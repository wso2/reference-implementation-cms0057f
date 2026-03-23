import ballerina/log;

function getData(PolicyChunk[] chunks) returns map<string[]> {
    map<string[]> policyData = {};
    foreach PolicyChunk chunk in chunks {
        // Only process chunks that match the requested filename
        string sectionTitle = chunk.section_title;
        log:printDebug("Processing sectionTitle: " + sectionTitle);
        if policyData.hasKey(sectionTitle) {
            (<string[]>policyData[sectionTitle]).push(chunk.chunk_content);
            log:printDebug("Appended chunkContext to existing sectionTitle: " + sectionTitle);
        } else {
            policyData[sectionTitle] = [chunk.chunk_content];
            log:printDebug("Created new entry for sectionTitle: " + sectionTitle);
        }
    }
    return policyData;
}

function isValidTitle(string documentContent, string title, int index) returns boolean {
    if index == 0 {
        log:printDebug("Title is at the start of the document. Title: " + title);
        return false;
    }
    foreach int i in 1...5{
        if documentContent[index - i] == "#" {
            return true;
        }
    }
    log:printDebug("Title:  " + title + "at index" + index.toString() + " does not have # before it.");
    return false;
}

function recursive_splitter(string[] sectionContent) returns string[]{
    int contentLength = sectionContent[0].length();
    if contentLength <= MAX_CHUNK_SIZE {
        return sectionContent;
    }
    string[] chunks = [];
    while contentLength > MAX_CHUNK_SIZE {
        int? splitIndex = sectionContent[0].lastIndexOf("\n", MAX_CHUNK_SIZE);
        if splitIndex is null{
            splitIndex = MAX_CHUNK_SIZE;
        }
        string chunk = sectionContent[0].substring(0, <int>splitIndex);
        chunks.push(chunk.trim());
        sectionContent[0] = sectionContent[0].substring(<int>splitIndex).trim();
        contentLength = sectionContent[0].length();
    }
    if sectionContent[0] != "" {
        chunks.push(sectionContent[0].trim());
    }
    return chunks;
}
