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
import { useDispatch } from "react-redux";
import Form from "react-bootstrap/Form";
import axios from "axios";
import { selectPatient } from "../redux/patientSlice";
import { Patient } from "../components/interfaces/patient";

export default function DetailsDiv({ patientId }: { patientId: string }) {
  const dispatch = useDispatch();
  const [patient, setPatient] = useState<Patient | null>(null);

  useEffect(() => {
    const fetchPatientDetails = async () => {
      try {
        const Config = window.Config;
        const response = await axios.get(`${Config.patient}/${patientId}`);
        if (response.status >= 200 && response.status < 300) {
          setPatient(response.data);
          dispatch(selectPatient(response.data.id));
        }
      } catch (error) {
        console.error("Error fetching patient details:", error);
      }
    };

    fetchPatientDetails();
  }, [patientId, dispatch]);

  return (
    <div style={{ display: "flex", gap: "20px" }}>
      <Form.Group
        controlId="formPatientName"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Patient Name</Form.Label>
        <Form.Control
          type="text"
          value={
            patient
              ? `${patient.name[0].given[0]} ${patient.name[0].family}`
              : "Loading..."
          }
          disabled
        />
      </Form.Group>
      <Form.Group
        controlId="formPatientID"
        style={{ marginTop: "20px", flex: "1 1 100%" }}
      >
        <Form.Label>Patient ID</Form.Label>
        <Form.Control
          type="text"
          value={patient ? patient.id : "Loading..."}
          disabled
        />
      </Form.Group>
    </div>
  );
}
