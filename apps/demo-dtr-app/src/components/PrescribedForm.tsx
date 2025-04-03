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

import { useEffect, useState } from "react";
import axios from "axios";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import DatePicker from "react-datepicker";

export default function PrescribedForm({
  medicationRequestId,
  setPractitionerIdCallback,
}: {
  medicationRequestId: string;
  setPractitionerIdCallback: (id: string) => void;
}) {
  const [medicationData, setMedicationData] = useState<{
    medication: string;
    quantity: string;
    frequency: string;
    duration: string;
    startDate: Date | null;
  }>({
    medication: "",
    quantity: "",
    frequency: "",
    duration: "",
    startDate: null,
  });

  useEffect(() => {
    const fetchMedicationRequest = async () => {
      try {
        const Config = window.Config;
        const response = await axios.get(
          `${Config.medicationRequest}/${medicationRequestId}`
        );
        if (response.status >= 200 && response.status < 300) {
          const data = response.data;
          setPractitionerIdCallback(data.requester.reference || "");
          setMedicationData({
            medication: data.medicationCodeableConcept?.text || "",
            quantity: `${data.dispenseRequest?.quantity?.value || ""} ${
              data.dispenseRequest?.quantity?.unit || ""
            }`,
            frequency: data.dosageInstruction?.[0]?.text || "",
            duration: `${
              data.dispenseRequest?.expectedSupplyDuration?.value || ""
            } ${data.dispenseRequest?.expectedSupplyDuration?.unit || ""}`,
            startDate: data.dosageInstruction?.[0]?.timing?.repeat?.boundsPeriod
              ?.start
              ? new Date(
                  data.dosageInstruction[0].timing.repeat.boundsPeriod.start
                )
              : null,
          });
        }
      } catch (error) {
        console.error("Error fetching medication request:", error);
      }
    };

    fetchMedicationRequest();
  }, [medicationRequestId, setPractitionerIdCallback]);

  return (
    <Card style={{ marginTop: "30px", padding: "20px" }}>
      <Card.Body>
        <Card.Title>Prescribed Medicine</Card.Title>
        <Form>
          <Form.Group controlId="formMedication" style={{ marginTop: "20px" }}>
            <Form.Label>Medication</Form.Label>
            <Form.Control
              type="text"
              value={medicationData.medication}
              disabled
            />
          </Form.Group>

          <div style={{ display: "flex", gap: "20px" }}>
            <Form.Group
              controlId="formQuantity"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Quantity</Form.Label>
              <Form.Control
                type="text"
                value={medicationData.quantity}
                disabled
              />
            </Form.Group>

            <Form.Group
              controlId="formFrequency"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Frequency</Form.Label>
              <Form.Control
                type="text"
                value={medicationData.frequency}
                disabled
              />
            </Form.Group>

            <Form.Group
              controlId="formDuration"
              style={{ marginTop: "20px", flex: "1 1 100%" }}
            >
              <Form.Label>Duration (days)</Form.Label>
              <Form.Control
                type="text"
                value={medicationData.duration}
                disabled
              />
            </Form.Group>

            <Form.Group
              controlId="formStartDate"
              style={{
                marginTop: "20px",
                flex: "1 1 100%",
                width: "100%",
              }}
            >
              <Form.Label>Starting Date</Form.Label>
              <br />
              <DatePicker
                selected={medicationData.startDate}
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
}
