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
import "../assets/styles/main.css";
import "bootstrap/dist/css/bootstrap.min.css";
import "react-datepicker/dist/react-datepicker.css";
import Form from "react-bootstrap/Form";
import Button from "react-bootstrap/Button";
import Select from "react-select";
import Card from "react-bootstrap/Card";
import { DEVICE } from "../constants/data";

const PrescribeDeviceForm = () => {
  const [formData, setFormData] = useState({
    medicalDevice: "",
    insturction: "",
    startDate: new Date() as Date | null,
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSelectChange = (
    newValue: { value: string; label: string } | null,
    actionMeta: { name?: string }
  ) => {
    if (actionMeta.name) {
      setFormData({
        ...formData,
        [actionMeta.name]: newValue ? newValue.value : "",
      });
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Form Data:", formData);
  };

  return (
    <Card style={{ marginTop: "30px", padding: "20px" }}>
      <Card.Body>
        <Card.Title>Prescribe a Medical Device</Card.Title>
        <Form onSubmit={handleSubmit}>
          <Form.Group
            controlId="formTreatingSickness"
            style={{ marginTop: "20px" }}
          >
            <Form.Label>
              Medical Device <span style={{ color: "red" }}>*</span>
            </Form.Label>
            <Select
              name="medicalDevice"
              options={DEVICE.map((device) => ({
                label: device.name,
                value: device.name,
              }))}
              isSearchable
              onChange={handleSelectChange}
              required
            />
          </Form.Group>

          <Form.Group
            controlId="formDeviceDescription"
            style={{ marginTop: "20px", marginBottom: "20px" }}
          >
            {formData.medicalDevice && (
              <Card style={{ padding: "20px" }}>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                  }}
                >
                  <img
                    src={
                      DEVICE.find(
                        (device) => device.name === formData.medicalDevice
                      )?.imagePath || ""
                    }
                    alt={formData.medicalDevice}
                    style={{
                      width: "auto",
                      height: "150px",
                      marginRight: "20px",
                    }}
                  />
                  <Form.Control
                    as="textarea"
                    rows={5}
                    value={
                      DEVICE.find(
                        (device) => device.name === formData.medicalDevice
                      )?.large_description || ""
                    }
                    disabled
                  />
                </div>
              </Card>
            )}
          </Form.Group>

          <Form.Group
            controlId="formDeviceDescription"
            style={{ marginTop: "20px" }}
          >
            <Form.Label>Usage Instruction</Form.Label>
            <Form.Control
              as="textarea"
              rows={3}
              placeholder="Enter instructions for usage"
              name="insturction"
              value={formData.insturction}
              onChange={handleInputChange}
            />
          </Form.Group>

          <Button
            variant="primary"
            type="submit"
            style={{ marginTop: "30px", float: "right" }}
          >
            CHECK PAYER REQUIREMENTS
          </Button>
        </Form>
      </Card.Body>
    </Card>
  );
};

const PrescribeDeviceCard = () => {
  return (
    <div
      style={{
        color: "black",
        marginTop: "20px",
      }}
    >
      <PrescribeDeviceForm />
    </div>
  );
};

export default function DeviceOrderPageV2() {
  return (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <div className="page-heading">Order Device</div>
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
      </div>
      <div>
        <PrescribeDeviceCard />
      </div>
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
