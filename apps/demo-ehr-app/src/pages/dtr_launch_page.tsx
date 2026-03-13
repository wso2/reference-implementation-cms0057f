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

import { useEffect } from "react";
import { useAuth } from "../components/AuthProvider";
import { Navigate, useNavigate, useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";
import { appendRequestLog } from "../redux/currentStateSlice";
import {
    QUESTIONNAIRE_PACKAGE_REQUEST,
    QUESTIONNAIRE_PACKAGE_RESPONSE,
    QUESTIONNAIRE_PACKAGE_URL,
    QUESTIONNAIRE_PACKAGE_REQUEST_METHOD,
} from "../constants/localStorageVariables";
import PatientInfo from "../components/PatientInfo";

const useQuery = () => {
    return new URLSearchParams(useLocation().search);
};

export default function DtrLaunchPage() {
    const { isAuthenticated } = useAuth();
    const navigate = useNavigate();
    const dispatch = useDispatch();
    const query = useQuery();
    const dtrUrl = query.get("dtrUrl");

    useEffect(() => {
        const handleMessage = (event: MessageEvent) => {
            // Check for the expected message type from the embedded DTR app
            if (event.data && event.data.type === "DTR_CLAIM_SUBMIT") {
                console.log("Received DTR_CLAIM_SUBMIT message:", event.data.payload);
                const { patientId, serviceRequestId, medicationRequestId, coverageId, qrId } = event.data.payload;

                // Build the claim submit URL parameters
                const params = new URLSearchParams();
                if (patientId) params.append("patientId", patientId);
                if (serviceRequestId) params.append("serviceRequestId", serviceRequestId);
                if (medicationRequestId) params.append("medicationRequestId", medicationRequestId);
                if (coverageId) params.append("coverageId", coverageId);
                if (qrId) params.append("qrId", qrId);

                navigate(`/dashboard/claim-submit?${params.toString()}`);
            } else if (event.data && event.data.type === "DTR_QUESTIONNAIRE_RESPONSE_LOG") {
                console.log("Received DTR_QUESTIONNAIRE_RESPONSE_LOG message:", event.data.payload);
                dispatch(appendRequestLog(event.data.payload));
            } else if (event.data && event.data.type === "DTR_QUESTIONNAIRE_PACKAGE_LOG") {
                console.log("Received DTR_QUESTIONNAIRE_PACKAGE_LOG message:", event.data.payload);
                dispatch(appendRequestLog(event.data.payload));

                // Store in localStorage for the "Questionnaire package" Developer Console tab
                if (event.data.payload.request) {
                    localStorage.setItem(QUESTIONNAIRE_PACKAGE_REQUEST, JSON.stringify(event.data.payload.request));
                }
                if (event.data.payload.response) {
                    localStorage.setItem(QUESTIONNAIRE_PACKAGE_RESPONSE, JSON.stringify(event.data.payload.response));
                }
                if (event.data.payload.url) {
                    const Config = window.Config;
                    const fullUrl = event.data.payload.url.startsWith("http") ? event.data.payload.url : Config.demoBaseUrl + event.data.payload.url;
                    localStorage.setItem(QUESTIONNAIRE_PACKAGE_URL, fullUrl);
                }
                if (event.data.payload.method) {
                    localStorage.setItem(QUESTIONNAIRE_PACKAGE_REQUEST_METHOD, event.data.payload.method);
                }
            }
        };

        window.addEventListener("message", handleMessage);

        // Cleanup the event listener on unmount
        return () => {
            window.removeEventListener("message", handleMessage);
        };
    }, [navigate]);

    return isAuthenticated ? (
        <div style={{ marginLeft: 50, marginBottom: 50, height: "calc(100vh - 100px)", display: "flex", flexDirection: "column" }}>
            <div className="page-heading">DTR Questionnaire</div>
            <PatientInfo />
            {dtrUrl ? (
                <div style={{ flex: 1, marginTop: "20px", border: "1px solid #ddd", borderRadius: "8px", overflow: "hidden" }}>
                    <iframe
                        src={dtrUrl}
                        style={{ width: "100%", height: "100%", border: "none" }}
                        title="DTR Questionnaire"
                    />
                </div>
            ) : (
                <div style={{ marginTop: "20px", padding: "20px", color: "red" }}>
                    No DTR URL provided.
                </div>
            )}
        </div>
    ) : (
        <Navigate to="/" replace />
    );
}
