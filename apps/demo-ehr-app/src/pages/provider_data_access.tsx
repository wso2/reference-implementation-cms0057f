// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Container, Card, Form, Button, Alert, Spinner, Table } from "react-bootstrap";
import axios from "axios";

function ProviderDataAccess() {
    const [loading, setLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [downloadedData, setDownloadedData] = useState<{ [patientId: string]: { [resourceType: string]: any[] } }>({});
    const [selectedPatientForView, setSelectedPatientForView] = useState<string>("");
    const [selectedResourceTypeForView, setSelectedResourceTypeForView] = useState<string>("Patient");
    const [selectedPayer, setSelectedPayer] = useState<string>("");

    const SUPPORTED_RESOURCE_TYPES = ["Patient", "Coverage", "ClaimResponse", "Claim", "Observation", "AllergyIntolerance"];

    const Config = window.Config;
    const navigate = useNavigate();

    const handleFetchData = async () => {
        const npi = Config.npi;
        if (!npi) {
            setErrorMsg("Missing NPI in application config.");
            return;
        }

        console.log(`[Provider Access] Initiating bulk data sync for NPI: ${npi}`);
        setLoading(true);
        setErrorMsg("");

        try {
            // 1. Fetch Organization by NPI identifier
            const orgResponse = await axios.get(`${Config.organization}?identifier=${npi}`);
            if (!orgResponse.data || !orgResponse.data.entry || orgResponse.data.entry.length === 0) {
                throw new Error(`No Organization found for NPI: ${npi}`);
            }
            if (orgResponse.data.entry.length > 1) {
                throw new Error(`Multiple Organizations found for NPI: ${npi}. Expected only one.`);
            }

            const organizationId = orgResponse.data.entry[0].resource.id;

            // 2. Fetch Group by managing-entity
            const groupResponse = await axios.get(`${Config.group}?managing-entity=Organization/${organizationId}`);
            if (!groupResponse.data || !groupResponse.data.entry || groupResponse.data.entry.length === 0) {
                throw new Error(`No Group found managed by Organization: ${organizationId}`);
            }

            const groupId = groupResponse.data.entry[0].resource.id;
            console.log(`[Provider Access] Found Group ID: ${groupId} for Organization: ${organizationId}`);

            // 3. Trigger Group Export
            console.log(`[Provider Access] Triggering Group /$export operation...`);
            const exportResponse = await axios.get(`${Config.group}/${groupId}/$export`);

            if (exportResponse.data && exportResponse.data.exportUrls) {
                console.log(`[Provider Access] Group /$export Accepted. Transaction Time: ${exportResponse.data.transactionTime}`);
                console.log(`[Provider Access] Received Status Polling URLs for group members:`, exportResponse.data.exportUrls);
                pollExportStatus(exportResponse.data.exportUrls);
            } else {
                throw new Error("Invalid response received from Group Export API.");
            }

        } catch (error: any) {
            console.error("Provider Data Access Error:", error);
            setErrorMsg(error.response?.data?.message || error.message || "An unexpected error occurred.");
            setLoading(false);
        }
    };

    const pollExportStatus = async (urls: { [key: string]: string }) => {
        const activePolls = Object.keys(urls).map(async (patientId) => {
            let isReady = false;
            let retries = 0;
            const MAX_RETRIES = 30; // 30 * 2s = 60s
            const originalUrl = urls[patientId];
            const exportPathIndex = originalUrl.indexOf("_export/status");
            let pollingUrl = originalUrl;

            if (exportPathIndex !== -1) {
                const relativeExportUrl = originalUrl.substring(exportPathIndex);
                // Extract base path from Config.group (e.g. /choreo-apis/cms-paas/fhir-service-fm/v1)
                const proxyBasePath = window.Config.group.replace("/Group", "");
                pollingUrl = `${proxyBasePath}/${relativeExportUrl}`;
            }

            while (!isReady && retries < MAX_RETRIES) {
                try {
                    const statusResponse = await axios.get(pollingUrl);

                    if (statusResponse.status === 200) {
                        isReady = true;
                        if (statusResponse.data && statusResponse.data.output) {
                            console.log(`[Provider Access] [Patient: ${patientId}] Export completed successfully. Data received:`, statusResponse.data.output);

                            // Immediately fetch the supported ndjson files
                            await fetchNdjsonData(patientId, statusResponse.data.output);
                        } else {
                            console.warn(`[Provider Access] [Patient: ${patientId}] Export ready but no output links provided.`);
                        }
                    } else if (statusResponse.status === 202) {
                        // Still processing
                        console.log(`[Provider Access] [Patient: ${patientId}] Export pending (202). Retrying in 2 seconds... (Attempt ${retries + 1}/${MAX_RETRIES})`);
                        await new Promise((resolve) => setTimeout(resolve, 2000));
                        retries++;
                    } else {
                        throw new Error(`Unexpected status: ${statusResponse.status}`);
                    }
                } catch (err: any) {
                    isReady = true; // Stop polling on error
                    console.error(`[Provider Access] [Patient: ${patientId}] Polling failed:`, err);
                }
            }

            if (!isReady) {
                console.error(`[Provider Access] [Patient: ${patientId}] Timed out waiting for export.`);
            }
        });

        await Promise.all(activePolls);
        setLoading(false); // Done polling for all
    };

    const fetchNdjsonData = async (patientId: string, outputLinks: any[]) => {
        const patientData: { [resourceType: string]: any[] } = {};

        for (const output of outputLinks) {
            if (SUPPORTED_RESOURCE_TYPES.includes(output.type)) {
                try {
                    // Similar proxy rewrite logic for download links
                    const originalUrl = output.url;
                    const downloadPathIndex = originalUrl.indexOf("_export/download");
                    let downloadUrl = originalUrl;

                    if (downloadPathIndex !== -1) {
                        const relativeDownloadUrl = originalUrl.substring(downloadPathIndex);
                        const proxyBasePath = window.Config.group.replace("/Group", "");
                        downloadUrl = `${proxyBasePath}/${relativeDownloadUrl}`;
                    }

                    const res = await axios.get(downloadUrl, { responseType: 'text' });
                    // Parse NDJSON (New Line Delimited JSON)
                    const lines = res.data.split('\n').filter((line: string) => line.trim() !== '');
                    const resources = lines.map((line: string) => JSON.parse(line));
                    patientData[output.type] = resources;
                } catch (e) {
                    console.error(`Failed to download ${output.type} for patient ${patientId}`, e);
                }
            }
        }

        setDownloadedData((prev) => ({ ...prev, [patientId]: patientData }));

        // Auto-select first available patient for view if none selected
        setSelectedPatientForView((prev) => prev || patientId);
    };

    const renderDataRowList = (resourceType: string, list: any[]) => {
        if (!list || list.length === 0) return <tr><td colSpan={5}>No data available</td></tr>;

        switch (resourceType) {
            case "Patient":
                return list.map((res: any, i) => (
                    <tr key={i}>
                        <td>{res.id}</td>
                        <td>{res.name?.[0]?.given?.join(" ")} {res.name?.[0]?.family}</td>
                        <td>{res.gender}</td>
                        <td>{res.birthDate}</td>
                        <td>{res.address?.[0]?.city}, {res.address?.[0]?.state}</td>
                    </tr>
                ));
            case "Observation":
                return list.map((res: any, i) => (
                    <tr key={i}>
                        <td>{res.id}</td>
                        <td>{res.code?.coding?.[0]?.display || res.code?.text}</td>
                        <td>{res.valueQuantity ? `${res.valueQuantity.value} ${res.valueQuantity.unit}` : res.valueCodeableConcept?.text}</td>
                        <td>{res.effectiveDateTime}</td>
                        <td>{res.status}</td>
                    </tr>
                ));
            case "AllergyIntolerance":
                return list.map((res: any, i) => (
                    <tr key={i}>
                        <td>{res.id}</td>
                        <td>{res.code?.coding?.[0]?.display || res.code?.text}</td>
                        <td>{res.clinicalStatus?.coding?.[0]?.code}</td>
                        <td>{res.reaction?.[0]?.manifestation?.[0]?.text || "N/A"}</td>
                        <td>{res.criticality || "N/A"}</td>
                    </tr>
                ));
            case "Claim":
                return list.map((res: any, i) => (
                    <tr key={i}>
                        <td>{res.id}</td>
                        <td>{res.type?.coding?.[0]?.code}</td>
                        <td>{res.status}</td>
                        <td>{res.total?.value} {res.total?.currency}</td>
                        <td>{res.created}</td>
                    </tr>
                ));
            case "ClaimResponse":
                return list.map((res: any, i) => (
                    <tr key={i}>
                        <td>{res.id}</td>
                        <td>{res.outcome}</td>
                        <td>{res.disposition}</td>
                        <td>{res.payment?.amount?.value} {res.payment?.amount?.currency}</td>
                        <td>{res.created}</td>
                    </tr>
                ));
            case "Coverage":
                return list.map((res: any, i) => (
                    <tr key={i}>
                        <td>{res.id}</td>
                        <td>{res.status}</td>
                        <td>{res.type?.text || res.type?.coding?.[0]?.display}</td>
                        <td>{res.subscriberId}</td>
                        <td>{res.period?.start} to {res.period?.end}</td>
                    </tr>
                ));
            default:
                return <tr><td colSpan={5}>Unsupported Resource Type View</td></tr>;
        }
    };

    const renderTableHeader = (resourceType: string) => {
        switch (resourceType) {
            case "Patient":
                return <tr><th>ID</th><th>Name</th><th>Gender</th><th>Birth Date</th><th>Address</th></tr>;
            case "Observation":
                return <tr><th>ID</th><th>Code</th><th>Value</th><th>Effective Date</th><th>Status</th></tr>;
            case "AllergyIntolerance":
                return <tr><th>ID</th><th>Substance</th><th>Clinical Status</th><th>Reaction</th><th>Criticality</th></tr>;
            case "Claim":
                return <tr><th>ID</th><th>Type</th><th>Status</th><th>Total</th><th>Created Date</th></tr>;
            case "ClaimResponse":
                return <tr><th>ID</th><th>Outcome</th><th>Disposition</th><th>Payment Amount</th><th>Created Date</th></tr>;
            case "Coverage":
                return <tr><th>ID</th><th>Status</th><th>Type</th><th>Subscriber ID</th><th>Period</th></tr>;
            default:
                return <tr><th>Data</th></tr>;
        }
    };

    return (
        <Container style={{ marginTop: "40px", paddingBottom: "40px" }}>
            <Button variant="secondary" onClick={() => navigate(-1)} style={{ marginBottom: "20px" }}>
                Back
            </Button>
            <div className="page-heading">Provider Data Access</div>
            <Card style={{ marginTop: "20px", padding: "20px" }}>
                <Card.Body>
                    <Card.Title>Import Health Records from Clinical Systems</Card.Title>
                    <Card.Text>
                        Click the button below to fetch and synchronize bulk health records associated with the current clinical practice.
                    </Card.Text>
                    {Config.payers && Config.payers.length > 0 && (
                        <Form.Group style={{ marginTop: "20px" }}>
                            <Form.Label>
                                Select Payer Network <span style={{ color: "red" }}>*</span>
                            </Form.Label>
                            <Form.Select
                                value={selectedPayer}
                                onChange={(e) => setSelectedPayer(e.target.value)}
                            >
                                <option value="" disabled>-- Select a Payer --</option>
                                {Config.payers.map((payer) => (
                                    <option key={payer.id} value={payer.id}>{payer.name}</option>
                                ))}
                            </Form.Select>
                        </Form.Group>
                    )}

                    {errorMsg && <Alert variant="danger" style={{ marginTop: "20px" }}>{errorMsg}</Alert>}

                    <Button
                        variant="primary"
                        style={{ marginTop: "20px" }}
                        onClick={handleFetchData}
                        disabled={loading || !selectedPayer}
                    >
                        {loading ? <Spinner as="span" animation="border" size="sm" role="status" aria-hidden="true" /> : "Sync Data"}
                    </Button>
                </Card.Body>
            </Card>

            {Object.keys(downloadedData).length > 0 && (
                <Card style={{ marginTop: "20px" }}>
                    <Card.Header>Health Records Viewer</Card.Header>
                    <Card.Body>
                        <div style={{ display: "flex", gap: "20px", marginBottom: "20px" }}>
                            <Form.Group style={{ flex: 1 }}>
                                <Form.Label>Select Patient</Form.Label>
                                <Form.Select
                                    value={selectedPatientForView}
                                    onChange={(e) => setSelectedPatientForView(e.target.value)}
                                >
                                    {Object.keys(downloadedData).map(pid => (
                                        <option key={pid} value={pid}>{pid}</option>
                                    ))}
                                </Form.Select>
                            </Form.Group>

                            <Form.Group style={{ flex: 1 }}>
                                <Form.Label>Select Resource Type</Form.Label>
                                <Form.Select
                                    value={selectedResourceTypeForView}
                                    onChange={(e) => setSelectedResourceTypeForView(e.target.value)}
                                >
                                    {SUPPORTED_RESOURCE_TYPES.map(type => (
                                        <option key={type} value={type}>{type}</option>
                                    ))}
                                </Form.Select>
                            </Form.Group>
                        </div>

                        <Table striped bordered hover responsive>
                            <thead>
                                {renderTableHeader(selectedResourceTypeForView)}
                            </thead>
                            <tbody>
                                {selectedPatientForView && downloadedData[selectedPatientForView] &&
                                    renderDataRowList(
                                        selectedResourceTypeForView,
                                        downloadedData[selectedPatientForView][selectedResourceTypeForView]
                                    )
                                }
                            </tbody>
                        </Table>
                    </Card.Body>
                </Card>
            )}
        </Container>
    );
}

export default ProviderDataAccess;
