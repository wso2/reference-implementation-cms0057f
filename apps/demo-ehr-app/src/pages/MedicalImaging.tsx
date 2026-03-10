// Copyright (c) 2024 - 2025, WSO2 LLC. (http://www.wso2.com).
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

import React, { useState, useEffect } from "react";
import "../assets/styles/main.css";
import "bootstrap/dist/css/bootstrap.min.css";
import "react-datepicker/dist/react-datepicker.css";
import Form from "react-bootstrap/Form";
import Button from "react-bootstrap/Button";
import Select, { ActionMeta, SingleValue } from "react-select";
import Card from "react-bootstrap/Card";
import DatePicker from "react-datepicker";
import { useDispatch, useSelector } from "react-redux";
import { CdsCard, CdsResponse } from "../components/interfaces/cdsCard";
import axios from "axios";
import { useAuth } from "../components/AuthProvider";
import { Navigate, useNavigate } from "react-router-dom";
import { Alert, Box, Snackbar, Step, StepLabel, Stepper } from "@mui/material";
import PatientInfo from "../components/PatientInfo";
import {
  CHIP_COLOR_CRITICAL,
  CHIP_COLOR_INFO,
  CHIP_COLOR_WARNING,
} from "../constants/color";
import {
  appendRequestLog,
  clearRequestLogs,
  updateCurrentRequest,
  updateCurrentRequestMethod,
  updateCurrentRequestUrl,
  updateCurrentResponse,
  updateIsProcess,
} from "../redux/currentStateSlice";
import {
  StepStatus,
  updateActiveStep,
  updateSingleStep,
} from "../redux/commonStoargeSlice";
import {
  CDS_HOOK,
  CDS_REQUEST,
  CDS_REQUEST_METHOD,
  CDS_REQUEST_URL,
  CDS_RESPONSE,
  SELECTED_PATIENT_ID,
  MEDICATION_REQUEST,
  MEDICATION_REQUEST_METHOD,
  MEDICATION_REQUEST_URL,
  MEDICATION_RESPONSE,
} from "../constants/localStorageVariables";
import { HTTP_METHODS } from "../constants/enum";
import { selectPatient } from "../redux/patientSlice";
import { updateStepsArray } from "../redux/commonStoargeSlice";

// ── Imaging Type options (CPT codes for MRI Spine) ──────────────────────────
const IMAGING_TYPE_OPTIONS = [
  {
    value: "72148",
    label: "MRI Spine w/o Contrast (CPT 72148)",
    display: "MRI lumbar spine w/o contrast",
  },
  {
    value: "72149",
    label: "MRI Spine w/ Contrast (CPT 72149)",
    display: "MRI lumbar spine w/ contrast",
  },
  {
    value: "72158",
    label: "MRI Spine w/ & w/o Contrast (CPT 72158)",
    display: "MRI lumbar spine w/ and w/o contrast",
  },
];

const BODY_AREA_OPTIONS = [
  { value: "lumbar", label: "Lumbar" },
  { value: "cervical", label: "Cervical" },
  { value: "thoracic", label: "Thoracic" },
];

interface Operation {
  name: string;
  isCompleted: boolean;
}

// ── ImagingOrderForm ─────────────────────────────────────────────────────────
const ImagingOrderForm = ({
  setCdsCards,
  setServiceRequestId,
  serviceRequestId,
}: {
  setCdsCards: React.Dispatch<React.SetStateAction<CdsCard[]>>;
  setServiceRequestId: React.Dispatch<React.SetStateAction<string | null>>;
  serviceRequestId: string | null;
}) => {
  const dispatch = useDispatch();

  const [activeOperation, setActiveOperation] = useState(-1);
  const [operations] = useState<Operation[]>([
    { name: "Create imaging order", isCompleted: false },
    { name: "Check payer requirements", isCompleted: false },
  ]);

  const [imagingType, setImagingType] = useState<string>("");
  const [imagingDisplay, setImagingDisplay] = useState<string>("");
  const [bodyArea, setBodyArea] = useState<string>("");
  const [diagnosis, setDiagnosis] = useState<string>("");
  const [requestedDate, setRequestedDate] = useState<Date | null>(null);
  const [isSubmitted, setIsSubmitted] = useState(false);

  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);

  const savedPatientId = localStorage.getItem(SELECTED_PATIENT_ID);
  if (savedPatientId) {
    dispatch(selectPatient(savedPatientId));
  }
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  ) || savedPatientId || "101";

  useEffect(() => {
    dispatch(updateIsProcess(true));
    dispatch(
      updateStepsArray([
        { name: "Service request", status: StepStatus.NOT_STARTED },
        { name: "Check Payer Requirements", status: StepStatus.NOT_STARTED },
        { name: "Questionnaire package", status: StepStatus.NOT_STARTED },
        { name: "Questionnaire Response", status: StepStatus.NOT_STARTED },
        { name: "Claim Submit", status: StepStatus.NOT_STARTED },
      ])
    );
  }, [dispatch]);

  const isFormValid = () =>
    !!imagingType && !!bodyArea && !!diagnosis && !!requestedDate;

  // Build the ServiceRequest resource
  const buildServiceRequestResource = () => {
    return {
      resourceType: "ServiceRequest",
      id: `sr-${Math.floor(Math.random() * 1000).toString().padStart(3, "0")}`,
      status: "draft",
      intent: "order",
      subject: { reference: `Patient/${selectedPatientId}` },
      code: {
        coding: [
          {
            system: "http://www.ama-assn.org/go/cpt",
            code: imagingType,
            display: imagingDisplay,
          },
        ],
      },
      reasonCode: diagnosis ? [{ text: diagnosis }] : undefined,
      occurrenceDateTime: requestedDate
        ? requestedDate.toISOString().split("T")[0]
        : undefined,
      bodySite: bodyArea ? [{ text: bodyArea }] : undefined,
    };
  };

  // Build the CDS Hook request payload
  const buildCdsPayload = (srResource: any) => {
    const Config = window.Config;
    return {
      hookInstance: crypto.randomUUID(),
      hook: "order-sign",
      fhirServer: Config.fhirServerUrl,
      context: {
        userId: "Practitioner/456",
        patientId: selectedPatientId,
        draftOrders: {
          resourceType: "Bundle",
          type: "collection",
          entry: [
            {
              resource: srResource,
            },
            {
              resource: {
                resourceType: "Patient",
                id: selectedPatientId,
              },
            },
          ],
        },
      },
    };
  };

  const handleCheckPayerRequirements = async () => {
    if (!isFormValid()) {
      setAlertMessage("Please fill all required fields");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return;
    }

    const Config = window.Config;
    dispatch(clearRequestLogs());
    let currentServiceRequestId = serviceRequestId;

    // Step 1: Create Imaging Order if not already created
    if (!currentServiceRequestId) {
      dispatch(updateActiveStep(0));
      setActiveOperation(0);
      dispatch(
        updateSingleStep({
          stepName: "Service request",
          newStatus: StepStatus.IN_PROGRESS,
        })
      );

      const srResource = buildServiceRequestResource();
      dispatch(updateCurrentRequestMethod(HTTP_METHODS.POST));
      dispatch(updateCurrentRequestUrl(Config.baseUrl + Config.service_request));
      dispatch(updateCurrentRequest(srResource));

      localStorage.setItem(MEDICATION_REQUEST_METHOD, HTTP_METHODS.POST);
      localStorage.setItem(MEDICATION_REQUEST_URL, Config.baseUrl + Config.service_request);
      localStorage.setItem(MEDICATION_REQUEST, JSON.stringify(srResource));

      try {
        const res = await axios.post(Config.service_request, srResource, {
          headers: {
            "Content-Type": "application/fhir+json",
          },
        });
        if (res.status >= 200 && res.status < 300) {
          const createdSr = res.data;
          dispatch(
            appendRequestLog({
              method: HTTP_METHODS.POST,
              url: Config.baseUrl + Config.service_request,
              request: srResource,
              response: createdSr,
            })
          );
          currentServiceRequestId = createdSr.id;
          setServiceRequestId(createdSr.id);
          operations[0].isCompleted = true;

          localStorage.setItem(MEDICATION_RESPONSE, JSON.stringify(createdSr));

          dispatch(
            updateSingleStep({
              stepName: "Service request",
              newStatus: StepStatus.COMPLETED,
            })
          );
        } else {
          setAlertMessage("Error creating imaging order!");
          setAlertSeverity("error");
          setOpenSnackbar(true);
          return;
        }
      } catch (err) {
        console.error("Error creating imaging order", err);
        setAlertMessage("Error creating imaging order!");
        setAlertSeverity("error");
        setOpenSnackbar(true);
        return;
      }
    }

    // Step 2: Check Payer Requirements
    dispatch(updateActiveStep(1));
    setActiveOperation(1);
    dispatch(
      updateSingleStep({
        stepName: "Check Payer Requirements",
        newStatus: StepStatus.IN_PROGRESS,
      })
    );

    const srResourceForCds = buildServiceRequestResource();
    srResourceForCds.id = currentServiceRequestId!;
    const payload = buildCdsPayload(srResourceForCds);

    setCdsCards([]);
    localStorage.setItem(CDS_HOOK, "order-sign");
    localStorage.setItem(CDS_REQUEST_METHOD, HTTP_METHODS.POST);
    localStorage.setItem(
      CDS_REQUEST_URL,
      Config.demoBaseUrl + Config.crd_mri_spine
    );
    localStorage.setItem(CDS_REQUEST, JSON.stringify(payload));

    dispatch(updateCurrentRequestMethod(HTTP_METHODS.POST));
    dispatch(
      updateCurrentRequestUrl(Config.demoBaseUrl + Config.crd_mri_spine)
    );
    dispatch(updateCurrentRequest(payload));

    try {
      const res = await axios.post<CdsResponse>(Config.crd_mri_spine, payload, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      });
      if (res.status >= 200 && res.status < 300) {
        setAlertMessage("Payer requirements retrieved successfully!");
        setAlertSeverity("success");
      } else {
        setAlertMessage("Error retrieving payer requirements!");
        setAlertSeverity("error");
      }
      setOpenSnackbar(true);

      setCdsCards(res.data.cards);
      dispatch(
        appendRequestLog({
          method: HTTP_METHODS.POST,
          url: Config.demoBaseUrl + Config.crd_mri_spine,
          request: payload,
          response: res.data,
        })
      );
      localStorage.setItem(
        CDS_RESPONSE,
        JSON.stringify({ cards: res.data.cards, systemActions: {} })
      );
      dispatch(updateCurrentResponse(res.data));
      setIsSubmitted(true);

      dispatch(
        updateSingleStep({
          stepName: "Check Payer Requirements",
          newStatus: StepStatus.COMPLETED,
        })
      );
    } catch (err) {
      console.error("Error retrieving payer requirements", err);
      setAlertMessage("Error retrieving payer requirements!");
      setAlertSeverity("error");
      setOpenSnackbar(true);
    }
  };

  const handleCloseSnackbar = () => setOpenSnackbar(false);

  return (
    <div style={{ color: "black", marginTop: "20px" }}>
      <Card style={{ marginTop: "30px", padding: "20px" }}>
        <Card.Body>
          <Card.Title>Medical Imaging Order</Card.Title>
          <Form>
            {/* Row 1: Imaging Type + Body Area */}
            <div style={{ display: "flex", gap: "20px" }}>
              <Form.Group
                controlId="imagingType"
                style={{ marginTop: "20px", flex: "1 1 100%" }}
              >
                <Form.Label>
                  Imaging Type <span style={{ color: "red" }}>*</span>
                </Form.Label>
                <Select
                  name="imagingType"
                  options={IMAGING_TYPE_OPTIONS}
                  isSearchable
                  menuPosition="fixed"
                  placeholder="Select imaging type..."
                  onChange={(
                    opt: SingleValue<{ value: string; label: string; display: string }>,
                    _meta: ActionMeta<{ value: string; label: string; display: string }>
                  ) => {
                    setImagingType(opt?.value ?? "");
                    setImagingDisplay(opt?.display ?? "");
                    setIsSubmitted(false);
                    setCdsCards([]);
                  }}
                />
              </Form.Group>

              <Form.Group
                controlId="bodyArea"
                style={{ marginTop: "20px", flex: "1 1 100%" }}
              >
                <Form.Label>
                  Body Area <span style={{ color: "red" }}>*</span>
                </Form.Label>
                <Select
                  name="bodyArea"
                  options={BODY_AREA_OPTIONS}
                  isSearchable
                  menuPosition="fixed"
                  placeholder="Select body area..."
                  onChange={(
                    opt: SingleValue<{ value: string; label: string }>,
                    _meta: ActionMeta<{ value: string; label: string }>
                  ) => {
                    setBodyArea(opt?.value ?? "");
                    setIsSubmitted(false);
                    setCdsCards([]);
                  }}
                />
              </Form.Group>
            </div>

            {/* Row 2: Diagnosis + Requested Date */}
            <div style={{ display: "flex", gap: "20px" }}>
              <Form.Group
                controlId="diagnosis"
                style={{ marginTop: "20px", flex: "2 1 100%" }}
              >
                <Form.Label>
                  Diagnosis / Clinical Indication{" "}
                  <span style={{ color: "red" }}>*</span>
                </Form.Label>
                <Form.Control
                  type="text"
                  placeholder="e.g. Lower back pain with radiculopathy"
                  value={diagnosis}
                  onChange={(e) => {
                    setDiagnosis(e.target.value);
                    setIsSubmitted(false);
                    setCdsCards([]);
                  }}
                />
              </Form.Group>

              <Form.Group
                controlId="requestedDate"
                style={{ marginTop: "20px", flex: "1 1 100%", width: "100%" }}
              >
                <Form.Label>
                  Requested Date <span style={{ color: "red" }}>*</span>
                </Form.Label>
                <br />
                <DatePicker
                  selected={requestedDate}
                  onChange={(date: Date | null) => {
                    setRequestedDate(date);
                    setIsSubmitted(false);
                    setCdsCards([]);
                  }}
                  dateFormat="yyyy/MM/dd"
                  minDate={new Date()}
                  className="form-control"
                  wrapperClassName="date-picker-full-width"
                  placeholderText="Select date"
                />
              </Form.Group>
            </div>

            {/* Submit row */}
            <div style={{ marginTop: "30px", float: "right" }}>
              <Box
                sx={{ width: "100%" }}
                display="flex"
                flexDirection="row"
                alignItems="center"
                justifyContent="space-between"
                gap={2}
              >
                <Stepper
                  activeStep={activeOperation}
                  alternativeLabel
                  sx={{ marginTop: 6 }}
                >
                  {operations.map((op) => (
                    <Step key={op.name} completed={op.isCompleted}>
                      <StepLabel>{op.name}</StepLabel>
                    </Step>
                  ))}
                </Stepper>
                <Button
                  variant="success"
                  style={{ marginLeft: "30px", float: "right" }}
                  onClick={handleCheckPayerRequirements}
                  disabled={isSubmitted || !isFormValid()}
                >
                  Check Payer Requirements
                </Button>
              </Box>
            </div>
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
    </div>
  );
};

// ── PayerRequirementsCard ────────────────────────────────────────────────────
const PayerRequirementsCard = ({
  cdsCards,
  serviceRequestId
}: {
  cdsCards: CdsCard[],
  serviceRequestId: string | null
}) => {

  if (cdsCards.length === 0) return null;

  return (
    <div style={{ marginTop: "40px" }}>
      <h4>Payer Requirements</h4>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
          gap: "20px",
          maxWidth: "800px",
        }}
      >
        {cdsCards.map((card, index) => (
          <RequirementCard key={index} card={card} serviceRequestId={serviceRequestId} />
        ))}
      </div>

    </div>
  );
};

// ── RequirementCard ──────────────────────────────────────────────────────────
const RequirementCard = ({ card, serviceRequestId }: { card: CdsCard, serviceRequestId: string | null }) => {
  const patientId = localStorage.getItem(SELECTED_PATIENT_ID);
  const navigate = useNavigate();

  const indicatorColor =
    card.indicator === "warning"
      ? CHIP_COLOR_WARNING
      : card.indicator === "critical"
        ? CHIP_COLOR_CRITICAL
        : CHIP_COLOR_INFO;

  return (
    <div>
      <Card
        style={{
          marginTop: "30px",
          paddingLeft: "20px",
          paddingRight: "20px",
          paddingTop: "20px",
        }}
      >
        <Card.Body>
          <div>
            <h4 style={{ marginBottom: "20px" }}>{card.summary}</h4>
            <div
              style={{
                padding: "5px 10px",
                marginTop: "10px",
                backgroundColor: indicatorColor,
                color: "black",
                borderRadius: "30px",
                fontSize: "12px",
                textAlign: "center",
                fontWeight: "bold",
                width: "100px",
              }}
            >
              {card.indicator}
            </div>
          </div>
          <br />
          <Card.Text>
            <p style={{ textAlign: "justify" }}>{card.detail}</p>

            {card.suggestions && card.suggestions.length > 0 && (
              <div style={{ marginBottom: "10px", marginTop: "30px" }}>
                <h5>Suggestions</h5>
                <ul>
                  {card.suggestions.map((suggestion, idx) => {
                    // Look for a Task resource in suggestion actions
                    const taskAction = suggestion.actions?.find(
                      (action) =>
                        (action.resource as any)?.resourceType === "Task"
                    );

                    if (taskAction) {
                      const task = taskAction.resource as any;
                      const questionnaireUrl = task.input?.find(
                        (i: any) => i.type?.text === "questionnaire"
                      )?.valueCanonical;
                      const taskServiceRequestId =
                        task.basedOn?.[0]?.reference?.split("/")[1];
                      // Use the serviceRequestId from the task, or fall back to our locally created one
                      const srId = taskServiceRequestId || serviceRequestId;

                      console.log("DTR Launch - ServiceRequestId:", srId, "Patient:", patientId);

                      const dtrUrl = [
                        window.Config.dtrAppUrl,
                        `?questionnaire=${encodeURIComponent(questionnaireUrl ?? "")}`,
                        `&serviceRequestId=${srId ?? ""}`,
                        `&patientId=${patientId ?? ""}`,
                      ].join("");

                      return (
                        <div key={idx} style={{ marginBottom: "15px" }}>
                          <li>{suggestion.label}</li>
                          <div style={{ marginTop: "15px" }}>
                            <Button
                              variant="primary"
                              style={{
                                width: "100%",
                                fontWeight: "600",
                                padding: "10px 0",
                              }}
                              onClick={() => {
                                navigate(`/dashboard/dtr-launch?dtrUrl=${encodeURIComponent(dtrUrl)}`);
                              }}
                            >
                              Launch DTR
                            </Button>
                          </div>
                        </div>
                      );
                    }

                    return <li key={idx}>{suggestion.label}</li>;
                  })}
                </ul>
              </div>
            )}

            {/* Fallback: render plain links if present */}
            {card.links && card.links.length > 0 && (
              <>
                <br />
                {card.links.map((link, idx) => (
                  <div
                    key={idx}
                    style={{ display: "flex", justifyContent: "center" }}
                  >
                    <Button
                      variant="secondary"
                      onClick={() =>
                        window.open(link.url, "_blank", "noopener,noreferrer")
                      }
                    >
                      {link.label}
                    </Button>
                  </div>
                ))}
              </>
            )}
          </Card.Text>
        </Card.Body>
      </Card>
    </div>
  );
};

// ── Page root ────────────────────────────────────────────────────────────────
export default function MedicalImagingPage() {
  const { isAuthenticated } = useAuth();
  const [cdsCards, setCdsCards] = useState<CdsCard[]>([]);
  const [serviceRequestId, setServiceRequestId] = useState<string | null>(null);

  return isAuthenticated ? (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">Schedule Medical Imaging</div>
      <PatientInfo />
      <ImagingOrderForm
        setCdsCards={setCdsCards}
        setServiceRequestId={setServiceRequestId}
        serviceRequestId={serviceRequestId}
      />
      <PayerRequirementsCard cdsCards={cdsCards} serviceRequestId={serviceRequestId} />
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}
