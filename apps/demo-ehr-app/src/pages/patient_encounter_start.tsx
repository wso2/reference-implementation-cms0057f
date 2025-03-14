// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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
import Button from "@mui/material/Button";
import Box from "@mui/material/Box";
import InputLabel from "@mui/material/InputLabel";
import MenuItem from "@mui/material/MenuItem";
import FormControl from "@mui/material/FormControl";
import Select, { SelectChangeEvent } from "@mui/material/Select";
import { SCREEN_WIDTH, SCREEN_HEIGHT } from "../constants/page";
import { PATIENT_DETAILS } from "../constants/data";
import { useDispatch } from "react-redux";
import { selectPatient } from "../redux/patientSlice";
import { Navigate, useNavigate } from "react-router-dom";
import NavBar from "../components/nav_bar";
import { useAuth } from "../components/AuthProvider";

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

  const handleChange = (event: SelectChangeEvent) => {
    setSelectedPatient(event.target.value);
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
        <div style={{ display: "flex" }}>
          <div>
            <img
              src="/encounter_start.png"
              alt="Healthcare"
              style={{ width: SCREEN_WIDTH / 2 }}
            />
          </div>
          <div
            style={{
              marginLeft: SCREEN_WIDTH * 0.06,
              marginTop: SCREEN_HEIGHT * 0.12,
            }}
          >
            <div style={{ marginBottom: 0, fontSize: 48, fontWeight: 600 }}>
              Welcome to Your
            </div>
            <div style={{ marginTop: -10, fontSize: 48, fontWeight: 600 }}>
              Healthcare HQ
            </div>
            <div style={{ height: SCREEN_HEIGHT * 0.065 }} />
            <Box
              sx={{
                width: SCREEN_WIDTH * 0.25,
                minWidth: 100,
                marginLeft: SCREEN_WIDTH * 0.002,
              }}
            >
              <FormControl fullWidth>
                <InputLabel id="demo-simple-select-label">Patient</InputLabel>
                <Select
                  labelId="demo-simple-select-label"
                  id="demo-simple-select"
                  value={selectedPatient}
                  label="Patient"
                  onChange={handleChange}
                >
                  {Object.entries(patients).map(([key, value]) => (
                    <MenuItem key={key} value={key}>
                      {value}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Box>
            <Button
              variant="contained"
              style={{
                marginLeft: SCREEN_WIDTH * 0.16,
                marginTop: SCREEN_HEIGHT * 0.03,
                borderRadius: "50px",
              }}
              onClick={handleBtnClick}
            >
              Treat Patient
            </Button>
          </div>
        </div>
      </div>
    </>
  ) : (
    <Navigate to="/" replace />
  );
}

export default PatientEncounter;
