# Patient Access API Metrics for CMS with Opensearch + Opensearch Dashboards

CMS requires Patient Access API Metrics to be published to CMS annually. This requirement can be achieved using the `AnalyticsResponseInterceptor` which comes inbuilt in the `health.fhirr4` service. Refer `module-ballerinax-health.fhir.r4/fhirr4/ballerina/src/main/resources/fhirservice/resources/analytics_README.md` to learn more.

## Overview

Inside the Patient Access API module which imports `ballerinax.health.fhirr4`, we need to have a `Config.toml` at the same level as `Ballerina.toml` including the necessary configs. A sample Config.toml can be found in `analytics_sample_config.toml`.

### x-jwt-assertion Header :

The data which is published for analytics are taken from the `x-jwt-assertion` header coming in the http request. Only the attributes in the `analyticsRequiredAttributes` list are published.

### analyticsServerUrl :

Opensearch endpoint to publish logs in the following format:
```
<opensearch_hostname>/<index>/_doc
```
Here the index should a value which can categorize the incoming logs. In this case we can use something like `patient_access`

### More Info Endpoint:

There can be information related to patient like contract, plan etc. which are out of scope for the FHIR R4 server. Payer can expose these info using a POST resource endpoint which accepts a json with `requiredAttributes` as keys, and returns more info as a json with key:value pairs like below.

```
{
    "contract": "Contract/24351",
    "plan": "Premium"
}
```

## Step 1: Setting up  Analytics Server: Opensearch & Opensearch Dashboard

A sample docker-compose file to deploy a two node Opensearch cluster along with Opensearch Dashboard is available in `analytics_opensearch_docker_compose.yml`.

Need to provide `OPENSEARCH_INITIAL_ADMIN_PASSWORD` as an environment variable. Create a `.env` file containing the password as follows in the same path where `docker-compose.yml` exists.

```
OPENSEARCH_INITIAL_ADMIN_PASSWORD=Strong@pass@432
```

Run `docker-compose up` where the docker-compose.yml is, to download and run the OS & OSD instances.

- Default port for Opensearch: 9200
- Default port for Opensearch Dashboard: 5601

A sample Opensearch Dashboard to capture the required metrics as per the spec, can be found in `analytics_opensearch_dashboard.ndjson` which can be imported to Opensearch Dashboards as follows.

> Note: The index is set to `patient_access` in the .ndjson file. Change it if you are publishing logs under a different index (Change `analyticsServerUrl in Config.toml properly).

> When the `analytics_opensearch_dashboard.ndjson` is imported, the relavent index pattern is created along with the fields, provided in the .ndjson. Therefore make sure to have all the fields in here, since any new fields published in the log json may not be visible. (You can manually add new fields in Opensearch Dashboards if needed later.)

Visit `<open_search_dashboard_host>/app/home#/` > Manage > Saved Objects > Import

The created dashboard should be available in the Dashboards section now. The main spec required metrics: `Unique number of users` and `Users with more than 1 request` are available in the dashboard, and can be filtered with a given date range.

## Step 2: Run the patient-access-api service

After the `Config.toml` is configured properly and the dashboard is imported, you can send a request to any Patient Access API and check the dashboard for visualization.

> Note: If a request is sent before importing a dashboard (with the required fields in the `.ndjson`), Opensearch index fields will be created acording to the attributes sent in the first log. Any new field attributes sent in later logs, will not be shown in the dashboard, unles set manually.

If you are deploying in choreo, add the analytics configurations acordingly in the UI while deploying.
