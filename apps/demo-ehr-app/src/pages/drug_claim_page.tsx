// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import { useDispatch, useSelector } from "react-redux";
import {
  CREATE_PAS_CLAIM_BUNDLE,
} from "../constants/data";
import { useAuth } from "../components/AuthProvider";
import { Navigate, useNavigate, useLocation } from "react-router-dom";
import { Alert, CircularProgress, Snackbar } from "@mui/material";
import {
  SELECTED_PATIENT_ID,
  CLAIM_REQUEST,
  CLAIM_REQUEST_METHOD,
  CLAIM_REQUEST_URL,
  CLAIM_RESPONSE,
  QUESTIONNAIRE_RESPONSE,
  QUESTIONNAIRE_RESPONSE_REQUEST,
  QUESTIONNAIRE_RESPONSE_METHOD,
  QUESTIONNAIRE_RESPONSE_URL,
} from "../constants/localStorageVariables";
import { HTTP_METHODS } from "../constants/enum";
import {
  updateIsProcess,
  updateCurrentResponse,
  updateCurrentRequest,
  updateCurrentRequestUrl,
  updateCurrentRequestMethod,
} from "../redux/currentStateSlice";
import {
  StepStatus,
  updateActiveStep,
  updateSingleStep,
} from "../redux/commonStoargeSlice";
import PatientInfo from "../components/PatientInfo";

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

const ClaimForm = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const query = useQuery();

  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);
  const [loading, setLoading] = useState(true);
  const [itemAmount, setItemAmount] = useState<string>("");

  // Resources state
  const [resources, setResources] = useState<{
    patient: any;
    request: any;
    qr: any;
    coverage: any;
    providerOrg: any;
    payerOrg: any;
  } | null>(null);

  const patientId = query.get("patientId") || localStorage.getItem(SELECTED_PATIENT_ID) || "101";
  const medicationRequestId = query.get("medicationRequestId");
  const serviceRequestId = query.get("serviceRequestId");
  const qrId = query.get("qrId");
  const coverageId = query.get("coverageId");

  console.log("ClaimPage IDs:", { patientId, medicationRequestId, serviceRequestId, qrId, coverageId });

  const loggedUser = useSelector((state: any) => state.loggedUser);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      const Config = window.Config;
      try {
        // Fetch resources (QR and Coverage handle null/fallback)
        const fetchQr = async () => {
          const saveQRToLocalStorage = (qrResource: any) => {
            localStorage.setItem(QUESTIONNAIRE_RESPONSE, JSON.stringify(qrResource));
            const resource = { ...qrResource };
            delete resource.id;
            delete resource.authored;
            localStorage.setItem(QUESTIONNAIRE_RESPONSE_REQUEST, JSON.stringify(resource));
            localStorage.setItem(QUESTIONNAIRE_RESPONSE_METHOD, HTTP_METHODS.POST);
            localStorage.setItem(QUESTIONNAIRE_RESPONSE_URL, Config.demoBaseUrl + Config.questionnaire_response);
          };

          if (qrId && qrId !== "null") {
            try {
              const res = await axios.get(`${Config.questionnaire_response}/${qrId}`);
              saveQRToLocalStorage(res.data);
              return res;
            } catch (err) {
              console.warn(`Failed to fetch QR by ID ${qrId}, trying fallback search.`);
            }
          }
          // Fallback: search for the latest QuestionnaireResponse for this patient
          console.log(`Attempting fallback search for QuestionnaireResponse for Patient/${patientId} with page=6&_count=10`);
          const searchRes = await axios.get(`${Config.questionnaire_response}?subject=Patient/${patientId}&page=6&_count=10`);
          if (searchRes.data?.entry?.length > 0) {
            const lastEntryIndex = searchRes.data.entry.length - 1;
            const resource = searchRes.data.entry[lastEntryIndex].resource;
            console.log("Found QR via fallback search (using last entry of page 5):", resource.id);
            saveQRToLocalStorage(resource);
            return { data: resource };
          }
          throw new Error("No QuestionnaireResponse found for this patient.");
        };

        const fetchCoverage = async () => {
          if (coverageId && coverageId !== "null") {
            try {
              return await axios.get(`${Config.coverage}/${coverageId}`);
            } catch (err) {
              console.warn(`Failed to fetch Coverage by ID ${coverageId}, trying fallback search.`);
            }
          }
          // Fallback: search for the latest Coverage for this patient
          console.log(`Attempting fallback search for Coverage for Patient/${patientId}`);
          const searchRes = await axios.get(`${Config.coverage}?patient=Patient/${patientId}&_count=1`);
          if (searchRes.data?.entry?.length > 0) {
            console.log("Found Coverage via fallback search:", searchRes.data.entry[0].resource.id);
            return { data: searchRes.data.entry[0].resource };
          }
          throw new Error("No Coverage found for this patient.");
        };

        const fetchRequest = async () => {
          // Try ServiceRequest by ID first
          if (serviceRequestId && serviceRequestId !== "null") {
            try {
              console.log(`Fetching ServiceRequest by ID: ${serviceRequestId}`);
              return await axios.get(`${Config.service_request}/${serviceRequestId}`);
            } catch (err) {
              console.warn(`Failed to fetch ServiceRequest by ID ${serviceRequestId}, trying fallback search.`);
            }
          }

          // Try MedicationRequest by ID
          if (medicationRequestId && medicationRequestId !== "null") {
            try {
              console.log(`Fetching MedicationRequest by ID: ${medicationRequestId}`);
              return await axios.get(`${Config.medication_request}/${medicationRequestId}`);
            } catch (err) {
              console.warn(`Failed to fetch MedicationRequest by ID ${medicationRequestId}, trying fallback search.`);
            }
          }

          // Fallback: search for the latest ServiceRequest for this patient
          console.log(`Attempting fallback search for ServiceRequest for Patient/${patientId}`);
          try {
            const searchRes = await axios.get(`${Config.service_request}?patient=Patient/${patientId}&_count=1`);
            if (searchRes.data?.entry?.length > 0) {
              console.log("Found ServiceRequest via fallback search:", searchRes.data.entry[0].resource.id);
              return { data: searchRes.data.entry[0].resource };
            }
          } catch (err) {
            console.warn("ServiceRequest search failed, trying MedicationRequest search.");
          }

          // Last resort: search for the latest MedicationRequest for this patient
          console.log(`Attempting fallback search for MedicationRequest for Patient/${patientId}`);
          const medSearchRes = await axios.get(`${Config.medication_request}?patient=Patient/${patientId}&_count=1`);
          if (medSearchRes.data?.entry?.length > 0) {
            console.log("Found MedicationRequest via fallback search:", medSearchRes.data.entry[0].resource.id);
            return { data: medSearchRes.data.entry[0].resource };
          }

          throw new Error("No ServiceRequest or MedicationRequest found for this patient.");
        };

        const [patientRes, requestRes, qrRes, coverageRes, payerRes] = await Promise.all([
          axios.get(`${Config.patient}/${patientId}`),
          fetchRequest(),
          fetchQr(),
          fetchCoverage(),
          axios.get(`${Config.organization}/50`),
        ]);

        // Mock Provider Org if not found
        const providerOrg = {
          resourceType: "Organization",
          id: "456",
          name: "City General Hospital",
          identifier: [{ system: "http://hl7.org/fhir/sid/us-npi", value: "N123456" }]
        };

        if (!requestRes.data) {
          throw new Error("No MedicationRequest or ServiceRequest found for claim submission.");
        }

        setResources({
          patient: patientRes.data,
          request: requestRes.data,
          qr: qrRes.data,
          coverage: coverageRes.data,
          providerOrg: providerOrg,
          payerOrg: payerRes.data,
        });
      } catch (err) {
        console.error("Error fetching resources:", err);
        const errorMessage = err instanceof Error ? err.message : "Failed to fetch necessary claim data.";
        setAlertMessage(errorMessage);
        setAlertSeverity("error");
        setOpenSnackbar(true);
      } finally {
        setLoading(false);
      }
    };

    fetchData();

    dispatch(updateIsProcess(true));
    // Mark previous steps as completed
    ["Medication request", "Check Payer Requirements", "Questionnaire package", "Questionnaire Response"].forEach(step => {
      dispatch(updateSingleStep({ stepName: step, newStatus: StepStatus.COMPLETED }));
    });
  }, [patientId, medicationRequestId, qrId, coverageId, dispatch]);

  const handleSubmit = () => {
    if (!resources) return;

    const parsedAmount = Number(itemAmount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      setAlertMessage("Please enter a valid item amount greater than 0.");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return;
    }

    const Config = window.Config;
    const payload = CREATE_PAS_CLAIM_BUNDLE(
      resources.patient,
      resources.request,
      resources.qr,
      resources.coverage,
      resources.providerOrg,
      resources.payerOrg,
      loggedUser?.id || "456"
    );

    try {
      // Enrich the Claim resource with monetary amounts using user-provided item amount.
      const claimEntry = (payload as any).entry?.find(
        (e: any) => e.resource?.resourceType === "Claim"
      );
      const claimResource = claimEntry?.resource;
      if (claimResource) {
        const currency = "USD";
        const amountValue = parsedAmount;

        claimResource.total = {
          value: amountValue,
          currency,
        };

        if (!claimResource.item || !Array.isArray(claimResource.item)) {
          claimResource.item = [
            {
              sequence: 1,
            },
          ];
        }

        if (!claimResource.item[0]) {
          claimResource.item[0] = {
            sequence: 1,
          };
        }

        claimResource.item[0].unitPrice = {
          value: amountValue,
          currency,
        };

        claimResource.item[0].net = {
          value: amountValue,
          currency,
        };
      }
    } catch (e) {
      console.error("Failed to enrich Claim with monetary amounts", e);
    }

    dispatch(updateActiveStep(4));
    dispatch(
      updateSingleStep({
        stepName: "Claim Submit",
        newStatus: StepStatus.IN_PROGRESS,
      })
    );

    localStorage.setItem(CLAIM_REQUEST_METHOD, HTTP_METHODS.POST);
    localStorage.setItem(CLAIM_REQUEST_URL, Config.demoBaseUrl + Config.claim_submit);
    localStorage.setItem(CLAIM_REQUEST, JSON.stringify(payload));

    axios
      .post(Config.claim_submit, payload, {
        headers: { "Content-Type": "application/fhir+json" },
      })
      .then((response) => {
        if (response.status >= 200 && response.status < 300) {
          console.log("Claim submitted successfully:", response.data);

          const responseBundle = response.data;
          localStorage.setItem(CLAIM_RESPONSE, JSON.stringify(responseBundle));
          dispatch(updateCurrentResponse(responseBundle));
          dispatch(updateCurrentRequest(payload));
          dispatch(updateCurrentRequestUrl(Config.demoBaseUrl + Config.claim_submit));
          dispatch(updateCurrentRequestMethod(HTTP_METHODS.POST));

          let outcome = null;
          let claimId = null;
          if (responseBundle.resourceType === "Bundle" && responseBundle.entry?.length > 0) {
            const claimResp = responseBundle.entry.find((e: any) => e.resource?.resourceType === "ClaimResponse");
            outcome = claimResp?.resource?.outcome;
            const reference = claimResp?.resource?.request?.reference;
            if (reference) {
              claimId = reference.startsWith("Claim/") ? reference.substring(6) : reference;
            }
          }

          if (claimId) {
            const webhookUrl = Config.webhookServerUrl || "http://localhost:9099";
            axios.post(`${webhookUrl}/claim`, {
              id: claimId,
              patientName: `${resources.patient.name?.[0]?.given?.join(" ")} ${resources.patient.name?.[0]?.family}`,
              providerName: resources.providerOrg.name,
              medicationRef: resources.request.medicationCodeableConcept?.text || "Medication",
              date: new Date().toISOString().split("T")[0],
              outcome: outcome,
              status: outcome === 'complete' ? 'active' : 'draft'
            }).catch(err => console.error("Failed to register claim for tracking", err));
          }

          if (outcome === "complete" || outcome === "partial") {
            navigate("/dashboard/prior-auth-list");
          } else {
            setAlertMessage("Claim submission outcome: " + outcome);
            setAlertSeverity("warning");
            setOpenSnackbar(true);
          }
        } else {
          setAlertMessage("Error submitting claim");
          setAlertSeverity("error");
          setOpenSnackbar(true);
        }
        dispatch(updateSingleStep({ stepName: "Claim Submit", newStatus: StepStatus.COMPLETED }));
      })
      .catch((error) => {
        setAlertMessage("Error submitting claim: " + error.message);
        setAlertSeverity("error");
        setOpenSnackbar(true);
      });
  };

  const handleCloseSnackbar = () => setOpenSnackbar(false);

  if (loading) {
    return (
      <Card style={{ marginTop: "30px", padding: "40px", textAlign: "center" }}>
        <CircularProgress />
        <p style={{ marginTop: "20px" }}>Loading claim details...</p>
      </Card>
    );
  }

  if (!resources) {
    return (
      <Card style={{ marginTop: "30px", padding: "20px" }}>
        <Alert severity="error">
          Could not load resources for claim submission.
          <br />
          <strong>Provided IDs:</strong>
          <ul style={{ marginTop: "10px", marginBottom: "0" }}>
            <li>Patient ID: {patientId || "missing"}</li>
            <li>Service Request ID: {serviceRequestId || "will search by patient"}</li>
            <li>Medication Request ID: {medicationRequestId || "will search by patient"}</li>
            <li>Questionnaire Response ID: {qrId || "will search by patient"}</li>
            <li>Coverage ID: {coverageId || "will search by patient"}</li>
          </ul>
          <p style={{ marginTop: "10px" }}>
            Check the browser console for detailed error information.
          </p>
        </Alert>
      </Card>
    );
  }

  return (
    <Card style={{ marginTop: "30px", padding: "20px" }}>
      <Card.Body>
        <Card.Title>PAS Claim Submission Details</Card.Title>
        <Form>
          <div style={{ display: "flex", gap: "20px" }}>
            <Form.Group controlId="patient" style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Patient</Form.Label>
              <Form.Control
                type="text"
                value={`${resources.patient.name?.[0]?.given?.join(" ")} ${resources.patient.name?.[0]?.family} (ID: ${resources.patient.id})`}
                disabled
              />
            </Form.Group>
            <Form.Group controlId="provider" style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Practitioner</Form.Label>
              <Form.Control
                type="text"
                value={loggedUser ? `${loggedUser.first_name} ${loggedUser.last_name}` : "City General Hospital"}
                disabled
              />
            </Form.Group>
            <Form.Group controlId="insurer" style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Insurer</Form.Label>
              <Form.Control
                type="text"
                value={resources.payerOrg.name || "UnitedCare Health Insurance"}
                disabled
              />
            </Form.Group>
          </div>

          <div style={{ display: "flex", gap: "20px" }}>
            <Form.Group controlId="use" style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Claim Use</Form.Label>
              <Form.Control type="text" value="PREAUTHORIZATION" disabled />
            </Form.Group>
            <Form.Group controlId="coverage" style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Coverage ID</Form.Label>
              <Form.Control type="text" value={resources.coverage.id} disabled />
            </Form.Group>
          </div>

          <Form.Group controlId="medication" style={{ marginTop: "20px" }}>
            <Form.Label>Medication / Service Requested</Form.Label>
            <Form.Control
              type="text"
              value={
                resources.request.medicationCodeableConcept?.text ||
                resources.request.code?.text ||
                resources.request.code?.coding?.[0]?.display ||
                resources.request.code?.coding?.[0]?.code ||
                resources.request.category?.[0]?.coding?.[0]?.display ||
                "Unknown Service"
              }
              disabled
            />
          </Form.Group>

          <Form.Group controlId="qr" style={{ marginTop: "20px" }}>
            <Form.Label>Associated Questionnaire Response</Form.Label>
            <Form.Control
              type="text"
              value={`ID: ${resources.qr.id} (Status: ${resources.qr.status})`}
              disabled
            />
          </Form.Group>

          <Form.Group controlId="itemAmount" style={{ marginTop: "20px", maxWidth: "300px" }}>
            <Form.Label>Item Amount (USD)</Form.Label>
            <Form.Control
              type="number"
              min="0"
              step="0.01"
              value={itemAmount}
              onChange={(e) => setItemAmount(e.target.value)}
              placeholder="Enter item amount"
            />
          </Form.Group>

          <Button
            variant="success"
            style={{ marginTop: "30px", width: "200px", float: "right", fontWeight: "bold" }}
            onClick={handleSubmit}
          >
            Submit PAS Claim Bundle
          </Button>
        </Form>
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
  );
};

export default function DrugClaimPage() {
  const { isAuthenticated } = useAuth();

  return isAuthenticated ? (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">Claim Submission</div>
      <PatientInfo />
      <ClaimForm />
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
  ) : (
    <Navigate to="/" replace />
  );
}
