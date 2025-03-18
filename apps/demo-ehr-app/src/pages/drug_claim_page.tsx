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

import React, { useState } from "react";
import axios from "axios";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import { paths } from "../config/urlConfigs";
import { useDispatch, useSelector } from "react-redux";
import {
  updateRequest,
  updateRequestMethod,
  updateRequestUrl,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";
import { CLAIM_REQUEST_BODY } from "../constants/data";
import { useAuth } from "../components/AuthProvider";
import { Navigate } from "react-router-dom";

const ClaimForm = () => {
  const dispatch = useDispatch();
  const medicationFormData = useSelector(
    (state: { medicationFormData: { medication: string; quantity: string } }) =>
      state.medicationFormData
  );
  const [formData, setFormData] = useState<{
    medication: string;
    quantity: string;
    patient: string;
    provider: string;
    insurer: string;
    use: string;
    supportingInfo: string;
    category: string;
    unitPrice: string;
  }>({
    medication: medicationFormData.medication,
    quantity: medicationFormData.quantity,
    patient: "Patient/101",
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
    console.log("Form data submitted:", formData);
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
    console.log("payload", payload);
    dispatch(updateRequest(payload));
    dispatch(updateRequestMethod("POST"));
    dispatch(updateRequestUrl("/fhir/r4/Claim/$submit"));
    dispatch(resetCdsResponse());
    axios
      .post(paths.claim_submit, payload, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        console.log("Claim submitted successfully");
        dispatch(
          updateCdsResponse({
            cards: response.data,
            systemActions: {},
          })
        );
        alert(
          `Claim submitted successfully. Outcome: ${response.data.parameter[0].resource.outcome}`
        );
        console.log("response", response);
        console.log("outcome", response.data.parameter[0].resource.outcome);
      })
      .catch((error) => {
        console.error("Error submitting claim", error);
        dispatch(
          updateCdsResponse({
            cards: error,
            systemActions: {},
          })
        );
      });
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
              <Form.Label>Provider</Form.Label>
              <Form.Control
                type="text"
                value={formData.provider}
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
                value={formData.insurer}
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
              controlId="use"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Use</Form.Label>
              <Form.Control
                type="text"
                value={formData.use}
                onChange={handleChange}
                disabled
              />
            </Form.Group>

            <Form.Group
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
            </Form.Group>
          </div>

          <Form.Group controlId="category" style={{ marginTop: "20px" }}>
            <Form.Label>Category</Form.Label>
            <Form.Control
              type="text"
              value={formData.category}
              onChange={handleChange}
              disabled
            />
          </Form.Group>

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
          <Button
            variant="success"
            style={{ marginTop: "30px", marginRight: "20px", float: "right" }}
            onClick={handleSubmit}
          >
            Submit Claim
          </Button>
        </Form>
      </Card.Body>
    </Card>
  );
};

export default function DrugClaimPage() {
  const { isAuthenticated } = useAuth();
  const medicationFormData = useSelector(
    (state: { medicationFormData: { medication: string; quantity: string } }) =>
      state.medicationFormData
  );

  console.log("medicationFormData", medicationFormData);
  return isAuthenticated ? (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">Claim Insurance</div>
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
