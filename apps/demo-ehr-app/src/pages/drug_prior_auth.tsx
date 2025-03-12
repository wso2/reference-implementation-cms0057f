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
import { useLocation } from "react-router-dom";
import { baseUrl, paths } from "../config/urlConfigs";
import Select from "react-select";
import DatePicker from "react-datepicker";
import { useDispatch, useSelector } from "react-redux";
import {
  updateRequest,
  updateRequestUrl,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

const QuestionnniarForm = ({
  questionnaireId,
  isQuestionnaireResponseSubmited,
  setIsQuestionnaireResponseSubmited,
}: {
  questionnaireId: string;
  isQuestionnaireResponseSubmited: boolean;
  setIsQuestionnaireResponseSubmited: React.Dispatch<
    React.SetStateAction<boolean>
  >;
}) => {
  const dispatch = useDispatch();
  const [questions, setQuestions] = useState<
    { linkId: string; text: string; type: string }[]
  >([]);
  const [formData, setFormData] = useState<{
    [key: string]: string | number | boolean;
  }>({});

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

  useEffect(() => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());
    // Fetch the questionnaire data from the API
    axios
      .post(baseUrl + paths.questionnaire_package, requestBody, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        const questionnaire = response.data;
        setQuestions(
          questionnaire.parameter[0].resource.entry[0].resource.item || []
        );

        dispatch(
          updateRequestUrl("/fhir/r4/Questionnaire/$questionnaire-package")
        );
        dispatch(updateRequestMethod("POST"));
        dispatch(updateRequest(requestBody));

        dispatch(
          updateCdsResponse({
            cards: questionnaire,
            systemActions: {},
          })
        );
      })
      .catch((error) => {
        console.error("Error fetching questionnaire data:", error);
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

  // generate the questionnaire response object
  const generateQuestionnaireResponse = () => {
    return {
      resourceType: "QuestionnaireResponse",
      questionnaire: "Questionnaire/" + questionnaireId,
      status: "completed",
      subject: {
        reference: "Patient/101",
      },
      author: {
        reference: "PractitionerRole/456",
      },
      item: questions.map((question) => ({
        linkId: question.linkId,
        text: question.text,
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
          },
        ],
      })),
    };
  };

  const submitQuestionnaireResponse = (questionnaireResponse: {
    resourceType: string;
    questionnaire: string;
    status: string;
    subject: { reference: string };
    author: { reference: string };
    item: {
      linkId: string;
      text: string;
      answer: {
        valueQuestionnaireResponseBoolean?: boolean;
        valueQuestionnaireResponseNumber?: number;
        valueQuestionnaireResponseString?: string;
      }[];
    }[];
  }) => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());
    dispatch(updateRequest(questionnaireResponse));
    dispatch(updateRequestUrl("/fhir/r4/QuestionnaireResponse"));
    dispatch(updateRequestMethod("POST"));

    // Submit the questionnaire response to the API
    axios
      .post(baseUrl + paths.questionnaire_response, questionnaireResponse, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      })
      .then((response) => {
        dispatch(
          updateCdsResponse({ cards: response.data, systemActions: {} })
        );
        alert("Questionnaire response submitted successfully!");
        setIsQuestionnaireResponseSubmited(true);
      })
      .catch((error) => {
        console.error("Error submitting questionnaire response:", error);
        dispatch(
          updateCdsResponse({
            cards: error,
            systemActions: {},
          })
        );
      });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const questionnaireResponse = generateQuestionnaireResponse();
    submitQuestionnaireResponse(questionnaireResponse);
  };

  const renderFormField = (question: {
    linkId: string;
    text: string;
    type: string;
  }) => {
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
              <Form.Label>{question.text}</Form.Label>
              {renderFormField(question)}
            </Form.Group>
          ))}
          <Button
            variant="primary"
            type="submit"
            style={{ marginTop: "30px", float: "right" }}
            onClick={handleSubmit}
            // disabled={isQuestionnaireResponseSubmited}
          >
            Submit Questionnaire Response
          </Button>
        </Form>
        <Button
          variant="success"
          style={{ marginTop: "30px", marginRight: "20px", float: "right" }}
          onClick={() =>
            window.open(
              "/patient/dashboard/drug-order-v2/claim-submit",
              "_blank"
            )
          }
          disabled={!isQuestionnaireResponseSubmited}
        >
          Visit Claim Submission
        </Button>
      </Card.Body>
    </Card>
  );
};

const PrescribedForm = () => {
  const medicationFormData = useSelector(
    (state: {
      medicationFormData: {
        treatingSickness: string;
        medication: string;
        quantity: string;
        frequency: string;
        startDate: Date;
      };
    }) => state.medicationFormData
  );
  const treatingSickness = medicationFormData.treatingSickness;
  const medication = medicationFormData.medication;
  const quantity = medicationFormData.quantity;
  const frequency = medicationFormData.frequency;

  return (
    <Card style={{ marginTop: "30px", padding: "20px" }}>
      <Card.Body>
        <Card.Title>Prescribed Medicine</Card.Title>
        <Form>
          <Form.Group
            controlId="formTreatingSickness"
            style={{ marginTop: "20px" }}
          >
            <Form.Label>Treating Sickness</Form.Label>
            <Form.Control type="text" value={treatingSickness || ""} disabled />
          </Form.Group>

          <Form.Group controlId="formMedication" style={{ marginTop: "20px" }}>
            <Form.Label>Medication</Form.Label>
            <Form.Control type="text" value={medication || ""} disabled />
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
              <Form.Label>Quantity</Form.Label>
              <Form.Control type="text" value={quantity || ""} disabled />
            </Form.Group>

            <Form.Group
              controlId="formFrequency"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Frequency</Form.Label>
              <Form.Control type="text" value={frequency || ""} disabled />
            </Form.Group>

            <Form.Group
              controlId="formDuration"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Duration (days)</Form.Label>
              <Form.Control type="text" value={frequency || ""} disabled />
            </Form.Group>

            <Form.Group
              controlId="formStartDate"
              style={{ marginTop: "20px", flex: "1 1 100%", width: "100%" }}
            >
              <Form.Label>Starting Date</Form.Label>
              <br />
              <DatePicker
                selected={medicationFormData.startDate}
                dateFormat="yyyy/MM/dd"
                className="form-control"
                wrapperClassName="date-picker-full-width"
                disabled
              />
            </Form.Group>
          </div>
        </Form>
      </Card.Body>
    </Card>
  );
};

const DetailsDiv = ({ questionnaireId }: { questionnaireId: string }) => {
  return (
    <div style={{ display: "flex", gap: "20px" }}>
      <Form.Group
        controlId="formPatientName"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Patient Name</Form.Label>
        <Form.Control type="text" value="PA0012323" disabled />
      </Form.Group>
      <Form.Group
        controlId="formPatientID"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Patient ID</Form.Label>
        <Form.Control type="text" value="PT32403" disabled />
      </Form.Group>
      <Form.Group
        controlId="formPatientName"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Questionnaire ID</Form.Label>
        <Form.Control type="text" value={questionnaireId} disabled />
      </Form.Group>
    </div>
  );
};

export default function DrugPiorAuthPage() {
  const query = useQuery();
  const questionnaireId = query.get("questionnaireId");
  const [isQuestionnaireResponseSubmited, setIsQuestionnaireResponseSubmited] =
    useState(false);

  return (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">
        Send a Prior-Authorizing Request for Drugs
      </div>
      <DetailsDiv questionnaireId={questionnaireId || ""} />
      <PrescribedForm />
      <QuestionnniarForm
        questionnaireId={questionnaireId || ""}
        isQuestionnaireResponseSubmited={isQuestionnaireResponseSubmited}
        setIsQuestionnaireResponseSubmited={setIsQuestionnaireResponseSubmited}
      />
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
  );
}
