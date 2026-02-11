import ballerina/http;
import ballerinax/health.fhir.r4;

configurable string fhir_server_url = ?;
configurable map<string> & readonly hook_id_questionnaire_id_map = ?;

service http:Service / on new http:Listener(9090) {
    isolated resource function post crd\-mri\-spine\-order\-sign(@http:Payload json payload) returns PriorAuthDecision|error|error {
        // log:printInfo(payload.toJsonString());
        // return error(string `Rule repository backend not implemented/ connected yet`);

        // r4:Bundle|error parse = parser:parse(payload, r4:Bundle).ensureType();
        r4:Bundle|error parse = payload.cloneWithType();

        if parse is error {
            return parse;
        }

        return decidePriorAuth(parse, "crd-mri-spine-order-sign");
    }
}
