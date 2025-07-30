# Reference Implementation CMS-0057-F

### Purpose

This repository provides a comprehensive reference implementation of the [CMS-0057-F](https://www.cms.gov/priorities/burden-reduction/overview/interoperability/policies-and-regulations/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f) regulation, encompassing all critical regulatory provisions:

* Patient Access  
* Provider Access  
* Payer-to-Payer Data Exchange  
* Prior Authorization

The implementation is built using Ballerina, a cloud-native integration language optimized for health data interoperability. [Ballerina's native FHIR capabilities](https://ballerina.io/use-cases/healthcare/) enable healthcare developers to build scalable and flexible healthcare solutions that can adapt to changing healthcare needs and standards.

Then all the services are securely exposed through the WSO2 API Management platform to ensure robust API governance and access control.

In addition to the core services, the repository includes demo applications that demonstrate the full end-to-end flows, serving as a practical guide for implementers aiming to achieve compliance with CMS-0057-F.

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

## On-premise Deployment

### Deployment Architecture:

<img width="600" height="472" width="50%" alt="image" src="https://github.com/user-attachments/assets/b44c4433-37c4-435d-9458-b1afabaf0a25" />

### Pre-requisites 

1. [Set up APIM with the Healthcare accelerator.](https://healthcare.docs.wso2.com/en/latest/install-and-setup/manual/)  
2. [Set up the Integration Layer for Healthcare](https://healthcare.docs.wso2.com/en/latest/install-and-setup/manual/#setting-up-integration-layer-for-healthcare).  
3. Clone the reference implementation from [https://github.com/wso2/reference-implementation-cms0057f.git](https://github.com/wso2/reference-implementation-cms0057f.git).  
   * Open the project using [VS Code](https://ballerina.io/learn/vs-code-extension/get-started/).

<img width="600" height="472" alt="get-started" src="https://github.com/user-attachments/assets/289146b5-f432-4375-a73e-741a0da1a5fb" />


### Running the Integration Layer

The four reference ballerina services implemented are:

```
├── bulk-export-client
├── cds-service
├── fhir-service
├── file-service
```

Each service in this reference implementation includes a pre-populated `Config.toml` file located at `reference-implementation-cms0057f/<service-directory>`. If needed, you can customize these configuration values by updating the respective Config.toml file based on your environment and use case.

To start each service, navigate to the service directory. Run the following command. 

``` bash
bal run
```

Or you can click the `Run` button when the project is opened from VS Code.

### Securely Exposing and Managing APIs via WSO2 APIM

WSO2 API Manager is a full-featured platform that lets you create, manage, and expose APIs securely, whether you're deploying in the cloud, on-premises, or in a hybrid environment. It supports your digital transformation by enabling you to easily turn your services into managed APIs.

With WSO2 API Manager:

* Developers can design, publish, and control the lifecycle of APIs.  
* Product managers can group APIs into reusable API products to meet business needs.

To expose the services via WSO2 APIM (version 4.2.0), use the Swagger files found in each service's `/oas` directory.

Refer to [Create an API from an OpenAPI Definition](https://apim.docs.wso2.com/en/4.2.0/design/create-api/create-rest-api/create-a-rest-api-from-an-openapi-definition/) for detailed instructions.

| API Name | Swagger Definition | Backend Endpoint                                                                                  | Usage                                                                                                                                                                                                                    |
| ----- | ----- |---------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FHIRServiceAPI | fhir-service/oas/OpenAPI.yaml | fhir-service endpoint [http://localhost:9090](http://localhost:9090/)                             | Provides secure access to core FHIR resources such as Patient, Observation, Encounter, and Medication. Enables compliant retrieval and management of clinical healthcare data for Patient and Provider Access use cases. |
| BulkExportClientAPI | bulk-export-client/oas/BulkExport.yaml | bulk-export-client service endpoint [http://localhost:8091/bulk](http://localhost:8091/bulk)      | Facilitates large-scale export of patient and claims data from legacy or previous payer systems, supporting the Payer-to-Payer Data Exchange requirements of CMS-0057-F                                                  |
|BulkExportFileServer|bulk-export-client/oas/FileServer.yaml| bulk-export-client file service endpoint [http://localhost:8100/file](http://localhost:8100/file) | Acts as the file server for bulk export client - client side                                                                                                                                                             |
| FileServerAPI | file-service/oas/OpenAPI.yaml | file-service endpoint [http://localhost:8090](http://localhost:8090/)                             | Acts as a secure file server API to store, manage, and export user data files, including clinical documents and reports, supporting patient access and data portability                                                  |
| CDSServiceAPI | cds-service/oas/CDS.yaml | cds-service endpoint [http://localhost:9091](http://localhost:9091/)                              | Provides Clinical Decision Support (CDS) resources and services that assist in automating prior authorization workflows and other clinical decision-making processes for CMS-0057-F compliance.                          |

### Launch and Deploy in One Command

Kickstart your Ballerina services and deploy the APIs fronting them with a single script. To simplify the setup, we’ve included the `reference-implementation-cms0057f/start-services.sh`.

This script automates:
- Starting Ballerina services
- Deploying the corresponding APIs to WSO2 APIM.
  
Notes:
   - Pre-requisite: Install [APICTL](https://apim.docs.wso2.com/en/latest/install-and-setup/setup/api-controller/getting-started-with-wso2-api-controller/)
   - If needed, you can easily customize the script to add your own API names, endpoints, or API context making it adaptable to different environments and use cases.
   - Each service in this reference implementation includes a pre-populated `Config.toml`. If required, before running this sh file, update these configuration values accordingly. 
   - Make sure to run the sh file from within the reference-implementation-cms0057f itself as the tool is reading the OAS files from the repository.
   - During the run, you will be prompted to enter the APICTL environment details, APIM base URL and user credentials. 
   - Ballerina service startup logs will be available inside `reference-implementation-cms0057f/service-logs` directory.

<br>

## Bringing the Setup to the Cloud: One-Click Cloud Deployment with [Devant](https://wso2.com/devant/)

The steps outlined in the previous section describe how to deploy and test these services in a local development environment, typically using containerized WSO2 runtimes or on-premise infrastructure.

Alternatively, these reference artifacts can be deployed directly into WSO2 Devant, WSO2’s fully managed AI-native Integration Platform as a Service (iPaaS). Devant enables cloud-native deployment, AI‑powered low‑code development, and integration workflows that can be exposed and managed as APIs, with built-in observability, governance, CI/CD capabilities and scalability across cloud environments.

To get started with Devant, refer to the official documentation at [Devant Docs](https://wso2.com/devant/docs/).

### Deployment Architecture:

<img width="600" height="472" alt="saas-arch" src="https://github.com/user-attachments/assets/8364532c-904f-441f-8554-f3baa17ef6a1" />

### Deploying Ballerina Services in [Devant](https://wso2.com/devant/)

#### One Click Deployment via VSCode

- Install Visual Studio Code and [Ballerina VS Code Extension](https://ballerina.io/learn/vs-code-extension/get-started/). 
- Open the Ballerina project from VSCode.
- Click Deploy to Devant.

<img width="600" height="472" alt="Screenshot 2025-07-28 at 14 56 51" src="https://github.com/user-attachments/assets/3db9078b-aa83-40bc-9414-9cc44d8c36c5" />

Notes:
1. You can configure the required configuration values during the Deploy step(Choose the Configure & Deploy option).
<img width="600" height="472" alt="config-devant" src="https://github.com/user-attachments/assets/1a1fa216-be73-42e5-ade8-f689f9e21df5" />

2. For file-service and bulk-export-client service, the target directory can be set by adding a volume mount. Refer to [configure-storage](https://wso2.com/choreo/docs/devops-and-ci-cd/configure-storage/) for more information.  

3. With Devant deployment, there is no need to deploy the APIs in APIM separately, as these cloud solutions are deploying these services as APIs. API Management capabilities are already available here.  

4. For authentication and authorization, you have the option to [create an application in Asgardeo](https://wso2.com/choreo/docs/administer/configure-an-external-idp/configure-asgardeo-as-an-external-idp/) as well to consume these services.

## Try Out 

The Access to the APIs are implemented using the SMART on FHIR’s authorization scheme.

SMART on FHIR’s authorization scheme uses OAuth scopes to communicate (and negotiate) access requirements. Refer to [official documentation](https://build.fhir.org/ig/HL7/smart-app-launch/scopes-and-launch-context.html) and [WSO2 implementation here](https://healthcare.docs.wso2.com/en/latest/secure-health-apis/guides/smart-on-fhir-overview/#how-smart-on-fhir-builds-secure-apis) for more information.

You can try out the API calls using the following options based on your deployment model.

### 01: APIM devportal Try Out for local environments

* Step 01: Go to the APIM developer portal.  
* Step 02: Sign In. Click on Create New Account. Fill the form and proceed to self register.  
* Step 03: [Create an application](https://apim.docs.wso2.com/en/latest/consume/manage-application/create-application/).   
  * Note: If the [approval workflows](https://healthcare.docs.wso2.com/en/latest/advance-topics/guides/enable-workflow/) are enabled in APIM for user registration and application creation, these requests should be approved by the admins first from the APIM /admin portal.  
* Step 04: [Subscribe to the APIs](https://apim.docs.wso2.com/en/latest/consume/manage-subscription/subscribe-to-an-api/#subscribe-to-an-existing-application).   
* Step 05: [Generate the keys](https://apim.docs.wso2.com/en/latest/consume/manage-application/generate-keys/generate-api-keys/).   
* Step 06: Generate an Access Token to tryout the APIs.
<img width="600" height="472" alt="Screenshot 2025-07-28 at 15 11 48" src="https://github.com/user-attachments/assets/35a3620a-48db-4625-8127-0867bbd774a0" />

* Step 07: Go to the API from Devportal and use the generated token to try out.   
<img width="600" height="472" alt="tryout" src="https://github.com/user-attachments/assets/08c5d88b-c35c-46be-9983-f7d298a353b6" />

### 02: Devant Test > Console for Devant deployments

<img width="600" height="472" alt="image" src="https://github.com/user-attachments/assets/25709395-5917-42df-9396-145dbeb68867" />

### 03: Directly Invoke the APIs

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

Get the authorization\_code upon successful completion of authorization flow.

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
Using the above access tokens(application/user access tokens), the secured API endpoints can be invoked conveniently. 

#### CMS Reference Implementation – Postman Collection

To make it easier to explore and test the APIs, we’ve included a sample Postman collection: `reference-implementation-cms0057f/ CMS-Reference-Implementation.postman_collection.json`.

### 04: Try the demo applications

Refer to the following steps to try out the “patient access” scenario using mediclaim app. This app is developed to demonstrate a “SMART App” which will connect as a third party consumer for accessing health data by the patient users.

#### Prerequisites: Install Node('^18.18.0 || >=20.0.0') & NPM.

To run the React application:

1. Navigate to the React Application Directory:  
   ```bash
   cd reference-implementation-cms0057f/apps/demo-mediclaim-app
   ```
2. Install Dependencies:
   ```bash 
     	npm install
   ```
3. Start the React Application:  
   ```bash
      npm run dev
   ```
The demo-mediclaim-app will launch in your default browser, typically accessible at [http://localhost:8080/](http://localhost:8080/). 

Fill the form with the required fields to proceed with the demo scenarios.
- Base FHIR URL: Base API URL giving access to the FHIR Services API
- Consumer Key: Client ID of the OAuth application consuming the FHIR API
- Consumer Secret: Consumer Secret of the OAuth application consuming the FHIR API
- Redirect URI: http://localhost:8080/api-view
  - Note: Make sure to give this as the Redirect URL while creating the OAuth application.

<br>
<img width="600" height="472" alt="medi-claim" src="https://github.com/user-attachments/assets/fccd9856-ba2e-4dea-9369-ce70f8a3c885" />

Similarly, you can run the other demo apps included in reference-implementation-cms0057f/apps to try out different healthcare integration scenarios.

## Core FHIR Provisions Behind the Reference Implementation

This reference implementation addresses key healthcare interoperability scenarios defined by CMS-0057-F, including:
- [Patient Access](https://wso2.com/library/blogs/cms-interoperability-seamless-access-to-patient-data/): Secure, real-time access to patient health data.
- [Provider Access](https://wso2.com/library/blogs/cms-interoperability-empowering-providers-with-seamless-access-to-patient-data/): Authorized provider retrieval of clinical information.
- [Payer-to-Payer Data Exchange](https://wso2.com/library/blogs/cms-interoperability-seamless-continuity-of-care-for-new-members-through-payer-to-payer-exchange/): Seamless transfer of member and claims data between payers.
- [Prior Authorization](https://wso2.com/library/blogs/cms-interoperability-automating-prior-authorization/): Streamlined electronic prior authorization workflows.

## Developer Tips

**01:** If you want to configure a certificate to be trusted during tls communications or if you are observing SSL errors while connecting to your endpoints(Ex: discovery endpoint, token endpoint etc) from Ballerina services, kindly refer to the following steps. The code should be updated as given below.

For example: To trust the localhost:9443 when trying to fetch the openid configuration, update getOpenidConfigurations in `fhir-service/utils_generator.bal` to include the certificate configurations. In here, we have used the APIM public certificate and placed it inside a truststore p12 file at resources directory inside the fhir-service project.

```
public isolated function getOpenidConfigurations(string discoveryEndpoint) returns OpenIDConfiguration|error {
   LogDebug("Retrieving openid configuration started");
   string discoveryEndpointUrl = check url:decode(discoveryEndpoint, "UTF8");
   // http:Client discoveryEpClient = check new (discoveryEndpointUrl.toString());
   http:Client discoveryEpClient = check new (discoveryEndpointUrl.toString(),
   secureSocket = {
       trustStore: {
           path: "resources/truststore.p12", // Path to your truststore
           password: "changeit"              // Password for the truststore
       }
   });
   OpenIDConfiguration openidConfiguration = check discoveryEpClient->get("/");
   LogDebug("Retrieving openid configuration ended");
   return openidConfiguration;
}
```

**02:** In a local environment, if the react application is making calls to endpoints such as /oauth2/token in APIM, it is possible that you might observe CORS errors.  

To resolve this, add the following lines to the APIM-HOME/repository/deployment/server/webapps/oauth2/WEB-INF/web.xml right before the `</web-app>` tag.

```
   <filter>
   <filter-name>CORS</filter-name>
   <filter-class>com.thetransactioncompany.cors.CORSFilter</filter-class>
   <init-param>
       <param-name>cors.allowOrigin</param-name>
       <param-value>*</param-value>
   </init-param>
   <init-param>
       <param-name>cors.supportedMethods</param-name>
       <param-value>GET, POST, HEAD, PUT, DELETE, OPTIONS</param-value>
   </init-param>
   <init-param>
       <param-name>cors.supportedHeaders</param-name>
       <param-value>authorization,Access-Control-Allow-Origin,Content-Type,SOAPAction,apikey</param-value>
   </init-param>
   </filter>
   <filter-mapping>
       <filter-name>CORS</filter-name>
       <url-pattern>*</url-pattern>
   </filter-mapping>
```



## Additional Notes

- Ensure that both the Ballerina service and the React application are running concurrently to allow seamless interaction between the frontend and backend.  
- For detailed information on Ballerina code organization, refer to the official documentation: [Ballerina Documentation](https://ballerina.io/learn/organize-ballerina-code/)  
- For insights into structuring React projects, consider this guide: [React Folder Structure](https://blog.webdevsimplified.com/2022-07/react-folder-structure/)

By following this setup, you can explore the integration of Ballerina services with a React frontend, providing a comprehensive understanding of building CMS0057F-compliant applications.  

