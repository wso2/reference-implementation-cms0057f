import ballerina/os;

# Configurations for the claim repository service.
configurable string serviceURL = os:getEnv("CHOREO_PROVIDER_ACCESS_API_CLAIM_REPO_SERVICEURL");
configurable string consumerKey = os:getEnv("CHOREO_PROVIDER_ACCESS_API_CLAIM_REPO_CONSUMERKEY");
configurable string consumerSecret = os:getEnv("CHOREO_PROVIDER_ACCESS_API_CLAIM_REPO_CONSUMERSECRET");
configurable string tokenURL = os:getEnv("CHOREO_PROVIDER_ACCESS_API_CLAIM_REPO_TOKENURL");
configurable string choreoApiKey = os:getEnv("CHOREO_PROVIDER_ACCESS_API_CLAIM_REPO_CHOREOAPIKEY");
