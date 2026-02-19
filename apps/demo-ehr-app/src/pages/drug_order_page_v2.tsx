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
import { updateCdsResponse } from "../redux/cdsResponseSlice";
import {
  updateMedicationFormData,
  resetMedicationFormData,
} from "../redux/medicationFormDataSlice";

import {
  MEDICATION_OPTIONS,
  CHECK_PAYER_REQUIREMENTS_REQUEST_BODY,
  TREATMENT_OPTIONS,
  CREATE_MEDICATION_REQUEST_BODY,
  FREQUENCY_UNITS,
} from "../constants/data";
import { CdsCard, CdsResponse } from "../components/interfaces/cdsCard";
import axios from "axios";
import { useAuth } from "../components/AuthProvider";
import { Navigate } from "react-router-dom";
import { Alert, Box, Snackbar, Step, StepLabel, Stepper } from "@mui/material";
import PatientInfo from "../components/PatientInfo";
import {
  CHIP_COLOR_CRITICAL,
  CHIP_COLOR_INFO,
  CHIP_COLOR_WARNING,
} from "../constants/color";
import {
  resetCurrentRequest,
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
  MEDICATION_REQUEST,
  MEDICATION_REQUEST_URL,
  MEDICATION_RESPONSE,
  QUESTIONNAIRE_PACKAGE_REQUEST,
  QUESTIONNAIRE_PACKAGE_REQUEST_METHOD,
  QUESTIONNAIRE_PACKAGE_RESPONSE,
  QUESTIONNAIRE_PACKAGE_URL,
  SELECTED_PATIENT_ID,
  TIMESTAMP,
} from "../constants/localStorageVariables";
import { HTTP_METHODS } from "../constants/enum";

interface Operation {
  name: string;
  isCompleted: boolean;
}

const timeout = (delay: number) => {
  return new Promise((res) => setTimeout(res, delay));
};

const PrescribeForm = ({
  setCdsCards,
}: {
  setCdsCards: React.Dispatch<React.SetStateAction<CdsCard[]>>;
}) => {
  const dispatch = useDispatch();
  const [activeOperation, setActiveOperation] = useState(-1);
  const [operations, setOperations] = useState<Operation[]>([
    { name: "Create medication request", isCompleted: false },
    { name: "Check payer requirements", isCompleted: false },
  ]);

  useEffect(() => {
    dispatch(resetMedicationFormData());
    dispatch(updateIsProcess(true));
  }, [dispatch]);

  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);

  const medicationFormData = useSelector(
    (state: {
      medicationFormData: {
        treatingSickness: string;
        medication: string;
        frequency: number;
        frequencyUnit: string;
        period: number;
        startDate: Date;
      };
    }) => state.medicationFormData
  );

  const patientId = localStorage.getItem(SELECTED_PATIENT_ID) || "";
  const loggedUserStr = localStorage.getItem("loggedUser");
  const loggedUser = loggedUserStr ? JSON.parse(loggedUserStr) : null;

  console.log("loggedUser", loggedUser);
  const [practionerId] = useState("456");
  const [isSubmited, setIsSubmited] = useState(false);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    dispatch(
      updateMedicationFormData({
        [name]:
          name === "frequency" || name === "period" ? Number(value) : value,
      })
    );
  };

  const handleSelectChange = (
    selectedOption: SingleValue<{ value: string | null }>,
    actionMeta: ActionMeta<{ value: string | null }>
  ) => {
    dispatch(
      updateMedicationFormData({
        [actionMeta.name as string]: selectedOption
          ? selectedOption.value
          : null,
      })
    );
  };

  const handleDateSelectChange = (date: Date | null) => {
    dispatch(updateMedicationFormData({ startDate: date as Date | null }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
  };

  const handleCheckPayerRequirements = () => {
    dispatch(updateActiveStep(1));
    setActiveOperation(1);
    dispatch(
      updateSingleStep({
        stepName: "Check Payer Requirements",
        newStatus: StepStatus.IN_PROGRESS,
      })
    );

    const payload = CHECK_PAYER_REQUIREMENTS_REQUEST_BODY(
      patientId,
      practionerId
    );
    const Config = window.Config;

    setCdsCards([]);
    localStorage.setItem(CDS_HOOK, "order-sign");
    localStorage.setItem(CDS_REQUEST_METHOD, HTTP_METHODS.POST);
    localStorage.setItem(
      CDS_REQUEST_URL,
      Config.demoBaseUrl + Config.prescribe_medication
    );
    localStorage.setItem(CDS_REQUEST, JSON.stringify(payload));

    axios
      .post<CdsResponse>(Config.prescribe_medication, payload)
      .then<CdsResponse>((res) => {
        if (res.status >= 200 && res.status < 300) {
          setAlertMessage("Payer requirements retrieved successfully!");
          setAlertSeverity("success");
        } else {
          setAlertMessage("Error retrieving payer requirements!");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);

        setCdsCards(res.data.cards);

        localStorage.setItem(
          CDS_RESPONSE,
          JSON.stringify({ cards: res.data, systemActions: {} })
        );
        setOperations((prev) =>
          prev.map((op) => {
            if (op.name === "Check payer requirements") {
              return {
                name: op.name,
                isCompleted: true,
              };
            }
            return op;
          })
        );
        setIsSubmited(true);
        dispatch(
          updateSingleStep({
            stepName: "Check Payer Requirements",
            newStatus: StepStatus.COMPLETED,
          })
        );
        return res.data;
      })
      .catch((err) => {
        setAlertMessage("Error retrieving payer requirements!");
        setAlertSeverity("error");
        setOpenSnackbar(true);
        localStorage.setItem(
          CDS_RESPONSE,
          JSON.stringify({ cards: err, systemActions: {} })
        );
      });
  };

  const validateFormRequiredFields = () => {
    const requiredFields: (keyof typeof medicationFormData)[] = [
      "treatingSickness",
      "medication",
      "frequency",
      "frequencyUnit",
      "period",
      "startDate",
    ];
    let isValid = true;
    requiredFields.forEach((field) => {
      if (!medicationFormData[field]) {
        isValid = false;
      }
    });
    return isValid;
  };

  const validateForm = () => {
    if (!validateFormRequiredFields()) {
      setAlertMessage("Please fill all required fields");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return false;
    }

    if (medicationFormData.frequency <= 0) {
      setAlertMessage("Frequency must be greater than 0");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return false;
    }
    if (medicationFormData.period <= 0) {
      setAlertMessage("Period must be greater than 0");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return false;
    }
    return true;
  };

  const handleCreateMedicationOrder = () => {
    if (!validateForm()) {
      return;
    }
    dispatch(updateActiveStep(0));
    dispatch(
      updateSingleStep({
        stepName: "Medication request",
        newStatus: StepStatus.IN_PROGRESS,
      })
    );

    setActiveOperation(0);
    dispatch(resetCurrentRequest());
    console.log("medicationFormData", medicationFormData);

    const payload = CREATE_MEDICATION_REQUEST_BODY(
      patientId,
      practionerId,
      medicationFormData.medication,
      medicationFormData.frequency,
      medicationFormData.frequencyUnit,
      medicationFormData.period,
      medicationFormData.startDate.toISOString().split("T")[0]
    );
    const Config = window.Config;

    localStorage.setItem(MEDICATION_REQUEST, HTTP_METHODS.POST);
    localStorage.setItem(
      MEDICATION_REQUEST_URL,
      Config.demoHospitalUrl + Config.medication_request
    );
    localStorage.setItem(MEDICATION_REQUEST, JSON.stringify(payload));

    dispatch(updateIsProcess(true));
    dispatch(updateCurrentRequestMethod(HTTP_METHODS.POST));
    dispatch(
      updateCurrentRequestUrl(
        Config.demoHospitalUrl + Config.medication_request
      )
    );
    dispatch(updateCurrentRequest(payload));

    axios
      .post<CdsResponse>(Config.medication_request, payload, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then<CdsResponse>(async (res) => {
        if (res.status >= 200 && res.status < 300) {
          setAlertMessage("Medication order created successfully!");
          setAlertSeverity("success");
        } else {
          setAlertMessage("Error creating medication order!");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);
        localStorage.setItem(MEDICATION_RESPONSE, JSON.stringify(res.data));
        dispatch(updateCurrentResponse(res.data));
        setOperations((prev) =>
          prev.map((op) => {
            if (op.name === "Create medication request") {
              return {
                name: op.name,
                isCompleted: true,
              };
            }
            return op;
          })
        );
        await timeout(3000);
        dispatch(
          updateSingleStep({
            stepName: "Medication request",
            newStatus: StepStatus.COMPLETED,
          })
        );
        handleCheckPayerRequirements();
        return res.data;
      })
      .catch((err) => {
        setAlertMessage("Error creating medication order!");
        setAlertSeverity("error");
        setOpenSnackbar(true);
        dispatch(updateCdsResponse({ cards: err, systemActions: {} }));
      });
  };

  const handleCloseSnackbar = () => {
    setOpenSnackbar(false);
  };

  return (
    <div
      style={{
        color: "black",
        marginTop: "20px",
      }}
    >
      <Card style={{ marginTop: "30px", padding: "20px" }}>
        <Card.Body>
          <Card.Title>Prescribe Medicine</Card.Title>
          <Form onSubmit={handleSubmit}>
            <Form.Group
              controlId="formTreatingSickness"
              style={{ marginTop: "20px" }}
            >
              <Form.Label>
                Treating <span style={{ color: "red" }}>*</span>
              </Form.Label>
              <Select
                name="treatingSickness"
                options={TREATMENT_OPTIONS}
                isSearchable
                onChange={handleSelectChange}
                required
              />
            </Form.Group>

            <Form.Group
              controlId="formMedication"
              style={{ marginTop: "20px", flex: "1 1 40%" }}
            >
              <Form.Label>
                Medication <span style={{ color: "red" }}>*</span>
              </Form.Label>
              <Select
                name="medication"
                options={MEDICATION_OPTIONS}
                isSearchable
                onChange={handleSelectChange}
                menuPosition="fixed"
                required
              />
            </Form.Group>
            <div
              style={{
                display: "flex",
                gap: "20px",
              }}
            >
              <Form.Group
                controlId="formFrequency"
                style={{ marginTop: "20px", flex: "1 1 100%" }}
              >
                <Form.Label>
                  Frequency <span style={{ color: "red" }}>*</span>
                </Form.Label>
                <Form.Control
                  type="number"
                  placeholder="Enter frequency"
                  name="frequency"
                  onChange={handleInputChange}
                  required
                />
              </Form.Group>
              <Form.Group
                controlId="formFrequency"
                style={{ marginTop: "20px", flex: "1 1 100%" }}
              >
                <Form.Label>
                  Frequency Unit <span style={{ color: "red" }}>*</span>
                </Form.Label>
                <Select
                  name="frequencyUnit"
                  options={FREQUENCY_UNITS}
                  isSearchable
                  onChange={handleSelectChange}
                  menuPosition={"fixed"}
                  required
                />
              </Form.Group>

              <Form.Group
                controlId="formPeriod"
                style={{ marginTop: "20px", flex: "1 1 100%" }}
              >
                <Form.Label>
                  Period<span style={{ color: "red" }}>*</span>
                </Form.Label>
                <Form.Control
                  type="number"
                  placeholder="Enter period"
                  name="period"
                  onChange={handleInputChange}
                  required
                />
              </Form.Group>

              <Form.Group
                controlId="formStartDate"
                style={{ marginTop: "20px", flex: "1 1 100%", width: "100%" }}
              >
                <Form.Label>Starting Date</Form.Label>
                <br />
                <DatePicker
                  selected={
                    medicationFormData.startDate instanceof Date
                      ? medicationFormData.startDate
                      : null
                  }
                  onChange={handleDateSelectChange}
                  dateFormat="yyyy/MM/dd"
                  className="form-control"
                  wrapperClassName="date-picker-full-width"
                />
              </Form.Group>
            </div>
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
                  {operations.map((operation) => (
                    <Step
                      key={operation.name}
                      completed={operation.isCompleted}
                    >
                      <StepLabel>{operation.name}</StepLabel>
                    </Step>
                  ))}
                </Stepper>
                <Button
                  variant="success"
                  style={{ marginLeft: "30px", float: "right" }}
                  onClick={handleCreateMedicationOrder}
                  disabled={isSubmited || !validateFormRequiredFields()}
                >
                  Create Medication Order
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

const PayerRequirementsCard = ({ cdsCards }: { cdsCards: CdsCard[] }) => {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
        gap: "20px",
        maxWidth: "400px",
      }}
    >
      {cdsCards.map((card, index) => (
        <RequirementCard key={index} requirementsResponsCard={card} />
      ))}
    </div>
  );
};

const RequirementCard = ({
  requirementsResponsCard,
}: {
  requirementsResponsCard: CdsCard;
}) => {
  const dispatch = useDispatch();

  const requestBody = {
    resourceType: "Parameters",
    id: "questionnaire-package-request",
    parameter: [
      {
        name: "coverage",
        resource: {
          resourceType: "Coverage",
          reference: "Coverage/367",
        },
      },
      {
        name: "order",
        resource: {
          resourceType: "MedicationRequest",
          reference: "MedicationRequest/111112",
        },
      },
    ],
  };
  const Config = window.Config;

  const loadQuestionnaires = () => {
    localStorage.setItem(TIMESTAMP, new Date().toISOString());
    dispatch(updateActiveStep(2));
    dispatch(
      updateSingleStep({
        stepName: "Questionnaire package",
        newStatus: StepStatus.IN_PROGRESS,
      })
    );

    localStorage.setItem(
      QUESTIONNAIRE_PACKAGE_REQUEST_METHOD,
      HTTP_METHODS.POST
    );
    localStorage.setItem(
      QUESTIONNAIRE_PACKAGE_URL,
      Config.demoBaseUrl + Config.questionnaire_package
    );

    localStorage.setItem(
      QUESTIONNAIRE_PACKAGE_REQUEST,
      JSON.stringify(requestBody)
    );
    axios
      .post(Config.questionnaire_package, requestBody, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then(async (response) => {
        if (response.status >= 200 && response.status < 300) {
          console.log("Questionnaire fetched successfully!");
        } else {
          console.log("Failed to fetch questionnaire!");
        }

        const questionnaire = response.data;
        localStorage.setItem(
          QUESTIONNAIRE_PACKAGE_RESPONSE,
          JSON.stringify(questionnaire)
        );
        dispatch(
          updateSingleStep({
            stepName: "Questionnaire package",
            newStatus: StepStatus.COMPLETED,
          })
        );
        await timeout(2000);
        dispatch(updateActiveStep(3));
        dispatch(
          updateSingleStep({
            stepName: "Questionnaire Response",
            newStatus: StepStatus.IN_PROGRESS,
          })
        );
        await timeout(5000);
        dispatch(
          updateSingleStep({
            stepName: "Questionnaire Response",
            newStatus: StepStatus.COMPLETED,
          })
        );
      })
      .catch((error) => {
        console.error("Error fetching questionnaire:", error);
      });
  };

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
            <h4 style={{ marginBottom: "20px" }}>
              {requirementsResponsCard.summary}
            </h4>
            <div
              style={{
                padding: "5px 10px",
                marginTop: "10px",
                backgroundColor:
                  requirementsResponsCard.indicator === "warning"
                    ? CHIP_COLOR_WARNING
                    : requirementsResponsCard.indicator === "critical"
                      ? CHIP_COLOR_CRITICAL
                      : CHIP_COLOR_INFO,
                color: "black",
                borderRadius: "30px",
                fontSize: "12px",
                textAlign: "center",
                fontWeight: "bold",
                width: "100px",
              }}
            >
              {requirementsResponsCard.indicator}
            </div>
          </div>
          <br />
          <Card.Text>
            <p style={{ textAlign: "justify" }}>
              {requirementsResponsCard.detail}
            </p>

            <div
              style={{
                marginBottom: "10px",
                marginTop: "30px",
              }}
            >
              <h5>Suggestions</h5>
              <ul>
                {requirementsResponsCard.suggestions &&
                  requirementsResponsCard.suggestions.map(
                    (suggestion, index) => {
                      // Check for Task resource in suggestion actions
                      const taskAction = suggestion.actions?.find(
                        (action) =>
                          (action.resource as any)?.resourceType === "Task"
                      );

                      if (taskAction) {
                        const task = taskAction.resource as any;
                        const questionnaireUrl = task.input?.find(
                          (i: any) => i.type?.text === "questionnaire"
                        )?.valueCanonical;
                        const medicationRequestId = task.basedOn?.[0]?.reference?.split(
                          "/"
                        )[1];
                        const patientId = localStorage.getItem(
                          SELECTED_PATIENT_ID
                        );
                        const dtrUrl = `${window.Config.dtrAppUrl}?questionnaire=${questionnaireUrl}&medicationRequestId=${medicationRequestId}&patientId=${patientId}`;

                        return (
                          <div key={index} style={{ marginBottom: "10px" }}>
                            <li>{suggestion.label}</li>
                            <Button
                              variant="primary"
                              size="sm"
                              style={{ marginTop: "5px" }}
                              onClick={() => {
                                window.open(
                                  dtrUrl,
                                  "_blank",
                                  "noopener,noreferrer"
                                );
                              }}
                            >
                              Launch DTR
                            </Button>
                          </div>
                        );
                      }

                      return <li key={index}>{suggestion.label}</li>;
                    }
                  )}
              </ul>
            </div>
            {requirementsResponsCard.links &&
              requirementsResponsCard.links.length > 0 && (
                <>
                  <br />
                  {requirementsResponsCard.links.map((link, index) => (
                    <div
                      key={index}
                      style={{
                        display: "flex",
                        justifyContent: "center",
                      }}
                    >
                      <Button
                        variant="secondary"
                        onClick={() => {
                          console.log(link.url);
                          loadQuestionnaires();
                          window.open(
                            link.url,
                            "_blank",
                            "noopener,noreferrer"
                          );
                        }}
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

export default function DrugOrderPageV2() {
  const { isAuthenticated } = useAuth();
  const [cdsCards, setCdsCards] = useState<CdsCard[]>([]);

  return isAuthenticated ? (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">Order Drugs</div>
      <PatientInfo />
      <PrescribeForm setCdsCards={setCdsCards} />
      <PayerRequirementsCard cdsCards={cdsCards} />
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}
