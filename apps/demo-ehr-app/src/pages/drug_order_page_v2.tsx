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
import {
  updateCdsHook,
  updateRequest,
  updateRequestUrl,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { resetCdsResponse, updateCdsResponse } from "../redux/cdsResponseSlice";
import {
  updateMedicationFormData,
  resetMedicationFormData,
} from "../redux/medicationFormDataSlice";

import {
  FREQUENCY_OPTIONS,
  MEDICATION_OPTIONS,
  CHECK_PAYER_REQUIREMENTS_REQUEST_BODY,
  TREATMENT_OPTIONS,
  CREATE_MEDICATION_REQUEST_BODY,
  PATIENT_DETAILS,
} from "../constants/data";
import { CdsCard, CdsResponse } from "../components/interfaces/cdsCard";
import axios from "axios";
import { useAuth } from "../components/AuthProvider";
import { Navigate } from "react-router-dom";
import { Alert, Snackbar } from "@mui/material";

const PrescribeForm = ({
  setCdsCards,
}: {
  setCdsCards: React.Dispatch<React.SetStateAction<CdsCard[]>>;
}) => {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(resetMedicationFormData());
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
        quantity: number;
        frequency: string;
        duration: string;
        startDate: Date;
      };
    }) => state.medicationFormData
  );

  const [patientId] = useState("john-smith");
  const [practionerId] = useState("456");
  const [isSubmited, setIsSubmited] = useState(false);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    dispatch(updateMedicationFormData({ [name]: value }));
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
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());

    const payload = CHECK_PAYER_REQUIREMENTS_REQUEST_BODY(
      patientId,
      practionerId,
      medicationFormData.medication as string,
      medicationFormData.quantity as number
    );
    setCdsCards([]);
    dispatch(updateCdsHook("order-sign"));
    dispatch(updateRequestMethod("POST"));
    dispatch(updateRequestUrl("https://unitedcare.com/cds-services/prescirbe-medication"));
    dispatch(updateRequest(payload));

    const Config = window.Config;

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

        dispatch(updateCdsResponse({ cards: res.data, systemActions: {} }));
        return res.data;
      })
      .catch((err) => {
        setAlertMessage("Error retrieving payer requirements!");
        setAlertSeverity("error");
        setOpenSnackbar(true);
        dispatch(updateCdsResponse({ cards: err, systemActions: {} }));
      });
  };
  const validateForm = () => {
    const requiredFields: (keyof typeof medicationFormData)[] = [
      "treatingSickness",
      "medication",
      "quantity",
      "frequency",
      "duration",
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

  const handleCreateMedicationOrder = () => {
    if (!validateForm()) {
      return;
    }
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());

    const payload = CREATE_MEDICATION_REQUEST_BODY();
    dispatch(updateRequestMethod("POST"));
    dispatch(updateRequestUrl("https://unitedcare.com/fhir/r4/MedicationRequest"));
    dispatch(updateRequest(payload));

    const Config = window.Config;
    axios
      .post<CdsResponse>(Config.medication_request, payload, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then<CdsResponse>((res) => {
        if (res.status >= 200 && res.status < 300) {
          setAlertMessage("Medication order created successfully!");
          setAlertSeverity("success");
        } else {
          setAlertMessage("Error creating medication order!");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);
        dispatch(updateCdsResponse({ cards: res.data, systemActions: {} }));
        setIsSubmited(true);
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

          <Form.Group controlId="formMedication" style={{ marginTop: "20px" }}>
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
              controlId="formQuantity"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>
                Quantity <span style={{ color: "red" }}>*</span>
              </Form.Label>
              <Form.Control
                type="number"
                placeholder="Enter quantity"
                name="quantity"
                onChange={handleInputChange}
                required
              />
            </Form.Group>

            <Form.Group
              controlId="formFrequency"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>
                Frequency <span style={{ color: "red" }}>*</span>
              </Form.Label>
              <Select
                name="frequency"
                options={FREQUENCY_OPTIONS}
                isSearchable
                onChange={handleSelectChange}
                menuPosition={"fixed"}
                required
              />
            </Form.Group>

            <Form.Group
              controlId="formDuration"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>
                Duration<span style={{ color: "red" }}>*</span>
              </Form.Label>
              <Form.Control
                type="number"
                placeholder="Enter duration"
                name="duration"
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
            {isSubmited && (
              <Button
                variant="primary"
                type="submit"
                onClick={handleCheckPayerRequirements}
              >
                Check Payer Requirements
              </Button>
            )}
            <Button
              variant="success"
              // type="submit"
              style={{ marginLeft: "30px", float: "right" }}
              onClick={handleCreateMedicationOrder}
              disabled={isSubmited || !validateForm() ? true : false}
            >
              Create Medication Order
            </Button>
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
  );
};

const PrescribeMedicineCard = ({
  setCdsCards,
}: {
  setCdsCards: React.Dispatch<React.SetStateAction<CdsCard[]>>;
}) => {
  return (
    <div
      style={{
        color: "black",
        marginTop: "20px",
      }}
    >
      <PrescribeForm setCdsCards={setCdsCards} />
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
  return (
    <div>
      <Card style={{ marginTop: "30px", padding: "20px" }}>
        <Card.Body>
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: "10px",
            }}
          >
            <Card.Title>{requirementsResponsCard.summary}</Card.Title>
            <div
              style={{
                padding: "5px 10px",
                backgroundColor: "#ffcccb",
                color: "darkred",
                borderRadius: "30px",
                fontSize: "12px",
              }}
            >
              Critical
            </div>
          </div>
          <Card.Text>
            <p>{requirementsResponsCard.detail}</p>
            <hr />
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: "10px",
              }}
            >
              <Card.Title>Suggestions</Card.Title>
              {requirementsResponsCard.selectionBehavior && (
                <div
                  style={{
                    padding: "5px 10px",
                    backgroundColor: "#FFD580",
                    color: "black",
                    borderRadius: "30px",
                    fontSize: "12px",
                  }}
                >
                  {requirementsResponsCard.selectionBehavior}
                </div>
              )}
            </div>
            <ul>
              {requirementsResponsCard.suggestions &&
                requirementsResponsCard.suggestions.map((suggestion, index) => (
                  <li key={index}>{suggestion.label}</li>
                ))}
            </ul>
            {requirementsResponsCard.links &&
              requirementsResponsCard.links.length > 0 && (
                <>
                  <hr />
                  <Card.Title>Links</Card.Title>
                  {requirementsResponsCard.links.map((link, index) => (
                    <div key={index}>
                      <li>
                        <Card.Link
                          href={`${window.location.origin}${new URL(link.url).pathname}`}
                          target="_blank"
                          style={{ color: "#4635B1" }}
                        >
                          {link.label}
                        </Card.Link>
                      </li>
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

  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  const currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );


  return isAuthenticated ? (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">Order Drugs</div>
      <div style={{ display: "flex", gap: "20px" }}>
        <Form.Group
          controlId="formPatientName"
          style={{ marginTop: "20px", flex: "1 1 100%" }}
        >
          <Form.Label>Patient Name</Form.Label>
          <Form.Control
            type="text"
            value={`${currentPatient?.name[0].given[0]} ${currentPatient?.name[0].family}`}
            disabled
          />
        </Form.Group>
        <Form.Group
          controlId="formPatientID"
          style={{ marginTop: "20px", flex: "1 1 100%" }}
        >
          <Form.Label>Patient ID</Form.Label>
          <Form.Control type="text" value={currentPatient?.id} disabled />
        </Form.Group>
      </div>
      <div>
        <PrescribeMedicineCard setCdsCards={setCdsCards} />
      </div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
          gap: "20px",
        }}
      ></div>
      <PayerRequirementsCard cdsCards={cdsCards} />
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
