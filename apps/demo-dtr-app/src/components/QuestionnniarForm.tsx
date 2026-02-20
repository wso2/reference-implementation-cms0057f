// Copyright (c) 2024-2025, WSO2 LLC. (http://www.wso2.com).
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
import { useDispatch } from "react-redux";
import axios from "axios";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import Select from "react-select";
import { Alert, Snackbar } from "@mui/material";
import {
  updateRequest,
  updateRequestUrl,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";

export default function QuestionnniarForm({
  coverageId,
  medicationRequestId,
  patientId,
  isQuestionnaireResponseSubmited,
  setIsQuestionnaireResponseSubmited,
  practitionerId,
}: {
  coverageId: string;
  medicationRequestId: string;
  patientId: string;
  isQuestionnaireResponseSubmited: boolean;
  setIsQuestionnaireResponseSubmited: React.Dispatch<
    React.SetStateAction<boolean>
  >;
  practitionerId: string;
}) {
  const dispatch = useDispatch();
  const [questions, setQuestions] = useState<
    { linkId: string; text: { value: string } | string; type: string }[]
  >([]);
  const [questionnaireID, setQuestionnaireID] = useState<string | null>(null);
  const [formData, setFormData] = useState<{
    [key: string]: string | number | boolean;
  }>({});
  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);

  const Config = window.Config;

  const questionnairePackageRequestBody = {
    resourceType: "Parameters",
    id: "questionnaire-package-request",
    parameter: [
      {
        name: "coverage",
        resource: {
          resourceType: "Coverage",
          reference: "Coverage/" + coverageId,
        },
      },
      {
        name: "order",
        resource: {
          resourceType: "MedicationRequest",
          reference: "MedicationRequest/" + medicationRequestId,
        },
      },
    ],
  };

  useEffect(() => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());
    dispatch(updateRequestUrl(Config.questionnaire_package));
    dispatch(updateRequestMethod("POST"));
    dispatch(updateRequest(questionnairePackageRequestBody));

    axios
      .post(Config.questionnaire_package, questionnairePackageRequestBody, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        if (response.status >= 200 && response.status < 300) {
          setAlertMessage("Questionnaire fetched successfully!");
          setAlertSeverity("success");
        } else {
          setAlertMessage("Failed to fetch questionnaire!");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);

        const questionnaire = response.data;
        const questionnaireResource = questionnaire.parameter?.[0]?.resource?.entry?.[0]?.resource || {};
        const items = questionnaireResource.item || [];
        setQuestions(items);
        setQuestionnaireID(questionnaireResource.id || null);

        dispatch(
          updateCdsResponse({
            cards: questionnaire,
            systemActions: {},
          })
        );
      })
      .catch((error) => {
        setAlertMessage("Error fetching questionnaire!");
        setAlertSeverity("error");
        setOpenSnackbar(true);
        console.error("Error fetching questionnaire:", error);
        dispatch(
          updateCdsResponse({
            cards: error,
            systemActions: {},
          })
        );
      });
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type } = e.target;
    const parsedValue = type === "number" ? parseFloat(value) : value;
    setFormData({ ...formData, [name]: parsedValue });
  };

  const handleBooleanChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, checked } = e.target;
    setFormData({ ...formData, [name]: checked });
  };

  const generateQuestionnaireResponse = () => {
    if (!patientId) {
      throw new Error("Patient ID not found");
    }

    if (!questionnaireID) {
      throw new Error("Questionnaire ID not found");
    }

    if (!practitionerId) {
      throw new Error("Practitioner ID not found");
    }

    return {
      resourceType: "QuestionnaireResponse",
      meta: {
        profile: [
          "http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse",
        ],
      },
      extension: [
        {
          url: "http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/questionnaireresponse-item-mapping-extension",
          valueExpression: {
            language: "text/fhirpath",
            expression: "Bundle.entry.resource",
          },
        },
      ],
      authored: new Date().toISOString(),
      questionnaire: "Questionnaire/" + questionnaireID,
      status: "completed",
      subject: {
        reference: "Patient/" + patientId,
      },
      author: {
        reference: practitionerId,
      },
      item: questions.map((question) => ({
        linkId: question.linkId,
        text: typeof question.text === 'string' ? question.text : question.text?.value,
        answer: [
          {
            valueQuestionnaireResponseBoolean:
              typeof formData[question.linkId] === "boolean"
                ? (formData[question.linkId] as boolean)
                : undefined,
            valueQuestionnaireResponseInteger:
              typeof formData[question.linkId] === "number"
                ? (formData[question.linkId] as number)
                : undefined,
            valueQuestionnaireResponseString:
              typeof formData[question.linkId] === "string"
                ? (formData[question.linkId] as string)
                : undefined,
            extension: [
              {
                url: "http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/questionnaireresponse-item-extension",
                valueExpression: {
                  language: "text/fhirpath",
                  expression: "Observation.value",
                },
              },
            ],
          },
        ],
      })),
    };
  };

  const submitQuestionnaireResponse = (questionnaireResponse: any) => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());
    dispatch(updateRequest(questionnaireResponse));
    dispatch(updateRequestUrl(Config.questionnaire_response));
    dispatch(updateRequestMethod("POST"));
    axios
      .post(Config.questionnaire_response, questionnaireResponse, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        if (response.status >= 200 && response.status < 300) {
          setAlertMessage("Questionnaire response submitted successfully!");
          setAlertSeverity("success");
        } else {
          setAlertMessage("Failed to submit questionnaire response!");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);
        dispatch(
          updateCdsResponse({ cards: response.data, systemActions: {} })
        );
        setIsQuestionnaireResponseSubmited(true);
      })
      .catch((error) => {
        console.error("Error submitting questionnaire response:", error);
        setAlertMessage("Error submitting questionnaire response!");
        setAlertSeverity("error");
        dispatch(
          updateCdsResponse({
            cards: error,
            systemActions: {},
          })
        );
      });
  };

  const validateForm = () => {
    return questions.every((question) => {
      const value = formData[question.linkId];
      return value !== undefined && value !== "";
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const questionnaireResponse = generateQuestionnaireResponse();
    submitQuestionnaireResponse(questionnaireResponse);
  };

  const renderFormField = (question: any) => {
    switch (question.type) {
      case "boolean":
        return (
          <Select
            name={question.linkId}
            onChange={(selectedOption) =>
              handleBooleanChange({
                target: {
                  name: question.linkId,
                  checked: selectedOption?.value === "Yes",
                },
              } as React.ChangeEvent<HTMLInputElement>)
            }
            options={[
              { value: "Yes", label: "Yes" },
              { value: "No", label: "No" },
            ]}
          />
        );
      case "integer":
        return (
          <Form.Control
            type="number"
            name={question.linkId}
            onChange={handleInputChange}
          />
        );
      case "string":
      default:
        return (
          <Form.Control
            type="text"
            name={question.linkId}
            onChange={handleInputChange}
          />
        );
    }
  };

  const handleCloseSnackbar = () => {
    setOpenSnackbar(false);
  };

  return (
    <Card style={{ marginTop: "30px", padding: "20px" }}>
      <Card.Body>
        <Card.Title>Questionnaire</Card.Title>
        <Form onSubmit={handleSubmit}>
          {questions.map((question, index) => (
            <Form.Group
              controlId={`formQuestion${index}`}
              style={{ marginTop: "20px" }}
              key={index}
            >
              <Form.Label>
                {typeof question.text === 'string' ? question.text : question.text?.value} <span style={{ color: "red" }}>*</span>
              </Form.Label>
              {renderFormField(question)}
            </Form.Group>
          ))}
          <Button
            variant="primary"
            type="submit"
            style={{ marginTop: "30px", float: "right" }}
            onClick={handleSubmit}
            disabled={!validateForm() || isQuestionnaireResponseSubmited}
          >
            Submit Questionnaire Response
          </Button>
        </Form>
        {isQuestionnaireResponseSubmited && (
          <Button
            variant="success"
            style={{ marginTop: "30px", marginRight: "20px", float: "right" }}
            onClick={() =>
              window.open(Config.ehr_baseUrl + "/dashboard/claim-submit")
            }
            disabled={!isQuestionnaireResponseSubmited}
          >
            Visit Claim Submission
          </Button>
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
  );
}
