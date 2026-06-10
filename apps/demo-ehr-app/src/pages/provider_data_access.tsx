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
import { useEffect, useMemo, useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate } from "react-router-dom";
import { Container, Card, Form, Button, Alert, Spinner, Table, Row, Col, Badge } from "react-bootstrap";
import Select, { SingleValue } from "react-select";
import { CloudSync, ArrowBack, Storage } from "@mui/icons-material";
import axios from "axios";
import {
    appendRequestLog,
    clearRequestLogs,
    setStackedRequestLogs,
} from "../redux/currentStateSlice";
import { HTTP_METHODS } from "../constants/enum";

const getPatientDisplayName = (
    patientId: string,
    patientData?: { [resourceType: string]: any[] }
): string => {
    const patientResources = patientData?.Patient;
    if (patientResources && patientResources.length > 0) {
        const patient = patientResources[0];
        const name = patient.name?.[0];
        if (name) {
            const given = name.given?.join(" ") || "";
            const family = name.family || "";
            const fullName = `${given} ${family}`.trim();
            if (fullName) {
                return `${fullName} (ID: ${patient.id ?? patientId})`;
            }
        }
    }
    return `Patient ${patientId}`;
};

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
    const dispatch = useDispatch();

    useEffect(() => {
        dispatch(setStackedRequestLogs(true));
        return () => {
            dispatch(setStackedRequestLogs(false));
            dispatch(clearRequestLogs());
        };
    }, [dispatch]);

    const patientOptions = useMemo(
        () =>
            Object.keys(downloadedData).map((patientId) => ({
                value: patientId,
                label: getPatientDisplayName(patientId, downloadedData[patientId]),
            })),
        [downloadedData]
    );

    const logToDevConsole = (
        method: string,
        payerFhirUrl: string,
        response: unknown,
        request: Record<string, unknown> = {}
    ) => {
        dispatch(
            appendRequestLog({
                method,
                url: payerFhirUrl,
                request,
                response,
            })
        );
    };

    const handleFetchData = async () => {
        const npi = Config.npi;
        if (!npi) {
            setErrorMsg("Missing NPI in application config.");
            return;
        }

        console.log(`[Provider Access] Initiating bulk data sync for NPI: ${npi}`);
        setLoading(true);
        setErrorMsg("");

        dispatch(clearRequestLogs());

        try {
            const orgUrl = `${Config.demoBaseUrl}${Config.organization}?identifier=${npi}`;

            // 1. Fetch Organization by NPI identifier
            const orgResponse = await axios.get(`${Config.organization}?identifier=${npi}`);
            logToDevConsole(HTTP_METHODS.GET, orgUrl, orgResponse.data);

            if (!orgResponse.data || !orgResponse.data.entry || orgResponse.data.entry.length === 0) {
                throw new Error(`No Organization found for NPI: ${npi}`);
            }
            if (orgResponse.data.entry.length > 1) {
                throw new Error(`Multiple Organizations found for NPI: ${npi}. Expected only one.`);
            }

            const organizationId = orgResponse.data.entry[0].resource.id;

            const groupUrl = `${Config.demoBaseUrl}${Config.group}?managing-entity=Organization/${organizationId}`;

            // 2. Fetch Group by managing-entity
            const groupResponse = await axios.get(`${Config.group}?managing-entity=Organization/${organizationId}`);
            logToDevConsole(HTTP_METHODS.GET, groupUrl, groupResponse.data);

            if (!groupResponse.data || !groupResponse.data.entry || groupResponse.data.entry.length === 0) {
                throw new Error(`No Group found managed by Organization: ${organizationId}`);
            }

            const groupId = groupResponse.data.entry[0].resource.id;
            console.log(`[Provider Access] Found Group ID: ${groupId} for Organization: ${organizationId}`);

            // 3. Trigger Group Export
            console.log(`[Provider Access] Triggering Group /$export operation...`);

            const exportUrl = `${Config.demoBaseUrl}${Config.group}/${groupId}/$export`;

            const exportResponse = await axios.get(`${Config.group}/${groupId}/$export`);
            logToDevConsole(HTTP_METHODS.GET, exportUrl, exportResponse.data);

            if (exportResponse.data && exportResponse.data.exportUrls) {
                console.log(`[Provider Access] Group /$export Accepted. Transaction Time: ${exportResponse.data.transactionTime}`);
                console.log(`[Provider Access] Received Status Polling URLs for group members:`, exportResponse.data.exportUrls);
                pollExportStatus(exportResponse.data.exportUrls);
            } else {
                throw new Error("Invalid response received from Group Export API.");
            }

        } catch (error: any) {
            console.error("Provider Data Access Error:", error);
            logToDevConsole(
                HTTP_METHODS.GET,
                `${Config.demoBaseUrl}${Config.organization}`,
                error.response?.data ?? { error: error.message || "An unexpected error occurred." }
            );
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
            const proxyBasePath = window.Config.group.replace("/Group", "");
            let pollingUrl = originalUrl;

            if (exportPathIndex !== -1) {
                const relativeExportUrl = originalUrl.substring(exportPathIndex);
                pollingUrl = `${proxyBasePath}/${relativeExportUrl}`;
            }

            const payerPollingUrl = originalUrl.startsWith("http")
                ? originalUrl
                : `${Config.demoBaseUrl}${pollingUrl.startsWith("/") ? pollingUrl : `/${pollingUrl}`}`;

            while (!isReady && retries < MAX_RETRIES) {
                try {
                    const statusResponse = await axios.get(pollingUrl);

                    if (statusResponse.status === 200) {
                        logToDevConsole(HTTP_METHODS.GET, payerPollingUrl, statusResponse.data);
                        isReady = true;
                        if (statusResponse.data && statusResponse.data.output) {
                            console.log(`[Provider Access] [Patient: ${patientId}] Export completed successfully. Data received:`, statusResponse.data.output);

                            // Immediately fetch the supported ndjson files
                            await fetchNdjsonData(patientId, statusResponse.data.output);
                        } else {
                            console.warn(`[Provider Access] [Patient: ${patientId}] Export ready but no output links provided.`);
                        }
                    } else if (statusResponse.status === 202) {
                        logToDevConsole(HTTP_METHODS.GET, payerPollingUrl, {
                            status: 202,
                            message: "Export pending",
                            patientId,
                            attempt: retries + 1,
                            maxRetries: MAX_RETRIES,
                        });
                        console.log(`[Provider Access] [Patient: ${patientId}] Export pending (202). Retrying in 2 seconds... (Attempt ${retries + 1}/${MAX_RETRIES})`);
                        await new Promise((resolve) => setTimeout(resolve, 2000));
                        retries++;
                    } else {
                        throw new Error(`Unexpected status: ${statusResponse.status}`);
                    }
                } catch (err: any) {
                    isReady = true; // Stop polling on error
                    logToDevConsole(
                        HTTP_METHODS.GET,
                        payerPollingUrl,
                        err.response?.data ?? { error: err.message || "Polling failed", patientId }
                    );
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

                    const payerDownloadUrl = originalUrl.startsWith("http")
                        ? originalUrl
                        : `${Config.demoBaseUrl}${downloadUrl.startsWith("/") ? downloadUrl : `/${downloadUrl}`}`;

                    const res = await axios.get(downloadUrl, { responseType: 'text' });
                    const lines = res.data.split('\n').filter((line: string) => line.trim() !== '');
                    const resources = lines.map((line: string) => JSON.parse(line));
                    patientData[output.type] = resources;

                    logToDevConsole(
                        HTTP_METHODS.GET,
                        payerDownloadUrl,
                        {
                            resourceType: output.type,
                            patientId,
                            recordCount: resources.length,
                            resources,
                        },
                        { resourceType: output.type, patientId }
                    );
                } catch (e: any) {
                    console.error(`Failed to download ${output.type} for patient ${patientId}`, e);
                    logToDevConsole(
                        HTTP_METHODS.GET,
                        output.url?.startsWith("http") ? output.url : `${Config.demoBaseUrl}${output.url || ""}`,
                        e.response?.data ?? { error: e.message || "Download failed", resourceType: output.type, patientId }
                    );
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
                return list.map((res: any, i) => {
                    const lineItems = res.item || [];
                    const calculatedTotalVal = lineItems.reduce((acc: number, item: any) => {
                        const unitPrice = item.unitPrice?.value || 0;
                        const qty = item.quantity?.value || 0;
                        return acc + (unitPrice * qty);
                    }, 0);
                    const currency = lineItems[0]?.unitPrice?.currency || "";
                    const displayCode = lineItems[0]?.productOrService?.coding?.[0]?.display || "N/A";

                    return (
                        <tr key={i}>
                            <td>{res.id}</td>
                            <td>{res.type?.coding?.[0]?.code}</td>
                            <td>{res.status}</td>
                            <td>{displayCode}</td>
                            <td>{calculatedTotalVal} {currency}</td>
                        </tr>
                    );
                });
            case "ClaimResponse":
                return list.map((res: any, i) => {
                    const items = res.item || [];
                    const calculatedBenefitVal = items.reduce((acc: number, currentItem: any) => {
                        const adjudications = currentItem.adjudication || [];
                        const benefitAdjs = adjudications.filter((adj: any) =>
                            adj.category?.coding?.some((codeObj: any) => codeObj.code === "benefit")
                        );
                        const benefitSum = benefitAdjs.reduce((bAcc: number, bAdj: any) => bAcc + (bAdj.amount?.value || 0), 0);
                        return acc + benefitSum;
                    }, 0);

                    // Try to extract currency from the first benefit adjudication found, fallback to USD
                    let currency = "USD";
                    if (items.length > 0 && items[0].adjudication) {
                        const firstBenefit = items[0].adjudication.find((adj: any) =>
                            adj.category?.coding?.some((codeObj: any) => codeObj.code === "benefit")
                        );
                        if (firstBenefit && firstBenefit.amount?.currency) {
                            currency = firstBenefit.amount.currency;
                        }
                    }

                    return (
                        <tr key={i}>
                            <td>{res.id}</td>
                            <td>{res.outcome}</td>
                            <td>{res.disposition}</td>
                            <td>{calculatedBenefitVal} {currency}</td>
                            <td>{res.created}</td>
                        </tr>
                    );
                });
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
                return <tr><th>ID</th><th>Type</th><th>Status</th><th>Product/Service</th><th>Total (Calculated)</th></tr>;
            case "ClaimResponse":
                return <tr><th>ID</th><th>Outcome</th><th>Disposition</th><th>Benefit Amount</th><th>Created Date</th></tr>;
            case "Coverage":
                return <tr><th>ID</th><th>Status</th><th>Type</th><th>Subscriber ID</th><th>Period</th></tr>;
            default:
                return <tr><th>Data</th></tr>;
        }
    };

    const handlePatientSelectChange = (
        selectedOption: SingleValue<{ value: string; label: string }>
    ) => {
        if (selectedOption?.value) {
            setSelectedPatientForView(selectedOption.value);
        }
    };

    const selectedPatientOption = patientOptions.find(
        (option) => option.value === selectedPatientForView
    ) ?? null;

    return (
        <Container style={{ marginTop: "40px", paddingBottom: "40px", maxWidth: 1200 }}>
            <Button
                variant="outline-secondary"
                onClick={() => navigate(-1)}
                style={{ marginBottom: "24px", borderRadius: "20px", display: "inline-flex", alignItems: "center", gap: 6 }}
            >
                <ArrowBack sx={{ fontSize: 18 }} />
                Back
            </Button>

            <div className="page-heading" style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <CloudSync sx={{ fontSize: 40, color: "#006B75" }} />
                Provider Data Access
            </div>

            <Card className="shadow-sm border-0" style={{ marginTop: "8px" }}>
                <Card.Body style={{ padding: "30px" }}>
                    <Card.Title style={{ fontSize: "1.35rem", fontWeight: 600 }}>
                        Import Health Records from Payer Networks
                    </Card.Title>
                    <Card.Text style={{ color: "#555", fontSize: "1.05rem", marginTop: "8px" }}>
                        Synchronize bulk health records for your practice via the Provider Access API.
                        API traffic with the payer FHIR server is shown in the Developer Console.
                    </Card.Text>

                    {Config.payers && Config.payers.length > 0 && (
                        <Form.Group style={{ marginTop: "24px", maxWidth: 480 }}>
                            <Form.Label style={{ fontWeight: 600 }}>
                                Select Payer Network <span style={{ color: "red" }}>*</span>
                            </Form.Label>
                            <Form.Select
                                value={selectedPayer}
                                onChange={(e) => setSelectedPayer(e.target.value)}
                                style={{ borderRadius: 8 }}
                            >
                                <option value="" disabled>-- Select a Payer --</option>
                                {Config.payers.map((payer) => (
                                    <option key={payer.id} value={payer.id}>{payer.name}</option>
                                ))}
                            </Form.Select>
                        </Form.Group>
                    )}

                    {errorMsg && (
                        <Alert variant="danger" style={{ marginTop: "20px", borderRadius: 8 }}>
                            {errorMsg}
                        </Alert>
                    )}

                    <Button
                        variant="primary"
                        style={{
                            marginTop: "24px",
                            borderRadius: "20px",
                            padding: "10px 28px",
                            fontWeight: 600,
                            display: "inline-flex",
                            alignItems: "center",
                            gap: 8,
                        }}
                        onClick={handleFetchData}
                        disabled={loading || !selectedPayer}
                    >
                        {loading ? (
                            <>
                                <Spinner as="span" animation="border" size="sm" role="status" aria-hidden="true" />
                                Syncing...
                            </>
                        ) : (
                            <>
                                <CloudSync sx={{ fontSize: 20 }} />
                                Sync Data
                            </>
                        )}
                    </Button>
                </Card.Body>
            </Card>

            {Object.keys(downloadedData).length > 0 && (
                <Card className="shadow-sm border-0" style={{ marginTop: "24px" }}>
                    <Card.Header
                        style={{
                            backgroundColor: "#f8fafc",
                            borderBottom: "1px solid #e2e8f0",
                            fontWeight: 600,
                            display: "flex",
                            alignItems: "center",
                            gap: 8,
                            padding: "16px 24px",
                        }}
                    >
                        <Storage sx={{ fontSize: 22, color: "#006B75" }} />
                        Health Records Viewer
                        <Badge bg="secondary" style={{ marginLeft: 8 }}>
                            {Object.keys(downloadedData).length} patient{Object.keys(downloadedData).length !== 1 ? "s" : ""}
                        </Badge>
                    </Card.Header>
                    <Card.Body style={{ padding: "24px" }}>
                        <Row className="g-3" style={{ marginBottom: "20px" }}>
                            <Col md={6}>
                                <Form.Group>
                                    <Form.Label style={{ fontWeight: 600 }}>Select Patient</Form.Label>
                                    <Select
                                        value={selectedPatientOption}
                                        options={patientOptions}
                                        onChange={handlePatientSelectChange}
                                        isSearchable
                                        placeholder="Search by patient name..."
                                    />
                                </Form.Group>
                            </Col>

                            <Col md={6}>
                                <Form.Group>
                                    <Form.Label style={{ fontWeight: 600 }}>Select Resource Type</Form.Label>
                                    <Form.Select
                                        value={selectedResourceTypeForView}
                                        onChange={(e) => setSelectedResourceTypeForView(e.target.value)}
                                        style={{ borderRadius: 8 }}
                                    >
                                        {SUPPORTED_RESOURCE_TYPES.map(type => (
                                            <option key={type} value={type}>{type}</option>
                                        ))}
                                    </Form.Select>
                                </Form.Group>
                            </Col>
                        </Row>

                        <div style={{ borderRadius: 8, overflow: "hidden", border: "1px solid #e2e8f0" }}>
                            <Table striped hover responsive className="mb-0">
                                <thead style={{ backgroundColor: "#f1f5f9" }}>
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
                        </div>
                    </Card.Body>
                </Card>
            )}
        </Container>
    );
}

export default ProviderDataAccess;
