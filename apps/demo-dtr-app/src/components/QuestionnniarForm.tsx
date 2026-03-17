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

const getQuestionText = (text: { value: string } | string | undefined): string =>
  typeof text === "string" ? text : (text?.value ?? "");

/**
 * Extracts the Questionnaire ID from a full FHIR Questionnaire URL.
 * E.g. "https://example.com/fhir/r4/Questionnaire/34" -> "34"
 */
const extractQuestionnaireId = (url: string): string => {
  const parts = url.split("/");
  return parts[parts.length - 1];
};

export default function QuestionnniarForm({
  coverageId,
  medicationRequestId,
  serviceRequestId,
  questionnaireUrl,
  patientId,
  isQuestionnaireResponseSubmited,
  setIsQuestionnaireResponseSubmited,
  practitionerId,
}: {
  coverageId?: string;
  medicationRequestId?: string;
  serviceRequestId?: string;
  questionnaireUrl?: string;
  patientId: string;
  isQuestionnaireResponseSubmited: boolean;
  setIsQuestionnaireResponseSubmited: React.Dispatch<
    React.SetStateAction<boolean>
  >;
  practitionerId: string;
}) {
  const dispatch = useDispatch();
  const [questions, setQuestions] = useState<
    {
      linkId: string;
      text: { value: string } | string;
      type: string;
      extension?: any[];
    }[]
  >([]);
  const [questionnaireID, setQuestionnaireID] = useState<string | null>(
    questionnaireUrl ? extractQuestionnaireId(questionnaireUrl) : null
  );
  const [questionnaireResponseID, setQuestionnaireResponseID] = useState<string | null>(null);
  const [formData, setFormData] = useState<{
    [key: string]: string | number | boolean;
  }>({});
  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);

  const Config = window.Config;

  /**
   * Build the questionnaire-package request body dynamically based on
   * which parameters are available in the launch context.
   */
  const buildRequestBody = () => {
    const parameters: any[] = [];

    // Always include the questionnaire URL when launching via DTR link
    if (questionnaireUrl) {
      parameters.push({
        name: "questionnaire",
        valueCanonical: questionnaireUrl,
      });
    }

    // Include coverage if provided
    if (coverageId) {
      parameters.push({
        name: "coverage",
        resource: {
          resourceType: "Coverage",
          reference: "Coverage/" + coverageId,
        },
      });
    }

    // Include order — prefer MedicationRequest, fall back to ServiceRequest
    if (medicationRequestId) {
      parameters.push({
        name: "order",
        resource: {
          resourceType: "MedicationRequest",
          reference: "MedicationRequest/" + medicationRequestId,
        },
      });
    } else if (serviceRequestId) {
      parameters.push({
        name: "order",
        resource: {
          resourceType: "ServiceRequest",
          reference: "ServiceRequest/" + serviceRequestId,
        },
      });
    }

    return {
      resourceType: "Parameters",
      id: "questionnaire-package-request",
      parameter: parameters,
    };
  };

  useEffect(() => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());
    dispatch(updateRequestUrl(Config.questionnaire_package));
    dispatch(updateRequestMethod("POST"));

    const requestBody = buildRequestBody();
    dispatch(updateRequest(requestBody));

    axios
      .post(Config.questionnaire_package, requestBody, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        if (response.status >= 200 && response.status < 300) {
          setAlertMessage("Questionnaire fetched successfully!");
          setAlertSeverity("success");

          if (window !== window.parent) {
            window.parent.postMessage({
              type: "DTR_QUESTIONNAIRE_PACKAGE_LOG",
              payload: {
                method: "POST",
                url: Config.questionnaire_package,
                request: requestBody,
                response: response.data
              }
            }, "*");
          }
        } else {
          setAlertMessage("Failed to fetch questionnaire!");
          setAlertSeverity("error");
        }
        setOpenSnackbar(true);

        const questionnaire = response.data;
        const questionnaireParam = questionnaire.parameter?.find(
          (p: any) => p.name === "PackageBundle"
        );
        const questionnaireResource =
          questionnaireParam?.resource?.entry?.[0]?.resource ?? {};
        const rawItems: any[] = questionnaireResource.item ?? [];
        const items = rawItems.filter(
          (
            item
          ): item is {
            linkId: string;
            text: { value: string } | string;
            type: string;
            extension?: any[];
          } =>
            typeof item.linkId === "string" && item.type !== undefined
        );
        if (items.length === 0) {
          console.warn("Questionnaire parsed successfully but contained no items.", questionnaireResource);
        }

        // Pre-populate dummy values for questions that have a CQL initialExpression
        // so that the UI clearly shows values as if CQL was executed.
        const initialFormData: {
          [key: string]: string | number | boolean;
        } = {};

        items.forEach((item) => {
          const hasCqlInitialExpression = item.extension?.some(
            (ext: any) =>
              ext?.url ===
              "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression"
          );

          if (!hasCqlInitialExpression) {
            return;
          }

          // Use sensible demo defaults tailored to the MRI Spine Prior Auth questionnaire.
          // Fall back to type-based defaults for any other questionnaires.
          switch (item.linkId) {
            case "1": // Primary ICD-10 diagnosis code
              initialFormData[item.linkId] = "M54.16"; // Radiculopathy, lumbar region
              return;
            case "2": // Clinical indication / reason for MRI
              initialFormData[item.linkId] =
                "Persistent low back pain with right leg radiculopathy.";
              return;
            case "3": // Symptom onset date
              initialFormData[item.linkId] = "2026-01-15";
              return;
            case "4": // Duration of symptoms (in weeks)
              initialFormData[item.linkId] = 8;
              return;
            case "5": // Has neurological deficits
              initialFormData[item.linkId] = true;
              return;
            case "6": // Has conservative treatment
              initialFormData[item.linkId] = true;
              return;
            case "7": // Conservative treatments list
              initialFormData[item.linkId] =
                "NSAIDs, physical therapy, and home exercise program for 8 weeks.";
              return;
            case "8": // Has red flag symptoms
              initialFormData[item.linkId] = false;
              return;
            case "9": // Ordering provider NPI
              initialFormData[item.linkId] = "1234567890";
              return;
            default:
              break;
          }

          // Generic fallback for other questionnaires
          switch (item.type) {
            case "boolean":
              initialFormData[item.linkId] = true;
              break;
            case "integer":
              initialFormData[item.linkId] = 6;
              break;
            case "date":
              initialFormData[item.linkId] = "2026-03-01";
              break;
            case "string":
            default:
              initialFormData[item.linkId] = "Auto-populated value";
              break;
          }
        });

        setQuestions(items);
        setFormData((prev) => ({ ...initialFormData, ...prev }));

        // Use the ID from the fetched resource if we didn't have it from the URL
        if (!questionnaireID && questionnaireResource.id) {
          setQuestionnaireID(questionnaireResource.id);
        }

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
    const parsedValue =
      type === "number"
        ? value === ""
          ? ""
          : parseFloat(value)
        : value;
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

    return {
      resourceType: "QuestionnaireResponse",
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
        reference: practitionerId || "Practitioner/456",
      },
      item: questions.map((question) => ({
        linkId: question.linkId,
        text: getQuestionText(question.text),
        answer: [
          {
            valueBoolean:
              typeof formData[question.linkId] === "boolean"
                ? (formData[question.linkId] as boolean)
                : undefined,
            valueInteger:
              typeof formData[question.linkId] === "number"
                ? (formData[question.linkId] as number)
                : undefined,
            valueString:
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
          if (response.data && response.data.id) {
            setQuestionnaireResponseID(response.data.id);
          }
          if (window !== window.parent) {
            window.parent.postMessage({
              type: "DTR_QUESTIONNAIRE_RESPONSE_LOG",
              payload: {
                method: "POST",
                url: Config.questionnaire_response,
                request: questionnaireResponse,
                response: response.data
              }
            }, "*");
          }
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
            value={
              typeof formData[question.linkId] === "boolean"
                ? formData[question.linkId]
                  ? { value: "Yes", label: "Yes" }
                  : { value: "No", label: "No" }
                : null
            }
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
        {
          const rawValue = formData[question.linkId];
          const valueForInput =
            typeof rawValue === "number" || typeof rawValue === "string"
              ? rawValue
              : "";
          return (
            <Form.Control
              type="number"
              name={question.linkId}
              value={valueForInput as string | number}
              onChange={handleInputChange}
            />
          );
        }
      case "date":
        {
          const rawValue = formData[question.linkId];
          const valueForInput =
            typeof rawValue === "string" ? rawValue : "";
          return (
            <Form.Control
              type="date"
              name={question.linkId}
              value={valueForInput}
              onChange={handleInputChange}
            />
          );
        }
      case "string":
      default:
        {
          const rawValue = formData[question.linkId];
          const valueForInput =
            typeof rawValue === "string" ? rawValue : "";
          return (
            <Form.Control
              type="text"
              name={question.linkId}
              value={valueForInput}
              onChange={handleInputChange}
            />
          );
        }
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
                {getQuestionText(question.text)} <span style={{ color: "red" }}>*</span>
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
            onClick={() => {
              console.log("DTR -> Claim Submit - IDs:", {
                patientId,
                serviceRequestId,
                medicationRequestId,
                coverageId,
                qrId: questionnaireResponseID
              });
              const claimUrl = [
                Config.ehr_baseUrl,
                "/dashboard/claim-submit",
                `?patientId=${patientId}`,
                serviceRequestId ? `&serviceRequestId=${serviceRequestId}` : "",
                medicationRequestId ? `&medicationRequestId=${medicationRequestId}` : "",
                coverageId ? `&coverageId=${coverageId}` : "",
                questionnaireResponseID ? `&qrId=${questionnaireResponseID}` : ""
              ].join("");
              console.log("Opening claim URL:", claimUrl);

              if (window !== window.parent) {
                console.log("Embedded mode detected, sending postMessage");
                window.parent.postMessage({
                  type: "DTR_CLAIM_SUBMIT",
                  payload: {
                    patientId,
                    serviceRequestId,
                    medicationRequestId,
                    coverageId,
                    qrId: questionnaireResponseID
                  }
                }, "*");
              } else {
                window.open(claimUrl);
              }
            }}
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
