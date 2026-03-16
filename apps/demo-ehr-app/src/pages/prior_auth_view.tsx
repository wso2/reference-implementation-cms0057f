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

import { useEffect, useState } from "react";
import axios from "axios";
import { useParams, Navigate, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import Spinner from "react-bootstrap/Spinner";
import { Alert, Snackbar } from "@mui/material";
import { useAuth } from "../components/AuthProvider";
import PatientInfo from "../components/PatientInfo";
import {
    updateCurrentRequest,
    updateCurrentResponse,
    updateCurrentRequestUrl,
    updateCurrentRequestMethod,
} from "../redux/currentStateSlice";
import {
    updateActiveStep,
    updateSingleStep,
    StepStatus,
} from "../redux/commonStoargeSlice";
import {
    CLAIM_PAYER_NOTIFICATION,
    SELECTED_PATIENT_ID,
    SELECTED_PATIENT_NAME,
} from "../constants/localStorageVariables";

export default function PriorAuthView() {
    const { isAuthenticated } = useAuth();
    const { claimId } = useParams();
    const navigate = useNavigate();
    const dispatch = useDispatch();
    const loggedUser = useSelector((state: any) => state.loggedUser);

    const [claimData, setClaimData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [patientDisplay, setPatientDisplay] = useState<string>("Unknown");
    const [insurerDisplay, setInsurerDisplay] = useState<string>("Unknown");
    const [coverageIdDisplay, setCoverageIdDisplay] = useState<string>("Unknown");
    const [qrDisplay, setQrDisplay] = useState<string>("Unknown");
    const [alertMessage, setAlertMessage] = useState<string | null>(null);
    const [alertSeverity, setAlertSeverity] = useState<"error" | "warning" | "info" | "success">("info");
    const [openSnackbar, setOpenSnackbar] = useState(false);
    const [approvedAmountDisplay, setApprovedAmountDisplay] = useState<string>("Pending");
    const [claimStatusDisplay, setClaimStatusDisplay] = useState<string>("Pending");

    useEffect(() => {
        if (!claimId) return;

        const claimUrl = window.Config.claim || "/choreo-apis/cms-paas/fhir-service-fm/v1/Claim";
        const webhookUrl = window.Config.webhookServerUrl || "http://localhost:9099";

        axios.get(`${claimUrl}/${claimId}`)
            .then(response => {
                setClaimData(response.data);
            })
            .catch(error => {
                console.error("Error fetching Claim:", error);
                setAlertMessage("Failed to fetch Claim data");
                setAlertSeverity("error");
                setOpenSnackbar(true);
            })
            .finally(() => {
                setLoading(false);
            });

        axios.get(`${webhookUrl}/claim-notification/${claimId}`)
            .then(response => {
                const bundle = response.data;
                localStorage.setItem(CLAIM_PAYER_NOTIFICATION, JSON.stringify(bundle));
                dispatch(updateCurrentRequest({
                    "(no outbound request)": "Received from payer via webhook",
                }));
                dispatch(updateCurrentResponse(bundle));
                dispatch(updateCurrentRequestUrl("Payer notification (received via webhook)"));
                dispatch(updateCurrentRequestMethod("N/A"));
                dispatch(updateActiveStep(5));
                dispatch(updateSingleStep({ stepName: "Payer notification", newStatus: StepStatus.COMPLETED }));

                try {
                    // Extract ClaimResponse and approved (benefit) amount from notification bundle
                    const innerBundle = bundle.entry?.find(
                        (e: any) => e.resource?.resourceType === "Bundle"
                    )?.resource;
                    const claimResponse = innerBundle?.entry?.find(
                        (e: any) => e.resource?.resourceType === "ClaimResponse"
                    )?.resource;

                    if (claimResponse) {
                        const outcome = claimResponse.outcome as string | undefined;
                        const disposition = claimResponse.disposition as string | undefined;
                        const status = claimResponse.status as string | undefined;

                        const isComplete =
                            outcome === "complete" ||
                            disposition === "complete" ||
                            status === "active";

                        setClaimStatusDisplay(isComplete ? "Completed" : "Pending");

                        const firstItem = claimResponse.item?.[0];
                        const benefitAdjudication = firstItem?.adjudication?.find(
                            (adj: any) =>
                                adj.category?.coding?.some(
                                    (c: any) => c.code === "benefit"
                                )
                        );
                        const amount = benefitAdjudication?.amount;

                        if (amount?.value != null) {
                            const currency = amount.currency || "USD";
                            setApprovedAmountDisplay(`${amount.value} ${currency}`);
                        } else {
                            setApprovedAmountDisplay("Pending");
                        }
                    } else {
                        setClaimStatusDisplay("Pending");
                        setApprovedAmountDisplay("Pending");
                    }
                } catch (e) {
                    console.error("Failed to parse payer notification bundle", e);
                    setClaimStatusDisplay("Pending");
                    setApprovedAmountDisplay("Pending");
                }
            })
            .catch(() => {
                localStorage.removeItem(CLAIM_PAYER_NOTIFICATION);
                dispatch(updateCurrentResponse({}));
                setClaimStatusDisplay("Pending");
                setApprovedAmountDisplay("Pending");
            });
    }, [claimId, dispatch]);

    // Resolve human-friendly details similar to claim-submit page
    useEffect(() => {
        if (!claimData) {
            return;
        }

        const Config = window.Config;

        // Patient name (e.g., "John Smith (ID: 101)")
        const patientRef = claimData.patient?.reference as string | undefined;
        if (patientRef && Config.patient) {
            const patientId = patientRef.startsWith("Patient/")
                ? patientRef.substring("Patient/".length)
                : patientRef;
            axios
                .get(`${Config.patient}/${patientId}`)
                .then((res) => {
                    const p = res.data;
                    const name = p.name?.[0];
                    const fullName =
                        (name?.given ? name.given.join(" ") + " " : "") +
                        (name?.family ?? "");
                    const label =
                        (fullName.trim() || `Patient ${patientId}`) +
                        ` (ID: ${p.id ?? patientId})`;
                    setPatientDisplay(label);
                    // Keep PatientInfo in sync when navigating from Prior Auth list
                    localStorage.setItem(
                        SELECTED_PATIENT_NAME,
                        fullName.trim() || `Patient ${patientId}`
                    );
                    localStorage.setItem(
                        SELECTED_PATIENT_ID,
                        p.id ?? patientId
                    );
                })
                .catch(() => {
                    setPatientDisplay(patientRef);
                });
        } else {
            setPatientDisplay(patientRef || "Unknown");
        }

        // Insurer organization name
        const insurerRef = claimData.insurer?.reference as string | undefined;
        if (insurerRef && Config.organization) {
            const orgId = insurerRef.startsWith("Organization/")
                ? insurerRef.substring("Organization/".length)
                : insurerRef;
            axios
                .get(`${Config.organization}/${orgId}`)
                .then((res) => {
                    setInsurerDisplay(res.data?.name || insurerRef);
                })
                .catch(() => {
                    setInsurerDisplay(insurerRef);
                });
        } else {
            setInsurerDisplay(insurerRef || "Unknown");
        }

        // Coverage ID from insurance[0].coverage.reference (e.g., "Coverage/366" -> "366")
        const coverageRef =
            claimData.insurance?.[0]?.coverage?.reference as string | undefined;
        if (coverageRef) {
            const parts = coverageRef.split("/");
            setCoverageIdDisplay(parts[parts.length - 1] || coverageRef);
        } else {
            setCoverageIdDisplay("Unknown");
        }

        // Associated QuestionnaireResponse from supportingInfo[0].valueReference.reference
        const qrRef =
            claimData.supportingInfo?.[0]?.valueReference?.reference as
                | string
                | undefined;
        if (qrRef) {
            const parts = qrRef.split("/");
            const qrId = parts[parts.length - 1] || qrRef;
            setQrDisplay(`ID: ${qrId}`);
        } else {
            setQrDisplay("Not available");
        }
    }, [claimData]);

    const handleCloseSnackbar = () => {
        setOpenSnackbar(false);
    };

    if (!isAuthenticated) {
        return <Navigate to="/" replace />;
    }

    const patientRef = patientDisplay;
    const providerRef =
        loggedUser && loggedUser.first_name && loggedUser.last_name
            ? `${loggedUser.first_name} ${loggedUser.last_name}`
            : "Unknown";
    const insurerRef = insurerDisplay;
    const useValue =
        (claimData?.use
            ? String(claimData.use).toUpperCase()
            : "PREAUTHORIZATION");
    const item = claimData?.item?.[0];
    const medication =
        item?.productOrService?.text ||
        item?.productOrService?.coding?.[0]?.display ||
        item?.productOrService?.coding?.[0]?.code ||
        item?.category?.coding?.[0]?.display ||
        "Unknown Service";
    const unitPrice = item?.unitPrice
        ? `${item.unitPrice.value} ${item.unitPrice.currency || "USD"}`
        : "Unknown";

    return (
        <div style={{ marginLeft: 50, marginBottom: 50 }}>
            <div className="page-heading">Prior Authorization Claim View</div>
            <PatientInfo />

            <Card style={{ marginTop: "30px", padding: "20px" }}>
                <Card.Body>
                    <Card.Title>Claim Details: {claimId}</Card.Title>
                    {loading ? (
                        <div className="text-center mt-5">
                            <Spinner animation="border" variant="primary" />
                        </div>
                    ) : (
                        <Form>
                            <div style={{ display: "flex", gap: "20px" }}>
                                <Form.Group controlId="patient" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Patient</Form.Label>
                                    <Form.Control type="text" value={patientRef} disabled />
                                </Form.Group>
                                <Form.Group controlId="provider" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Practitioner</Form.Label>
                                    <Form.Control type="text" value={providerRef} disabled />
                                </Form.Group>
                                <Form.Group controlId="insurer" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Insurer</Form.Label>
                                    <Form.Control type="text" value={insurerRef} disabled />
                                </Form.Group>
                            </div>

                            <div style={{ display: "flex", gap: "20px" }}>
                                <Form.Group controlId="use" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Claim Use</Form.Label>
                                    <Form.Control type="text" value={useValue} disabled />
                                </Form.Group>
                                <Form.Group controlId="coverage" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Coverage ID</Form.Label>
                                    <Form.Control type="text" value={coverageIdDisplay} disabled />
                                </Form.Group>
                            </div>

                            <Form.Group controlId="medication" style={{ marginTop: "20px" }}>
                                <Form.Label>Medication / Service Requested</Form.Label>
                                <Form.Control type="text" value={medication} disabled />
                            </Form.Group>

                            <Form.Group controlId="qr" style={{ marginTop: "20px" }}>
                                <Form.Label>Associated Questionnaire Response</Form.Label>
                                <Form.Control type="text" value={qrDisplay} disabled />
                            </Form.Group>

                            <div style={{ display: "flex", gap: "20px", marginBottom: "30px" }}>
                                <Form.Group controlId="claimStatus" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Prior Authorization Status</Form.Label>
                                    <Form.Control type="text" value={claimStatusDisplay} disabled />
                                </Form.Group>

                                <Form.Group controlId="approvedAmount" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Approved Amount</Form.Label>
                                    <Form.Control type="text" value={approvedAmountDisplay} disabled />
                                </Form.Group>

                                <Form.Group controlId="unitPrice" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Requested Amount</Form.Label>
                                    <Form.Control type="text" value={unitPrice} disabled />
                                </Form.Group>
                            </div>

                            <Button variant="secondary" onClick={() => navigate(-1)} style={{ float: "right" }}>
                                Back to List
                            </Button>
                        </Form>
                    )}
                </Card.Body>
                <Snackbar
                    open={openSnackbar}
                    autoHideDuration={6000}
                    onClose={handleCloseSnackbar}
                    anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
                >
                    <Alert onClose={handleCloseSnackbar} severity={alertSeverity}>
                        {alertMessage}
                    </Alert>
                </Snackbar>
            </Card>

            <style>{`
                .card {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                }
                .card-body {
                    flex: 1;
                }
            `}</style>
        </div>
    );
}
