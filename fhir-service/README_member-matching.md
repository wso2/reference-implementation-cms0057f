# Member Match & Export — Reference Guide

This document describes the member matching and data export operations implemented in the FHIR service, covering configuration, supported algorithms, API endpoints, and response formats.

Spec references:
- [HRex Member Match](https://hl7.org/fhir/us/davinci-hrex/STU1/OperationDefinition-member-match.html)
- [PDex Payer-to-Payer Bulk Exchange](https://build.fhir.org/ig/HL7/davinci-epdx/payertopayerbulkexchange.html)

---

## Operations

| Operation | Endpoint | Mode | Purpose |
|-----------|----------|------|---------|
| `$member-match` | `POST /fhir/r4/Patient/$member-match` | Synchronous | Match a single member |
| `$bulk-member-match` | `POST /fhir/r4/Group/$bulk-member-match` | Async (can be configured sync only for development use) | Match a cohort of members |
| `$davinci-data-export` | `GET /fhir/r4/Group/{id}/$davinci-data-export` | Async | Export clinical data for a matched cohort |

---

## Matching Algorithms

Four string-similarity algorithms are available. Each demographic field can be assigned a different algorithm via configuration.

### Exact

```toml
algorithm = "exact"
```

Case-insensitive string equality. Produces a similarity score of `1.0` when both values match, `0.0` otherwise.

Best for: identifiers, birth dates, gender, phone numbers, postal codes — fields where a typo is more likely to indicate a different person than a data-entry variation.

---

### Levenshtein

```toml
algorithm = "levenshtein"
levenshteinThreshold = 0.80   # optional, default 0.80
```

Computes edit distance — the minimum number of single-character insertions, deletions, or substitutions needed to transform one string into the other. Converts distance into a similarity score:

```text
similarity = 1.0 - (editDistance / max(len1, len2))
```

A score below `levenshteinThreshold` is treated as no match.

Best for: names where minor spelling differences should be tolerated (e.g., `"Johnston"` vs `"Johnson"`).

---

### Soundex

```toml
algorithm = "soundex"
```

Encodes each name as a 4-character phonetic code (first letter + 3 digits). Two names match (`1.0`) if their codes are identical, otherwise `0.0`.

Encoding rules:

| Characters              | Code    |
|-------------------------|---------|
| B, F, P, V              | 1       |
| C, G, J, K, Q, S, X, Z | 2       |
| D, T                    | 3       |
| L                       | 4       |
| M, N                    | 5       |
| R                       | 6       |
| A, E, I, O, U, H, W, Y | ignored |

Example: `"Robert"` → `R163`, `"Rupert"` → `R163` — these match.

Best for: detecting phonetically equivalent names across different spellings (e.g., `"Catherine"` vs `"Katherine"`).

---

### Jaro-Winkler

```toml
algorithm = "jarowinkler"
jaroWinklerThreshold   = 0.85   # optional, default 0.85
jaroWinklerPrefixScale = 0.1    # optional, default 0.1, max 0.25
```

A two-stage similarity measure:

1. **Jaro**: Character-by-character comparison within a matching window of `floor(max(len1, len2) / 2) - 1`. Transpositions are penalised at half-weight.

2. **Winkler prefix bonus**: Rewards strings that share a common prefix (up to 4 characters):
   ```text
   jaro_winkler = jaro + (prefixLength × prefixScale × (1 − jaro))
   ```

Produces a continuous score in `[0.0, 1.0]`. A score below `jaroWinklerThreshold` is treated as no match.

Best for: names where short-prefix agreement is a strong signal (e.g., `"Johnathan"` vs `"Jonathan"`). The default configuration uses this for both family and given names.

---

## Demographic Fields

Seven fields are compared during matching. Each is independently configurable with its own algorithm and weight.

| Field        | Compared Value             | Special Handling                                                          |
|--------------|----------------------------|---------------------------------------------------------------------------|
| `identifier` | Patient identifier value   | Identifier system must match exactly before value is compared             |
| `family`     | Primary family name        | First name structure only                                                 |
| `given`      | First given name           | First element of `given[]` array only                                     |
| `birthDate`  | ISO 8601 date string       | —                                                                         |
| `gender`     | Administrative gender code | —                                                                         |
| `phone`      | Phone number               | Non-digit characters stripped; leading `1` removed from 11-digit numbers  |
| `postalCode` | Postal code                | —                                                                         |

---

## Scoring & Grade Thresholds

The final match score is a weighted sum of per-field similarities:

```text
score = min(1.0, Σ weight_i × similarity_i)
```

Fields with no comparable value on either side do not contribute to the sum.

The score is then mapped to a grade using configurable thresholds:

| Grade           | Default Threshold | HTTP Outcome                                                  |
|-----------------|-------------------|---------------------------------------------------------------|
| `certain`       | score ≥ 0.95      | Match returned                                                |
| `probable`      | score ≥ 0.80      | Match returned                                                |
| `possible`      | score ≥ 0.60      | 422 — insufficient confidence to share PHI (HRex requirement) |
| `certainly-not` | score < 0.60      | No match                                                      |

---

## Configuration

The full member-match and export configuration block for `Config.toml`. Copy and adjust as needed.

```toml
## ─── Operation Mode ───────────────────────────────────────────────────────────
## Controls $bulk-member-match behaviour.
## "respond-async" → 202 Accepted + Content-Location polling URL
## "respond-sync"  → 200 OK with inline Parameters body
## The Prefer header on each request must contain this value.
bulkMemberMatchMode = "respond-async"

## Base URL of this server, used to construct Content-Location headers.
serverBaseUrl = "http://localhost:8080"


## ─── Match Grade Thresholds ───────────────────────────────────────────────────
## Scores are in [0.0, 1.0]. Thresholds must be strictly descending.
[memberMatchConfig.gradeThresholds]
certain  = 0.95   # score >= certain  → grade "certain"  (match returned)
probable = 0.80   # score >= probable → grade "probable" (match returned)
possible = 0.60   # score >= possible → grade "possible" (422, per HRex spec)
                  # score <  possible → grade "certainly-not" (no match)

## ─── Per-Field Weights & Algorithms ──────────────────────────────────────────
## All weights must be in [0.0, 1.0]. Their sum must not exceed 1.0.
## algorithm: "exact" | "levenshtein" | "soundex" | "jarowinkler"

[memberMatchConfig.fields.identifier]
weight    = 0.30
algorithm = "exact"

[memberMatchConfig.fields.family]
weight                 = 0.20
algorithm              = "jarowinkler"
jaroWinklerThreshold   = 0.88   # min similarity to score as a match (0.0–1.0)
jaroWinklerPrefixScale = 0.1    # prefix bonus scaling factor p (0.0–0.25)

[memberMatchConfig.fields.given]
weight                 = 0.15
algorithm              = "jarowinkler"
jaroWinklerThreshold   = 0.88
jaroWinklerPrefixScale = 0.1

[memberMatchConfig.fields.birthDate]
weight    = 0.20
algorithm = "exact"

[memberMatchConfig.fields.gender]
weight    = 0.05
algorithm = "exact"

[memberMatchConfig.fields.phone]
weight    = 0.05
algorithm = "exact"

[memberMatchConfig.fields.postalCode]
weight    = 0.05
algorithm = "exact"
```

---

## API Endpoints

### `$member-match` — Single Member (HRex)

```http
POST /fhir/r4/Patient/$member-match
Content-Type: application/fhir+json
```

**Request body**: `HRexMemberMatchRequestParameters` containing:

| Parameter       | Type             | Required | Description                                          |
|-----------------|------------------|----------|------------------------------------------------------|
| `MemberPatient` | USCore Patient   | Yes      | Demographics of the member to match                  |
| `CoverageToMatch` | HRex Coverage  | Yes      | Member's coverage at the requesting payer            |
| `CoverageToLink` | HRex Coverage   | No       | Prospective coverage at the receiving payer          |
| `Consent`       | HRex Consent     | No       | Consent to receive or disclose PHI                   |

**Success response** (`200 OK`):

```json
{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "MemberIdentifier",
      "valueIdentifier": {
        "type": {
          "coding": [{ "system": "http://terminology.hl7.org/3.1.0/CodeSystem-v2-0203.html", "code": "MB" }]
        },
        "value": "<matched-patient-id>"
      }
    }
  ]
}
```

**Error responses**:
- `422 Unprocessable Entity` — no match found, insufficient confidence, or consent validation failed

---

### `$bulk-member-match` — Batch Members (PDex)

```http
POST /fhir/r4/Group/$bulk-member-match
Content-Type: application/fhir+json
Prefer: respond-async
```

The `Prefer` header value must match the `bulkMemberMatchMode` setting in `Config.toml`.

**Request body**: `PDexMultiMemberMatchRequestParameters` containing an array of `MemberBundle` entries. Each entry includes the same four resources as the single match (`MemberPatient`, `CoverageToMatch`, `CoverageToLink`, `Consent`).

**Async response** (`202 Accepted`):

```http
HTTP/1.1 202 Accepted
Content-Location: http://localhost:8080/fhir/r4/_export/bulk-match-status/{jobId}
```

Poll the `Content-Location` URL for results (see [Polling bulk-match status](#polling-bulk-match-status)).

**Sync response** (`200 OK`): Returns the completed `Parameters` body directly (same structure as the polling result).

---

### Polling bulk-match status

```http
GET /fhir/r4/_export/bulk-match-status/{jobId}
```

**In-progress** (`202 Accepted`): Job is still running.

**Complete** (`200 OK`): Returns a `Parameters` resource with three named groups:

| Parameter name              | Group type                  | Description                                               |
|-----------------------------|-----------------------------|-----------------------------------------------------------|
| `MatchedMembers`            | `pdex-member-match-group`   | Members successfully matched with valid consent           |
| `NonMatchedMembers`         | `pdex-member-no-match-group` | Members with no match found                              |
| `ConsentConstrainedMembers` | `pdex-member-no-match-group` | Members matched but consent evaluation failed            |

The `MatchedMembers` Group is persisted to the FHIR store. Its `id` is used as the input to `$davinci-data-export`.

---

### `$davinci-data-export` — Export Clinical Data

```http
GET /fhir/r4/Group/{groupId}/$davinci-data-export
```

`{groupId}` is the `id` of the `MatchedMembers` Group returned by `$bulk-member-match`.

Optional query parameters:

| Parameter | Description                                                                      |
|-----------|----------------------------------------------------------------------------------|
| `_type`   | Comma-separated list of resource types to include (defaults to all `allowedExportResourceTypes`) |
| `_since`  | Only include resources updated after this instant                                |

**Response** (`202 Accepted`):

```http
HTTP/1.1 202 Accepted
Content-Location: http://localhost:8080/fhir/r4/_export/davinci-export-status/{jobId}
```

---

### Polling export status

```http
GET /fhir/r4/_export/davinci-export-status/{jobId}
```

**In-progress** (`202 Accepted`): Export is still running.

**Complete** (`200 OK`):

```json
{
  "transactionTime": "2025-06-01T12:00:00Z",
  "request": "GET http://localhost:8080/fhir/r4/Group/grp-001/$davinci-data-export",
  "requiresAccessToken": true,
  "output": [
    { "type": "Observation", "url": "http://localhost:8090/export/abc123/Observation.ndjson", "count": 42 },
    { "type": "Condition",   "url": "http://localhost:8090/export/abc123/Condition.ndjson",   "count": 18 }
  ]
}
```

Output files are NDJSON (one FHIR resource per line), grouped by resource type. A bearer token is required if `requiresAccessToken` is `true`.

---

## Result Groups

Each group returned by `$bulk-member-match` is a FHIR `Group` resource with `type: "person"` and `actual: true`. The `code.coding` identifies the outcome:

| Group                       | Code                | Meaning                                                                                                                              |
|-----------------------------|---------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `MatchedMembers`            | `match`             | Member was demographically matched; consent (if present) passed validation. Use this Group's `id` for `$davinci-data-export`.        |
| `NonMatchedMembers`         | `nomatch`           | No candidate met the required confidence threshold, or the requesting member had no match in the receiving payer's records.          |
| `ConsentConstrainedMembers` | `consentconstraint` | A demographic match was found but consent could not be validated. PHI is not shared.                                                 |

Each member entry in the group has a `member.entity` reference pointing to a contained `Patient` resource — the original `MemberPatient` as submitted by the requester.
