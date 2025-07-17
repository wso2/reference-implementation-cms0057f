# Reference Implementation CMS 0057-F

### Purpose

This repository provides a reference implementation of the [CMS 0057-F](https://www.cms.gov/priorities/burden-reduction/overview/interoperability/policies-and-regulations/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f) regulation, demonstrating the integration of Ballerina services with React applications. It serves as a practical example for developers aiming to understand and implement CMS0057F-compliant solutions using these technologies.

### Folder Structure

```
.
├── apps
│   ├── demo-dtr-app
│   ├── demo-ehr-app
│   ├── demo-mediclaim-app
│   └── member-portal
├── bulk-export-client
│   ├── Ballerina.toml
│   ├── Config.toml
│   ├── Dependencies.toml
│   ├── inMemoryStorage.bal
│   ├── oas
│   │   └── BulkExport.yaml
│   │   └── FileServer.yaml
│   ├── records.bal
│   └── registry.bal
│   ├── service.bal
│   └── utils.bal
├── cds-service
│   ├── Ballerina.toml
│   ├── Config.toml
│   ├── Dependencies.toml
│   ├── decision_engine_connector.bal
│   ├── interceptor.bal
│   ├── oas
│   │   └── CDS.yaml
│   ├── service.bal
│   └── utils.bal
├── fhir-service
│   ├── Ballerina.toml
│   ├── Config.toml
│   ├── Dependencies.toml
│   ├── api_config.bal
│   ├── conformance.bal
│   ├── constants.bal
│   ├── member_matcher.bal
│   ├── mock_backend.bal
│   ├── oas
│   │   └── OpenAPI.yaml
│   ├── records.bal
│   ├── resources
│   ├── service.bal
│   ├── source_connect.bal
│   └── utils.bal
├── file-service
│   ├── Ballerina.toml
│   ├── Config.toml
│   ├── Dependencies.toml
│   ├── constants.bal
│   ├── inMemoryStorage.bal
│   ├── oas
│   │   └── OpenAPI.yaml
│   ├── records.bal
│   ├── service.bal
│   └── utils.bal
```

### Pre-requisites: 

1. Download the supported base distribution of [WSO2 API Manager](https://wso2.com/api-manager/previous-releases/) and [WSO2 Healthcare APIM Accelerator](https://github.com/wso2/healthcare-accelerator/releases). Refer to the [Product Compatibilities](https://healthcare.docs.wso2.com/en/latest/install-and-setup/manual/#product-compatibilities).
2. Setup APIM with the Healthcare accelerator.
3. Go through the following steps to setup Ballerina:
- Follow the instructions in [Ballerina Installation Options](https://ballerina.io/downloads/installation-options/) to install Ballerina runtime.
- Setup the Ballerina VSCode extension by following the instructions in [Ballerina VSCode Extension](https://ballerina.io/learn/get-started/#set-up-the-editor/) guide.
4. Clone the reference implementation from https://github.com/wso2/reference-implementation-cms0057f.git.


## Running Ballerina Services

The four reference ballerina services implemented are: 

```
├── bulk-export-client
├── cds-service
├── fhir-service
├── file-service
```
To start each service, navigate to the service directory. Run the following command. 

   ```bash
   bal run
   ```
Alternatively, these ballerina services can be deployed in WSO2 iPaaS Devant. 

## Deploying Ballerina Services in [Devant](https://wso2.com/devant/)

Attach your repository containing the Ballerina services in Devant and deploy the services.

Refer to [attach a repository](https://wso2.com/devant/docs/references/attach-a-repository/) and [deploy your first integration](https://wso2.com/devant/docs/quick-start-guides/deploy-your-first-integration-as-api/) documentations for more information. 


## Running React Applications

Sample React applications demonstrating real-world healthcare use cases are located in `reference-implementation-cms0057f/apps` directory. 

#### Prerequisites: Install Node & NPM.

To run a React application: 

1. **Navigate to the React Application Directory**:

   ```bash
   cd reference-implementation-cms0057f/apps/demo-mediclaim-app
   ```

2. **Install Dependencies**:

   ```bash
   npm install
   ```

3. **Start the React Application**:

   ```bash
   npm run dev
   ```
The demo-mediclaim-app will launch in your default browser, typically accessible at  `http://localhost:8080/`.

Repeat the same steps for other apps in the reference-implementation-cms0057f/apps directory.

## Deploying the APIs in APIM

To expose the services via WSO2 APIM (version 4.2.0), use the Swagger files found in each service's <service-directory>/oas directory.

Refer to [Deploying APIs in API Gateway vs Choreo Connect](https://apim.docs.wso2.com/en/4.2.0/deploy-and-publish/deploy-on-gateway/deploying-apis-in-api-gateway-vs-choreo-connect/) for detailed instructions.

## Subscribing to the APIs

- Go to the APIM developer portal. 
- Sign In. Click on Create New Account. Fill the form and proceed to self register. 
- Click Add New application. 
    - **Note:** If the [approval workflows](https://healthcare.docs.wso2.com/en/latest/advance-topics/guides/enable-workflow/) are enabled in APIM for user registration and application creation, these requests should be approved by the admins first from APIM /admin portal. 
- Subscribe to the APIs.
- Generate keys.

## Invoke the APIs

The Access to the APIs are implemented using the SMART on FHIR’s authorization scheme.

SMART on FHIR’s authorization scheme uses OAuth scopes to communicate (and negotiate) access requirements. 
Refer to [official documentation](https://build.fhir.org/ig/HL7/smart-app-launch/scopes-and-launch-context.html) and [WSO2 implementation here](https://healthcare.docs.wso2.com/en/latest/secure-health-apis/guides/smart-on-fhir-overview/#how-smart-on-fhir-builds-secure-apis) for more information. 

#### Generate an application access token:

```
curl --location 'https://localhost:9443/oauth2/token' \
--header 'Authorization: Basic Base64(consumer-key:consumer-secret)' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials'
```
#### Generate an user access token:

##### 1. Run the authorize request:

```
curl --location 'https://localhost:9443/oauth2/authorize/?response_type=code&redirect_uri=<redirect_uri>&state=<state>&client_id=<client_id>&prompt=login&nonce=<nonce>&scope=<scope1>%20<scope2>'
```
Get the authorization_code upon successful completion. 

##### 2. Run user access token request:
```
curl --location 'https://localhost:9443/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=<client_id>' \
--data-urlencode 'grant_type=authorization_code' \
--data-urlencode 'code=<authorization_code>' \
--data-urlencode 'scope=openid fhirUser' \
--data-urlencode 'redirect_uri=<redirect_uri>' \
--data-urlencode 'client_secret=<client_secret>'
```

Using the above access tokens(application/user access tokens), the secured API endpoints can be invoked using the APIs > Try Out option in APIM devportal. 

## Additional Notes

- Ensure that both the Ballerina service and the React application are running concurrently to allow seamless interaction between the frontend and backend.
- For detailed information on Ballerina code organization, refer to the official documentation: [Ballerina Documentation](https://ballerina.io/learn/organize-ballerina-code/)
- For insights into structuring React projects, consider this guide: [React Folder Structure](https://blog.webdevsimplified.com/2022-07/react-folder-structure/)

By following this setup, you can explore the integration of Ballerina services with a React frontend, providing a comprehensive understanding of building CMS0057F-compliant applications.
