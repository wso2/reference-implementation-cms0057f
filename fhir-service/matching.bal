// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0

// Configurable Patient Matching Engine
// =====================================
// Implements Levenshtein distance, Soundex phonetic matching,
// and a configurable scoring engine for patient deduplication.

import ballerinax/health.fhir.r4.uscore501;

// ============================================================
// CONFIGURABLE TYPES
// ============================================================

type GradeThresholds readonly & record {|
    decimal certain;
    decimal probable;
    decimal possible;
|};

type Algorithm "exact"|"levenshtein"|"soundex"|"jarowinkler";

type FieldConfig readonly & record {|
    decimal weight;
    Algorithm algorithm;
    decimal levenshteinThreshold?;   // similarity cutoff for levenshtein (default 0.80)
    decimal jaroWinklerThreshold?;   // similarity cutoff for jarowinkler (default 0.85)
    decimal jaroWinklerPrefixScale?; // prefix scaling factor p (default 0.1, capped at 0.25)
|};

type FieldsConfig readonly & record {|
    FieldConfig identifier;
    FieldConfig family;
    FieldConfig given;
    FieldConfig birthDate;
    FieldConfig gender;
    FieldConfig phone;
    FieldConfig postalCode;
|};

// ============================================================
// CONFIGURABLE DECLARATIONS (overridden via config.toml)
// ============================================================

configurable GradeThresholds gradeThresholds = {
    certain: 0.95d,
    probable: 0.80d,
    possible: 0.60d
};

configurable FieldsConfig fields = {
    identifier: {weight: 0.30d, algorithm: "exact"},
    family: {weight: 0.20d, algorithm: "exact"},
    given: {weight: 0.15d, algorithm: "exact"},
    birthDate: {weight: 0.20d, algorithm: "exact"},
    gender: {weight: 0.05d, algorithm: "exact"},
    phone: {weight: 0.05d, algorithm: "exact"},
    postalCode: {weight: 0.05d, algorithm: "exact"}
};

# Validate the FieldsConfig at application startup.
# Returns a descriptive error if any field's algorithm is not in the supported set.
# + f - The loaded FieldsConfig to validate
# + return - An error describing the invalid field, or nil if all fields are valid
isolated function validateFieldsConfig(FieldsConfig f) returns error? {
    // Algorithm values are enforced by the Algorithm type union: Ballerina's configurable
    // loader rejects any Config.toml value outside {"exact","levenshtein","soundex","jarowinkler"}
    // before this function runs, producing a startup error with the offending field name.
    // This function is the canonical application-layer hook for any future config constraints
    // (e.g., weight range checks, threshold bounds) that the type system cannot enforce.
    _ = f;
}

# Normalize a phone number by stripping non-digit characters.
# + phone - Raw phone string
# + return - Digits-only string
isolated function normalizePhone(string phone) returns string {
    string result = "";
    foreach int i in 0 ..< phone.length() {
        string ch = phone.substring(i, i + 1);
        if ch >= "0" && ch <= "9" {
            result += ch;
        }
    }
    return result;
}

# Canonicalize a phone number for matching and blocking purposes.
# Wraps normalizePhone() and additionally strips a leading US/Canada country
# code "1" from 11-digit results, so "+1 (800) 555-0100" and "8005550100"
# produce the same canonical form for blocking keys and scoring comparisons.
# + phone - Raw phone string
# + return - Canonical digits string
isolated function canonicalizePhone(string phone) returns string {
    string digits = normalizePhone(phone);
    if digits.length() == 11 && digits.startsWith("1") {
        return digits.substring(1);
    }
    return digits;
}

// ============================================================
// LEVENSHTEIN DISTANCE ALGORITHM
// ============================================================

# Calculate Levenshtein edit distance between two strings.
# Uses standard dynamic programming with O(min(m,n)) space.
# + a - First string
# + b - Second string
# + return - Edit distance (insertions + deletions + substitutions)
isolated function levenshteinDistance(string a, string b) returns int {
    string s = a.toLowerAscii();
    string t = b.toLowerAscii();
    int m = s.length();
    int n = t.length();

    if m == 0 {
        return n;
    }
    if n == 0 {
        return m;
    }

    // Ensure s is the shorter string for O(min(m,n)) space
    if m > n {
        return levenshteinDistance(b, a);
    }

    // Previous row of distances
    int[] prev = [];
    foreach int j in 0 ... n {
        prev.push(j);
    }

    foreach int i in 1 ... m {
        int[] curr = [i];
        string charS = s.substring(i - 1, i);
        foreach int j in 1 ... n {
            string charT = t.substring(j - 1, j);
            int cost = charS == charT ? 0 : 1;
            int insertCost = curr[j - 1] + 1;
            int deleteCost = prev[j] + 1;
            int replaceCost = prev[j - 1] + cost;
            int minVal = insertCost < deleteCost ? insertCost : deleteCost;
            curr.push(minVal < replaceCost ? minVal : replaceCost);
        }
        prev = curr;
    }

    return prev[n];
}

# Calculate Levenshtein similarity as a ratio between 0.0 and 1.0.
# + a - First string
# + b - Second string
# + return - Similarity ratio (1.0 = identical, 0.0 = completely different)
isolated function levenshteinSimilarity(string a, string b) returns decimal {
    if a.length() == 0 && b.length() == 0 {
        return 1.0d;
    }
    int maxLen = a.length() > b.length() ? a.length() : b.length();
    int distance = levenshteinDistance(a, b);
    return 1.0d - (<decimal>distance / <decimal>maxLen);
}

// ============================================================
// SOUNDEX PHONETIC ALGORITHM
// ============================================================

# Compute the American Soundex code for a string.
# Maps a name to a 4-character code: first letter + 3 digits.
# + input - The string to encode
# + return - 4-character Soundex code (e.g., "R163" for "Robert")
isolated function soundex(string input) returns string {
    string s = input.toLowerAscii().trim();
    if s.length() == 0 {
        return "0000";
    }

    // Soundex coding: B,F,P,V=1  C,G,J,K,Q,S,X,Z=2  D,T=3  L=4  M,N=5  R=6
    // A,E,I,O,U,H,W,Y = ignored (0)
    string firstChar = s.substring(0, 1).toUpperAscii();
    string result = firstChar;
    string lastCode = soundexCode(s.substring(0, 1));

    foreach int i in 1 ..< s.length() {
        if result.length() >= 4 {
            break;
        }
        string ch = s.substring(i, i + 1);
        string code = soundexCode(ch);
        if code != "0" && code != lastCode {
            result += code;
        }
        lastCode = code;
    }

    // Pad with zeros to length 4
    while result.length() < 4 {
        result += "0";
    }

    return result;
}

# Get the Soundex digit for a single character.
# + ch - Single character to encode
# + return - Soundex digit code ("0"-"6")
isolated function soundexCode(string ch) returns string {
    string c = ch.toLowerAscii();
    if c == "b" || c == "f" || c == "p" || c == "v" {
        return "1";
    }
    if c == "c" || c == "g" || c == "j" || c == "k" || c == "q" || c == "s" || c == "x" || c == "z" {
        return "2";
    }
    if c == "d" || c == "t" {
        return "3";
    }
    if c == "l" {
        return "4";
    }
    if c == "m" || c == "n" {
        return "5";
    }
    if c == "r" {
        return "6";
    }
    return "0";
}

# Check if two strings match phonetically using Soundex.
# + a - First string
# + b - Second string
# + return - true if both strings produce the same Soundex code
isolated function soundexMatch(string a, string b) returns boolean {
    return soundex(a) == soundex(b);
}

// ============================================================
// JARO-WINKLER ALGORITHM
// ============================================================

# Calculate the Jaro similarity between two strings.
# Characters match if within a window of floor(max(|s1|,|s2|)/2)-1.
# + a - First string
# + b - Second string
# + return - Jaro similarity (1.0 = identical, 0.0 = no match)
isolated function jaroSimilarity(string a, string b) returns decimal {
    string s1 = a.toLowerAscii();
    string s2 = b.toLowerAscii();
    int len1 = s1.length();
    int len2 = s2.length();

    if len1 == 0 && len2 == 0 {
        return 1.0d;
    }
    if len1 == 0 || len2 == 0 {
        return 0.0d;
    }
    if s1 == s2 {
        return 1.0d;
    }

    // Match window: floor(max(len1, len2) / 2) - 1
    int maxLen = len1 > len2 ? len1 : len2;
    int matchWindow = (maxLen / 2) - 1;
    if matchWindow < 0 {
        matchWindow = 0;
    }

    boolean[] s1Matched = [];
    boolean[] s2Matched = [];
    foreach int i in 0 ..< len1 {
        s1Matched.push(false);
    }
    foreach int i in 0 ..< len2 {
        s2Matched.push(false);
    }

    int matches = 0;
    foreach int i in 0 ..< len1 {
        int winStart = i - matchWindow;
        if winStart < 0 {
            winStart = 0;
        }
        int winEnd = i + matchWindow;
        if winEnd >= len2 {
            winEnd = len2 - 1;
        }
        if winStart > winEnd {
            continue;
        }
        foreach int j in winStart ... winEnd {
            if s2Matched[j] || s1.substring(i, i + 1) != s2.substring(j, j + 1) {
                continue;
            }
            s1Matched[i] = true;
            s2Matched[j] = true;
            matches += 1;
            break;
        }
    }

    if matches == 0 {
        return 0.0d;
    }

    // Count transpositions (half the number of matched chars in wrong order)
    int transpositions = 0;
    int k = 0;
    foreach int i in 0 ..< len1 {
        if !s1Matched[i] {
            continue;
        }
        while k < len2 && !s2Matched[k] {
            k += 1;
        }
        if k < len2 && s1.substring(i, i + 1) != s2.substring(k, k + 1) {
            transpositions += 1;
        }
        k += 1;
    }

    decimal m = <decimal>matches;
    decimal t = <decimal>transpositions;
    return (m / <decimal>len1 + m / <decimal>len2 + (m - t / 2.0d) / m) / 3.0d;
}

# Calculate the Jaro-Winkler similarity between two strings.
# Extends Jaro by giving extra weight to common prefix characters (up to 4).
# + a - First string
# + b - Second string
# + prefixScale - Scaling factor for prefix bonus (typically 0.1, max 0.25)
# + return - Jaro-Winkler similarity (1.0 = identical, 0.0 = no match)
isolated function jaroWinklerSimilarity(string a, string b, decimal prefixScale) returns decimal {
    decimal jaro = jaroSimilarity(a, b);

    string s1 = a.toLowerAscii();
    string s2 = b.toLowerAscii();
    int minLen = s1.length() < s2.length() ? s1.length() : s2.length();
    int maxPrefix = minLen < 4 ? minLen : 4;

    int prefix = 0;
    foreach int i in 0 ..< maxPrefix {
        if s1.substring(i, i + 1) == s2.substring(i, i + 1) {
            prefix += 1;
        } else {
            break;
        }
    }

    // Cap prefixScale at 0.25 to preserve mathematical validity
    decimal scale = prefixScale > 0.25d ? 0.25d : prefixScale;
    return jaro + <decimal>prefix * scale * (1.0d - jaro);
}

// ============================================================
// FIELD COMPARISON DISPATCHER
// ============================================================

# Compare two string values using the algorithm specified in config.
# Returns a similarity score between 0.0 and 1.0.
# + a - First string value
# + b - Second string value
# + config - Field configuration specifying algorithm and parameters
# + return - Similarity score (1.0 = match, 0.0 = no match)
isolated function compareField(string a, string b, FieldConfig config) returns decimal {
    match config.algorithm {
        "exact" => {
            return a.toLowerAscii() == b.toLowerAscii() ? 1.0d : 0.0d;
        }
        "levenshtein" => {
            decimal similarity = levenshteinSimilarity(a, b);
            decimal threshold = config.levenshteinThreshold ?: 0.80d;
            return similarity >= threshold ? similarity : 0.0d;
        }
        "soundex" => {
            return soundexMatch(a, b) ? 1.0d : 0.0d;
        }
        "jarowinkler" => {
            decimal prefixScale = config.jaroWinklerPrefixScale ?: 0.1d;
            decimal similarity = jaroWinklerSimilarity(a, b, prefixScale);
            decimal threshold = config.jaroWinklerThreshold ?: 0.85d;
            return similarity >= threshold ? similarity : 0.0d;
        }
        _ => {
            panic error("unreachable: unsupported algorithm");
        }
    }
}

// ============================================================
// SCORING ENGINE
// ============================================================

# Calculate a matching score between two patients using configured algorithms and weights.
# + input - The input patient record to match against
# + candidate - The candidate patient record to compare with
# + return - A decimal score between 0.0 and 1.0 representing match confidence
isolated function calculateScore(uscore501:USCorePatientProfile input, uscore501:USCorePatientProfile candidate) returns decimal {
    decimal score = 0.0d;

    // --- Identifier (system exact, value by configured algorithm) ---
    // The system field is a URI namespace and must always be exact-matched.
    // The value field uses the algorithm configured for the identifier field.
    boolean identifierMatched = false;
    foreach uscore501:USCorePatientProfileIdentifier inId in input.identifier {
        if identifierMatched {
            break;
        }
        string? inSystem = inId.system;
        string? inValue = inId.value;
        if inSystem is () || inValue is () {
            continue;
        }
        foreach uscore501:USCorePatientProfileIdentifier candId in candidate.identifier {
            string? candSystem = candId.system;
            string? candValue = candId.value;
            if candSystem is () || candValue is () {
                continue;
            }
            if inSystem == candSystem {
                decimal sim = compareField(inValue, candValue, fields.identifier);
                if sim > 0.0d {
                    score += fields.identifier.weight * sim;
                    identifierMatched = true;
                    break;
                }
            }
        }
    }

    // --- Family name ---
    string? inFamily = getFamily(input);
    string? candFamily = getFamily(candidate);
    if inFamily is string && candFamily is string {
        decimal sim = compareField(inFamily, candFamily, fields.family);
        score += fields.family.weight * sim;
    }

    // --- Given name ---
    string? inGiven = getGiven(input);
    string? candGiven = getGiven(candidate);
    if inGiven is string && candGiven is string {
        decimal sim = compareField(inGiven, candGiven, fields.given);
        score += fields.given.weight * sim;
    }

    // --- Birth date ---
    if input.birthDate is string && candidate.birthDate is string {
        decimal sim = compareField(<string>input.birthDate, <string>candidate.birthDate, fields.birthDate);
        score += fields.birthDate.weight * sim;
    }

    // --- Gender ---
    score += fields.gender.weight * compareField(input.gender, candidate.gender, fields.gender);

    // --- Phone (normalize before comparison to handle different formatting) ---
    string? inPhone = getTelecom(input, "phone");
    string? candPhone = getTelecom(candidate, "phone");
    if inPhone is string && candPhone is string {
        decimal sim = compareField(canonicalizePhone(inPhone), canonicalizePhone(candPhone), fields.phone);
        score += fields.phone.weight * sim;
    }

    // --- Postal code ---
    string? inPostal = getAddressField(input, "postalCode");
    string? candPostal = getAddressField(candidate, "postalCode");
    if inPostal is string && candPostal is string {
        decimal sim = compareField(inPostal, candPostal, fields.postalCode);
        score += fields.postalCode.weight * sim;
    }

    return score > 1.0d ? 1.0d : score;
}

# Determine the match grade based on configurable thresholds.
# + score - The decimal score to evaluate
# + return - Match grade: "certain", "probable", "possible", or "certainly-not"
isolated function getMatchGrade(decimal score) returns string {
    if score >= gradeThresholds.certain {
        return "certain";
    }
    if score >= gradeThresholds.probable {
        return "probable";
    }
    if score >= gradeThresholds.possible {
        return "possible";
    }
    return "certainly-not";
}

// ============================================================
// PATIENT FIELD ACCESSORS
// ============================================================

isolated function getFamily(uscore501:USCorePatientProfile patient) returns string? {
    uscore501:USCorePatientProfileName[] name = patient.name;
    if name.length() > 0 {
        return name[0].family;
    }
    return ();
}

isolated function getGiven(uscore501:USCorePatientProfile patient) returns string? {
    uscore501:USCorePatientProfileName[] name = patient.name;
    if name.length() > 0 {
        string[]? given = name[0].given;
        if given is string[] && given.length() > 0 {
            return given[0];
        }
    }
    return ();
}

isolated function getTelecom(uscore501:USCorePatientProfile patient, string system) returns string? {
    uscore501:USCorePatientProfileTelecom[]? telecoms = patient.telecom;
    if telecoms is uscore501:USCorePatientProfileTelecom[] {
        foreach uscore501:USCorePatientProfileTelecom t in telecoms {
            if t.system.toString() == system {
                return t.value;
            }
        }
    }
    return ();
}

isolated function getAddressField(uscore501:USCorePatientProfile patient, string 'field) returns string? {
    uscore501:USCorePatientProfileAddress[]? addresses = patient.address;
    if addresses is uscore501:USCorePatientProfileAddress[] && addresses.length() > 0 {
        uscore501:USCorePatientProfileAddress addr = addresses[0];
        if 'field == "postalCode" {
            return addr.postalCode;
        }
    }
    return ();
}
