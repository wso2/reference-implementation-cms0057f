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
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import Spinner from "react-bootstrap/Spinner";
import { Alert, Snackbar } from "@mui/material";
import { useAuth } from "../components/AuthProvider";
import PatientInfo from "../components/PatientInfo";

export default function PriorAuthView() {
    const { isAuthenticated } = useAuth();
    const { claimId } = useParams();
    const navigate = useNavigate();

    const [claimData, setClaimData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [alertMessage, setAlertMessage] = useState<string | null>(null);
    const [alertSeverity, setAlertSeverity] = useState<"error" | "warning" | "info" | "success">("info");
    const [openSnackbar, setOpenSnackbar] = useState(false);

    useEffect(() => {
        if (!claimId) return;

        const claimUrl = window.Config.claim || "/choreo-apis/cms-paas/fhir-service-fm/v1/Claim";
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
    }, [claimId]);

    const handleCloseSnackbar = () => {
        setOpenSnackbar(false);
    };

    if (!isAuthenticated) {
        return <Navigate to="/" replace />;
    }

    const patientRef = claimData?.patient?.reference || "Unknown";
    const providerRef = claimData?.provider?.reference || "Unknown";
    const insurerRef = claimData?.insurer?.reference || "Unknown";
    const useValue = claimData?.use || "Unknown";
    const category = claimData?.type?.coding?.[0]?.code || claimData?.type?.coding?.[0]?.display || "Pharmacy";

    const item = claimData?.item?.[0];
    const medication = item?.productOrService?.concept?.coding?.[0]?.display || item?.productOrService?.reference || item?.productOrService?.text || "Unknown";
    const quantity = item?.quantity?.value || "Unknown";
    const unitPrice = item?.unitPrice ? `${item.unitPrice.value} ${item.unitPrice.currency || 'USD'}` : "Unknown";

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
                                <Form.Group controlId="category" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Category</Form.Label>
                                    <Form.Control type="text" value={category} disabled />
                                </Form.Group>
                                <Form.Group controlId="use" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Use</Form.Label>
                                    <Form.Control type="text" value={useValue.toLocaleUpperCase()} disabled />
                                </Form.Group>
                            </div>

                            <Form.Group controlId="medication" style={{ marginTop: "20px" }}>
                                <Form.Label>Product/Service</Form.Label>
                                <Form.Control type="text" value={medication} disabled />
                            </Form.Group>

                            <div style={{ display: "flex", gap: "20px", marginBottom: "30px" }}>
                                <Form.Group controlId="quantity" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Quantity</Form.Label>
                                    <Form.Control type="text" value={quantity} disabled />
                                </Form.Group>

                                <Form.Group controlId="unitPrice" style={{ marginTop: "20px", flex: "1 1 100%" }}>
                                    <Form.Label>Unit Price</Form.Label>
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
