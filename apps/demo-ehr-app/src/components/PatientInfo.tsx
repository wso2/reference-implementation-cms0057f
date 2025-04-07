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

import React from "react";
import Form from "react-bootstrap/Form";
import Button from "react-bootstrap/Button";
import CachedIcon from "@mui/icons-material/Cached";
import {
  SELECTED_PATIENT_ID,
  SELECTED_PATIENT_NAME,
} from "../constants/localStorageVariables";

const PatientInfo: React.FC = () => {
  const savedPatientId = localStorage.getItem(SELECTED_PATIENT_ID);
  const savedPatientName = localStorage.getItem(SELECTED_PATIENT_NAME);
  return (
    <div style={{ display: "flex", gap: "20px" }}>
      <Form.Group
        controlId="formPatientName"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Patient Name</Form.Label>
        <Form.Control type="text" value={savedPatientName || ""} disabled />
      </Form.Group>
      <Form.Group
        controlId="formPatientID"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Patient ID</Form.Label>
        <Form.Control type="text" value={savedPatientId || ""} disabled />
      </Form.Group>
      <Form.Group controlId="formAddButton" style={{ marginTop: "20px" }}>
        <Form.Label>&nbsp;</Form.Label>
        <Button
          variant="danger"
          style={{ display: "block", width: "100%" }}
          onClick={() => (window.location.href = "/")}
        >
          <CachedIcon />
        </Button>
      </Form.Group>
    </div>
  );
};

export default PatientInfo;
