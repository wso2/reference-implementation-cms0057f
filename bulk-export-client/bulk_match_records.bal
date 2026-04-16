// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

# Request payload for POST /pdex/trigger-bulk-data-exchange.
# + requestIds - Array of requestIds to trigger bulk data exchange for. These should correspond to existing PayerDataExchangeRequest records in the database.
public type TriggerBulkDataExchangeRequest record {|
    string[] requestIds;
|};

# Result of buildBulkMemberMatchParams — the Parameters JSON ready to POST
# to $bulk-member-match, plus a map to correlate response members back to requestIds.
#
# + params                 - Parameters JSON with MemberBundle[] for $bulk-member-match
# + memberIdToRequestIdMap - memberId -> requestId (used for response correlation)
public type BulkMatchParamsResult record {|
    json params;
    map<string> memberIdToRequestIdMap;
|};

# Parsed result of the $bulk-member-match 200 response.
#
# + matchedGroupId                  - id of the MatchedMembers Group persisted in fhir-service
# + matchedRequestIds               - requestIds successfully matched (stay IN_PROGRESS)
# + nonMatchedRequestIds            - requestIds with no demographic match (-> FAILED)
# + consentConstrainedRequestIds    - requestIds matched but consent failed (-> FAILED)
public type BulkMatchResponseResult record {|
    string matchedGroupId;
    string[] matchedRequestIds;
    string[] nonMatchedRequestIds;
    string[] consentConstrainedRequestIds;
|};

# Record to represent a bulk export job in the database.
#
# + jobId - Unique job identifier (UUID)
# + payerId - Payer this job targets
# + status - Overall job status (INITIATED, BULK_MATCH_POLLING, BULK_MATCH_COMPLETED,
#            EXPORT_POLLING, SYNCING, COMPLETED, FAILED)
# + createdAt - Job creation timestamp
# + completedAt - Job completion timestamp (set when COMPLETED or FAILED)
public type BulkExportJob record {|
    string jobId;
    string payerId;
    string status;
    string? createdAt = ();
    string? completedAt = ();
|};

# Response for GET /pdex/bulk-export-jobs/{jobId}.
# The job is the single polling entry point. Individual request statuses
# provide the full breakdown of matched/not-matched/consent-constrained.
#
# + job - The bulk export job details
# + requests - Individual request statuses linked to this job
public type BulkExportJobStatusResponse record {|
    BulkExportJob job;
    PayerDataExchangeRequest[] requests;
|};
