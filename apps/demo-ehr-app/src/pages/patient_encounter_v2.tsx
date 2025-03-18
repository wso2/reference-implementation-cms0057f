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

import { useState } from "react";
import { PATIENT_DETAILS } from "../constants/data";
import { useDispatch } from "react-redux";
import { selectPatient } from "../redux/patientSlice";
import { Navigate, useNavigate } from "react-router-dom";
import NavBar from "../components/nav_bar";
import { useAuth } from "../components/AuthProvider";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Select, { SingleValue } from "react-select";
import Button from "react-bootstrap/Button";

function PatientEncounter() {
  const { isAuthenticated } = useAuth();
  const [selectedPatient, setSelectedPatient] = useState("");
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const patients: { [key: string]: string } = {};

  PATIENT_DETAILS.forEach((patient) => {
    const fullName = patient.name[0].given[0] + " " + patient.name[0].family;
    patients[patient.id] = fullName;
  });

  const handleSelectChange = (
    selectedOption: SingleValue<{ value: string | null }>
  ) => {
    if (selectedOption && selectedOption.value) {
      console.log("Patient: ", selectedOption.value);
      setSelectedPatient(selectedOption.value);
    }
  };

  const validateForm = () => {
    return selectedPatient.length > 0;
  };

  const handleBtnClick = () => {
    dispatch(selectPatient(selectedPatient));
    navigate("dashboard");
  };

  return isAuthenticated ? (
    <>
      <div
        style={{
          height: "100vh",
          width: "100vw",
          display: "flex",
          flexDirection: "column",
        }}
      >
        <div
          style={{
            position: "sticky",
            top: 0,
            zIndex: 1000,
            color: "white",
          }}
        >
          <NavBar />
        </div>
        <div>
          <div
            style={{
              marginLeft: 50,
              marginRight: 50,
              marginBottom: 50,
              marginTop: 30,
            }}
          >
            <div className="page-heading">Select Patient</div>

            <Card style={{ marginTop: "30px", padding: "20px" }}>
              <Card.Body>
                <Card.Title>Search for patient</Card.Title>
                <Form.Group
                  controlId="formTreatingSickness"
                  style={{ marginTop: "20px" }}
                >
                  <Form.Label>
                    Patient Name <span style={{ color: "red" }}>*</span>
                  </Form.Label>
                  <Select
                    name="treatingSickness"
                    options={PATIENT_DETAILS.map(
                      (patient: {
                        id: string;
                        name: { given: string[]; family: string }[];
                      }) => ({
                        value: patient.id,
                        label:
                          patient.name[0].given[0] +
                          " " +
                          patient.name[0].family,
                      })
                    )}
                    isSearchable
                    onChange={handleSelectChange}
                    required
                  />
                </Form.Group>
                <Button
                  variant="success"
                  // type="submit"
                  style={{ marginLeft: "30px", marginTop: "30px", float: "right" }}
                  onClick={handleBtnClick}
                  disabled={!validateForm()}
                >
                  Select Patient
                </Button>
              </Card.Body>
            </Card>
          </div>
        </div>
      </div>
    </>
  ) : (
    <Navigate to="/" replace />
  );
}

export default PatientEncounter;
