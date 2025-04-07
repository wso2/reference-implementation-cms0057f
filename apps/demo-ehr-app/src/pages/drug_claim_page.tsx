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

import React, { useEffect, useState } from "react";
import axios from "axios";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import { useDispatch, useSelector } from "react-redux";
import { CLAIM_REQUEST_BODY, PATIENT_DETAILS } from "../constants/data";
import { useAuth } from "../components/AuthProvider";
import { Navigate } from "react-router-dom";
import { Alert, Snackbar } from "@mui/material";
import { selectPatient } from "../redux/patientSlice";
import Lottie from "react-lottie";
import successAnimation from "../animations/success-animation.json"; // Add your animation JSON file here
import { updateIsProcess } from "../redux/currentStateSlice";
import {
  StepStatus,
  updateActiveStep,
  updateSingleStep,
} from "../redux/commonStoargeSlice";
import PatientInfo from "../components/PatientInfo";
import {
  CLAIM_REQUEST,
  CLAIM_REQUEST_METHOD,
  CLAIM_REQUEST_URL,
  CLAIM_RESPONSE,
  SELECTED_PATIENT_ID,
} from "../constants/localStorageVariables";
import { HTTP_METHODS } from "../constants/enum";

const ClaimForm = () => {
  const dispatch = useDispatch();
  const medicationFormData = useSelector(
    (state: {
      medicationFormData: {
        medication: string;
        frequency: number;
        period: number;
      };
    }) => state.medicationFormData
  );
  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);
  const [showSuccessAnimation, setShowSuccessAnimation] = useState(false);

  const savedPatientId = localStorage.getItem(SELECTED_PATIENT_ID);
  const loggedUser = useSelector((state: any) => state.loggedUser);

  if (savedPatientId) {
    dispatch(selectPatient(savedPatientId));
  }

  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

  useEffect(() => {
    dispatch(updateIsProcess(true));
    dispatch(
      updateSingleStep({
        stepName: "Medication request",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Check Payer Requirements",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Questionnaire package",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Questionnaire Response",
        newStatus: StepStatus.COMPLETED,
      })
    );
  }, [dispatch]);

  const [formData, setFormData] = useState<{
    medication: string;
    quantity: number;
    patient: string;
    provider: string;
    insurer: string;
    use: string;
    supportingInfo: string;
    category: string;
    unitPrice: string;
  }>({
    medication: medicationFormData.medication,
    quantity: medicationFormData.frequency * medicationFormData.period,
    patient:
      currentPatient?.name[0].given[0] + " " + currentPatient?.name[0].family,
    provider: "PractitionerRole/456",
    insurer: "Organization/insurance-org",
    use: "preauthorization",
    supportingInfo: "QuestionnaireResponse/1122",
    category: "Pharmacy",
    unitPrice: "600 USD",
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { id, value } = e.target;
    setFormData((prevFormData) => ({
      ...prevFormData,
      [id]: value,
    }));
  };

  const handleSubmit = () => {
    const Config = window.Config;
    const payload = CLAIM_REQUEST_BODY(
      formData.patient,
      formData.provider,
      formData.insurer,
      formData.use,
      formData.supportingInfo,
      formData.category,
      formData.medication,
      formData.quantity,
      formData.unitPrice
    );

    dispatch(updateActiveStep(4));
    dispatch(
      updateSingleStep({
        stepName: "Medication request",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Check Payer Requirements",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Questionnaire package",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Questionnaire Response",
        newStatus: StepStatus.COMPLETED,
      })
    );
    dispatch(
      updateSingleStep({
        stepName: "Claim Submit",
        newStatus: StepStatus.IN_PROGRESS,
      })
    );
    localStorage.setItem(CLAIM_REQUEST_METHOD, HTTP_METHODS.POST);
    localStorage.setItem(
      CLAIM_REQUEST_URL,
      Config.demoBaseUrl + Config.claim_submit
    );

    localStorage.setItem(CLAIM_REQUEST, JSON.stringify(payload));

    axios
      .post(Config.claim_submit, payload, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        if (response.status >= 200 && response.status < 300) {
          console.log("Claim submitted successfully:", response.data);
          if (
            response.data.parameter[0].resource.outcome &&
            response.data.parameter[0].resource.outcome === "complete"
          ) {
            setAlertMessage("Prior Authorization Status: Completed");
            setAlertSeverity("success");
            setShowSuccessAnimation(true);
          } else {
            console.log("Prior Authorization error:", response.data.issue);
            setAlertMessage("Prior Authorization");
            setAlertSeverity("error");
          }
        } else {
          setAlertMessage("Error submitting claim");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);

        localStorage.setItem(CLAIM_RESPONSE, JSON.stringify(response.data));
        dispatch(
          updateSingleStep({
            stepName: "Claim Submit",
            newStatus: StepStatus.COMPLETED,
          })
        );
      })
      .catch((error) => {
        setAlertMessage("Error submitting claim");
        setAlertSeverity("error");
        setOpenSnackbar(true);
        console.log(error);
        return;
      });
  };

  const handleCloseSnackbar = () => {
    setOpenSnackbar(false);
  };

  const defaultOptions = {
    loop: false,
    autoplay: true,
    animationData: successAnimation,
    rendererSettings: {
      preserveAspectRatio: "xMidYMid slice",
    },
  };

  return (
    <Card style={{ marginTop: "30px", padding: "20px" }}>
      <Card.Body>
        <Card.Title>Claim Details</Card.Title>
        <Form>
          <div
            style={{
              display: "flex",
              gap: "20px",
            }}
          >
            <Form.Group
              controlId="patient"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Patient</Form.Label>
              <Form.Control
                type="text"
                value={formData.patient}
                onChange={handleChange}
                disabled
              />
            </Form.Group>
            <Form.Group
              controlId="provider"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Practitioner</Form.Label>
              <Form.Control
                type="text"
                // value={formData.provider}
                value={loggedUser?.first_name + " " + loggedUser?.last_name}
                onChange={handleChange}
                disabled
              />
            </Form.Group>
            <Form.Group
              controlId="insurer"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Insurer</Form.Label>
              <Form.Control
                type="text"
                value="UnitedCare Health Insurance"
                onChange={handleChange}
                disabled
              />
            </Form.Group>
          </div>

          <div
            style={{
              display: "flex",
              gap: "20px",
            }}
          >
            <Form.Group
              controlId="category"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Category</Form.Label>
              <Form.Control
                type="text"
                value={formData.category}
                onChange={handleChange}
                disabled
              />
            </Form.Group>
            <Form.Group
              controlId="use"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Use</Form.Label>
              <Form.Control
                type="text"
                value={formData.use.toLocaleUpperCase()}
                onChange={handleChange}
                disabled
              />
            </Form.Group>

            {/* <Form.Group
              controlId="supportingInfo"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Supporting Info</Form.Label>
              <Form.Control
                type="text"
                value={formData.supportingInfo}
                onChange={handleChange}
                disabled
              />
            </Form.Group> */}
          </div>

          <Form.Group controlId="medication" style={{ marginTop: "20px" }}>
            <Form.Label>Product/Service</Form.Label>
            <Form.Control
              type="text"
              value={formData.medication}
              onChange={handleChange}
              disabled
            />
          </Form.Group>

          <div
            style={{
              display: "flex",
              gap: "20px",
            }}
          >
            <Form.Group
              controlId="quantity"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Quantity</Form.Label>
              <Form.Control
                type="text"
                value={formData.quantity}
                onChange={handleChange}
                disabled
              />
            </Form.Group>

            <Form.Group
              controlId="unitPrice"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Unit Price</Form.Label>
              <Form.Control
                type="text"
                value={formData.unitPrice}
                onChange={handleChange}
                disabled
              />
            </Form.Group>
          </div>
          {showSuccessAnimation && (
            <div style={{ textAlign: "center", marginTop: "50px" }}>
              <Lottie options={defaultOptions} height={70} width={70} />
              <br />
              <h5>Prior Authorization Approved.</h5>
            </div>
          )}
          {!showSuccessAnimation && (
            <Button
              variant="success"
              style={{ marginTop: "30px", marginRight: "20px", float: "right" }}
              onClick={handleSubmit}
            >
              Submit Claim
            </Button>
          )}
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
