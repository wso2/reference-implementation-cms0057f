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

import { useState, useMemo } from "react";
import { useDispatch } from "react-redux";
import { selectPatient } from "../redux/patientSlice";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../components/AuthProvider";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Select, { SingleValue } from "react-select";
import Button from "react-bootstrap/Button";
import { useEffect } from "react";
import axios from "axios";
import {
  resetCurrentRequest,
  updateCurrentRequestMethod,
  updateCurrentRequestUrl,
  updateCurrentResponse,
} from "../redux/currentStateSlice";
import {
  SELECTED_PATIENT_ID,
  SELECTED_PATIENT_NAME,
} from "../constants/localStorageVariables";
import { clearLocalStorageForPAPrococess, clearLocalStorageFully } from "../utils/clearLocalStorage";
import { HTTP_METHODS } from "../constants/enum";

function PatientEncounter() {
  const { isAuthenticated } = useAuth();
  const [selectedPatient, setSelectedPatient] = useState("");
  const [isLoaded, setIsLoaded] = useState(false);
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const Config = window.Config;
  const patients = useMemo<{ [key: string]: { fullName: string } }>(
    () => ({}),
    []
  );

  useEffect(() => {
    const fetchPatientDetails = async () => {
      dispatch(resetCurrentRequest());
      dispatch(updateCurrentRequestMethod(HTTP_METHODS.GET));
      dispatch(
        updateCurrentRequestUrl(Config.demoHospitalUrl + Config.patient)
      );
      try {
        const response = await axios.get(Config.patient);
        dispatch(updateCurrentResponse(response.data));
        const patientData = response.data.entry;
        console.log("Patients: ", patients);
        patientData.forEach((patient: any) => {
          patients[patient.resource.id] = {
            fullName:
              patient.resource.name[0].given[0] +
              " " +
              patient.resource.name[0].family,
          };
        });
        console.log("Patients: ", patients);
        setIsLoaded(true);
      } catch (error) {
        console.error("Error fetching patient details:", error);
        clearLocalStorageFully();
        navigate("/login");
      }
    };

    clearLocalStorageForPAPrococess();
    fetchPatientDetails();
  }, [Config, patients, dispatch]);

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

  const handleBtnClick = async () => {
    dispatch(selectPatient(selectedPatient));
    localStorage.setItem(SELECTED_PATIENT_ID, selectedPatient);
    localStorage.setItem(
      SELECTED_PATIENT_NAME,
      patients[selectedPatient].fullName
    );
    const loggedUser = await fetch("/auth/userinfo").then((response) =>
      response.json()
    );
    localStorage.setItem("loggedUser", JSON.stringify(loggedUser));
    navigate("dashboard");
  };

  return isAuthenticated ? (
    <>
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
              {!isLoaded ? (
                <div>Loading...</div>
              ) : (
                <Form.Group
                  controlId="formTreatingSickness"
                  style={{ marginTop: "20px" }}
                >
                  <Form.Label>
                    Patient Name <span style={{ color: "red" }}>*</span>
                  </Form.Label>
                  <Select
                    name="treatingSickness"
                    options={Object.keys(patients).map((id) => ({
                      value: id,
                      label: patients[id].fullName,
                    }))}
                    isSearchable
                    onChange={handleSelectChange}
                    required
                  />
                </Form.Group>
              )}
              <Button
                variant="success"
                style={{
                  marginLeft: "30px",
                  marginTop: "30px",
                  float: "right",
                }}
                onClick={handleBtnClick}
                disabled={!validateForm()}
              >
                Select Patient
              </Button>
            </Card.Body>
          </Card>
        </div>
      </div>
    </>
  ) : (
    <Navigate to="/" replace />
  );
}

export default PatientEncounter;
