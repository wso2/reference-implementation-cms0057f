import ballerina/http;
import ballerina/log;

configurable int port = 9091;

# initialize source system endpoint here

// Since 'status' and 'bulk-file' endpoints are not part of the FHIR standard, we define them here.
// When deploying the services, both FHIR and http services must have the same host.
service / on new http:Listener(port) {

    // download exported files.
    isolated resource function get api/export/[string taskId]/bulkfiles/[string fileName]() returns @http:Payload{mediaType: "application/json"} http:Response {
        // read ndjson from file system and return

        log:printInfo(string `taskId: ${taskId}, fileName: ${fileName}`);

        string filePath = "resources/" + fileName;

        http:Response response = new http:Response();
        response.setFileAsPayload(filePath);
        return response;
    }

    // kick-off request signature. 
    isolated resource function post api/export/Patient()
            returns http:Created {
        // Validate and extract resources from the request parameters
        log:printInfo(string `Patient level export operation kicked-off`);

        return http:CREATED;
    }
}
