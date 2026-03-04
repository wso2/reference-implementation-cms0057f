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
import { Container, Row, Col, Card, Button } from "react-bootstrap";
import { useNavigate, Navigate } from "react-router-dom";
import { useAuth } from "../components/AuthProvider";
import { MedicalServices, CloudSync } from "@mui/icons-material";

function HomePage() {
    const navigate = useNavigate();
    const { isAuthenticated } = useAuth();

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    const userDataText = localStorage.getItem("loggedUser");
    let userName = "Provider";
    if (userDataText) {
        try {
            const userData = JSON.parse(userDataText);
            userName = userData.name || "Provider";
        } catch (e) {
            console.error("Failed to parse user data", e);
        }
    }

    // Default to Dr. James Smith if name is not available from storage for aesthetic purposes in the demo
    const displayName = userName !== "Provider" ? userName : "Dr. James Smith";

    return (
        <Container style={{ marginTop: "60px" }}>
            <div style={{ marginBottom: "40px" }}>
                <h2 style={{ fontWeight: 600 }}>Welcome, {displayName}</h2>
                <p className="text-muted" style={{ fontSize: "1.1rem" }}>Please select an action below:</p>
            </div>

            <Row className="g-4">
                <Col md={6}>
                    <Card className="h-100 shadow-sm border-0" style={{ transition: "transform 0.2s", cursor: "pointer" }} onClick={() => navigate("/patient-encounter")}>
                        <Card.Body className="d-flex flex-column" style={{ padding: "30px" }}>
                            <div style={{ color: "#006B75", marginBottom: "20px" }}>
                                <MedicalServices sx={{ fontSize: "4rem" }} />
                            </div>
                            <Card.Title style={{ fontSize: "1.5rem", fontWeight: "bold" }}>Patient Treatment</Card.Title>
                            <Card.Text style={{ fontSize: "1.1rem", color: "#555", flex: 1, marginTop: "10px" }}>
                                Access patient records, start encounters, and manage clinical history.
                            </Card.Text>
                            <Button
                                variant="outline-primary"
                                className="mt-4 align-self-start"
                                style={{ borderRadius: "20px", padding: "8px 24px", fontWeight: "bold" }}
                                onClick={(e) => { e.stopPropagation(); navigate("/patient-encounter"); }}
                            >
                                Go to Patients &rarr;
                            </Button>
                        </Card.Body>
                    </Card>
                </Col>

                <Col md={6}>
                    <Card className="h-100 shadow-sm border-0" style={{ transition: "transform 0.2s", cursor: "pointer" }} onClick={() => navigate("/provider-data-access")}>
                        <Card.Body className="d-flex flex-column" style={{ padding: "30px" }}>
                            <div style={{ color: "#006B75", marginBottom: "20px" }}>
                                <CloudSync sx={{ fontSize: "4rem" }} />
                            </div>
                            <Card.Title style={{ fontSize: "1.5rem", fontWeight: "bold" }}>Data Sync</Card.Title>
                            <Card.Text style={{ fontSize: "1.1rem", color: "#555", flex: 1, marginTop: "10px" }}>
                                Connect with payer networks and synchronize data via Provider Access API.
                            </Card.Text>
                            <Button
                                variant="outline-primary"
                                className="mt-4 align-self-start"
                                style={{ borderRadius: "20px", padding: "8px 24px", fontWeight: "bold" }}
                                onClick={(e) => { e.stopPropagation(); navigate("/provider-data-access"); }}
                            >
                                Go to Data Sync &rarr;
                            </Button>
                        </Card.Body>
                    </Card>
                </Col>
            </Row>
        </Container>
    );
}

export default HomePage;
