// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/file;
import ballerina/time;

// ============================================================
// Audit log reading and filtering utilities
// ============================================================

# Returns the number of seconds corresponding to a TimeFilter window.
# + tf - TimeFilter value
# + return - Seconds in the window
isolated function getTimeFilterSeconds(TimeFilter tf) returns int {
    if tf == "PAST_10_MIN"  { return 600; }
    if tf == "PAST_30_MIN"  { return 1800; }
    if tf == "PAST_1_HOUR"  { return 3600; }
    if tf == "PAST_2_HOURS" { return 7200; }
    if tf == "PAST_12_HOURS"{ return 43200; }
    return 86400; // PAST_24_HOURS
}

# Normalises a log timestamp to RFC 3339 so time:utcFromString can parse it.
# Handles ISO-8601 with T-separator and space-separated formats.
# + timeStr - Raw timestamp string from a log entry
# + return  - Normalised RFC 3339 string
isolated function normalizeLogTime(string timeStr) returns string {
    string t = timeStr.trim();
    int? tIdx = t.indexOf("T");
    if tIdx is int {
        // Has T-separator: ensure it ends with a timezone designator
        boolean hasZone = t.endsWith("Z") || t.includes("+") || (t.lastIndexOf("-") ?: -1) > 10;
        if hasZone {
            return t;
        }
        return t + "Z";
    }
    // "2024-01-15 10:30:00.000" or "2024-01-15 10:30:00.000+05:30"
    int? spaceIdx = t.indexOf(" ");
    if spaceIdx is int {
        string timePart = t.substring(spaceIdx + 1);
        // Only append Z if no timezone offset is already present
        boolean hasZone = timePart.endsWith("Z") || timePart.includes("+") || (timePart.lastIndexOf("-") ?: -1) > 5;
        string suffix = hasZone ? "" : "Z";
        return t.substring(0, spaceIdx) + "T" + timePart + suffix;
    }
    return t;
}

# Parses the epoch second from a single raw log line.
# + line   - Raw JSON log line
# + return - Epoch seconds of the entry, or error if the line is malformed
isolated function parseLineTimeSec(string line) returns int|error {
    string trimmed = line.trim();
    if trimmed.length() == 0 {
        return error("empty line");
    }
    json parsed = check trimmed.fromJsonString();
    map<json> logMap = check parsed.ensureType();
    json timeVal = logMap["time"] ?: "";
    time:Utc utc = check time:utcFromString(normalizeLogTime(timeVal.toString()));
    return utc[0];
}

# Binary-searches a chronologically ordered lines array for the first entry
# whose timestamp is >= thresholdSec.  Returns 0 on any parse failure so the
# caller falls back to processing the whole file.
# + lines        - All lines read from a log file
# + thresholdSec - Epoch-second lower bound for the time window
# + return       - Index of the first line inside the window
isolated function binarySearchStart(string[] lines, int thresholdSec) returns int {
    int lo = 0;
    int hi = lines.length() - 1;
    int firstMatch = lines.length(); // sentinel: "no line in window"

    while lo <= hi {
        int mid = lo + (hi - lo) / 2;
        int|error midSec = parseLineTimeSec(lines[mid]);
        if midSec is error {
            return lo; // can't navigate further – process from here
        }
        if midSec >= thresholdSec {
            firstMatch = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }
    return firstMatch;
}

# Reads audit log files (current + rotated backups), applies optional time-window
# and keyword filters, and returns the matching entries as raw JSON objects.
#
# Time filtering uses binary search (O(log n) to locate the window start) because
# log entries are written chronologically. Keyword filtering uses a
# case-insensitive substring match.
#
# + timeFilter - Time window constant, or nil for no time limit
# + keyword    - Case-insensitive keyword to match in the message field, or nil
# + return     - Matching JSON log objects, or error
isolated function getAuditLogs(TimeFilter? timeFilter, string? keyword) returns json[]|error {
    // --- Normalize keyword once for case-insensitive matching ---
    string? normalizedKeyword = ();
    if keyword is string && keyword.trim().length() > 0 {
        normalizedKeyword = keyword.trim().toLowerAscii();
    }

    // --- Compute epoch-second threshold ---
    int? thresholdSec = ();
    if timeFilter is TimeFilter {
        thresholdSec = time:utcNow()[0] - getTimeFilterSeconds(timeFilter);
    }

    json[] result = [];

    // --- Discover log files ---
    // Ballerina rotates using the pattern: {basename}-yyyyMMdd-HHmmss.log
    // e.g. audit-20251217-120530.log
    // We list ./logs/, collect matching backups, sort them lexicographically
    // (yyyyMMdd-HHmmss sorts correctly as a string), then append the live file.
    string logDir = "./logs";
    string logBasename = "audit"; // stem of AUDIT_LOG_PATH
    string backupPrefix = logBasename + "-";

    string[] backupFiles = [];
    file:MetaData[]|file:Error dirEntries = file:readDir(logDir);
    if dirEntries is file:MetaData[] {
        foreach file:MetaData entry in dirEntries {
            int slashIdx = entry.absPath.lastIndexOf("/") ?: -1;
            string name = entry.absPath.substring(slashIdx + 1);
            // Keep files that match "audit-*.log" but exclude the live "audit.log"
            if name.startsWith(backupPrefix) && name.endsWith(".log") {
                backupFiles.push(entry.absPath);
            }
        }
    }

    // Sort backups ascending so oldest is processed first (chronological order)
    string[] sortedBackups = from string p in backupFiles order by p ascending select p;

    // Process oldest backups first, live file last
    string[] logFiles = [...sortedBackups, AUDIT_LOG_PATH];

    foreach string filePath in logFiles {
        string[]|io:Error lines = io:fileReadLines(filePath);
        if lines is io:Error {
            continue; // file absent or unreadable – skip
        }
        if lines.length() == 0 {
            continue;
        }

        // --- Binary search for time window start ---
        int startIdx = 0;
        if thresholdSec is int {
            // Newest entry is at the bottom; if even that is older than the
            // threshold the whole file can be skipped in O(1).
            int|error lastSec = parseLineTimeSec(lines[lines.length() - 1]);
            if lastSec is int && lastSec < thresholdSec {
                continue; // entire file is outside the window
            }
            startIdx = binarySearchStart(lines, thresholdSec);
        }

        // --- Scan from startIdx, apply case-insensitive keyword filter ---
        foreach int i in startIdx ..< lines.length() {
            string trimmed = lines[i].trim();
            if trimmed.length() == 0 {
                continue;
            }

            json|error parsed = trimmed.fromJsonString();
            if parsed is error {
                continue; // malformed line (e.g. partial write) – skip
            }

            // Keyword match against the message field of the parsed log entry
            if normalizedKeyword is string {
                map<json>|error logMap = parsed.ensureType();
                if logMap is error {
                    continue;
                }
                string messageStr = (logMap["message"] ?: "").toString().toLowerAscii();
                if !messageStr.includes(normalizedKeyword) {
                    continue;
                }
            }

            result.push(parsed);
        }
    }

    return result;
}
