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
import { Container, Table, Spinner, Badge, Button } from "react-bootstrap";
import { useNavigate } from "react-router-dom";

interface PriorAuth {
    id: string;
    patientName: string;
    providerName: string;
    medicationRef: string;
    date: string;
    status: string;
    outcome: string;
}

export default function PriorAuthList() {
    const [priorAuths, setPriorAuths] = useState<PriorAuth[]>([]);
    const [loading, setLoading] = useState(true);
    const navigate = useNavigate();

    useEffect(() => {
        fetchPriorAuths();
    }, []);

    const fetchPriorAuths = async () => {
        try {
            const webhookUrl = window.Config.webhookServerUrl || "http://localhost:9099";
            const response = await axios.get(`${webhookUrl}/claims`);
            setPriorAuths(response.data);
        } catch (error) {
            console.error("Failed to fetch Prior Authorizations", error);
        } finally {
            setLoading(false);
        }
    };

    const getStatusBadge = (outcome: string) => {
        switch (outcome.toLowerCase()) {
            case "complete":
                return <Badge bg="success">Completed</Badge>;
            case "partial":
            case "queued":
                return <Badge bg="warning" text="dark">Pending</Badge>;
            case "error":
                return <Badge bg="danger">Error</Badge>;
            default:
                return <Badge bg="secondary">{outcome}</Badge>;
        }
    };

    return (
        <Container className="mt-5 prior-auth-container p-4">
            <h2 className="mb-4 text-start">Prior Authorizations</h2>
            {loading ? (
                <div className="text-center mt-5">
                    <Spinner animation="border" variant="primary" />
                </div>
            ) : (
                <div className="table-responsive shadow-sm rounded">
                    <Table hover className="align-middle">
                        <thead className="table-light">
                            <tr>
                                <th>Claim ID</th>
                                <th>Patient</th>
                                <th>Medication</th>
                                <th>Submission Date</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {priorAuths.length > 0 ? (
                                priorAuths.map((auth) => (
                                    <tr key={auth.id}>
                                        <td>{auth.id}</td>
                                        <td>{auth.patientName}</td>
                                        <td>{auth.medicationRef}</td>
                                        <td>{auth.date}</td>
                                        <td>{getStatusBadge(auth.outcome)}</td>
                                        <td>
                                            <Button
                                                variant="outline-primary"
                                                size="sm"
                                                onClick={() => navigate(`/dashboard/prior-auth-list/${auth.id}`)}
                                            >
                                                View
                                            </Button>
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan={6} className="text-center py-4">
                                        No prior authorizations found.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </Table>
                </div>
            )}
        </Container>
    );
}
