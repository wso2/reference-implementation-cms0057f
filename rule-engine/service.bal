import ballerina/http;
import ballerinax/health.fhir.r4;
// import ballerinax/health.fhir.r4.parser;

service http:Service / on new http:Listener(9090) {
    isolated resource function post .(@http:Payload json payload) returns PriorAuthDecision|error|error {
        // log:printInfo(payload.toJsonString());
        // return error(string `Rule repository backend not implemented/ connected yet`);

        // r4:Bundle|error parse = parser:parse(payload, r4:Bundle).ensureType();
        r4:Bundle|error parse = payload.cloneWithType();

        if parse is error{
            return parse;
        }

        return decidePriorAuth(parse);
    }
}
