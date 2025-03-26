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

import { useSelector, useDispatch } from "react-redux";
import { PATIENT_DETAILS } from "../constants/data";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TableRow from "@mui/material/TableRow";
import Paper from "@mui/material/Paper";
import Form from "react-bootstrap/Form";
import { useEffect, useState } from "react";
import {
  updateRequestMethod,
  updateRequestUrl,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";
import axios from "axios";

function createData(
  date: string,
  disease: string,
  diagnosis: string,
  medicinePrescribed: string,
  referrals: string,
  labReports: string,
  devices: string
) {
  return {
    date,
    disease,
    diagnosis,
    medicinePrescribed,
    referrals,
    labReports,
    devices,
  };
}

const rows = [
  createData(
    "04/04/2024",
    "Seasonal Allergies",
    "Allergic Rhinitis",
    "Loratadine 10mg",
    "N/A",
    "N/A",
    "N/A"
  ),
  createData(
    "12/03/2024",
    "Headache",
    "Migraine",
    "Ibuprofen 400mg",
    "N/A",
    "N/A",
    "N/A"
  ),
  createData(
    "01/02/2024",
    "Sprained Ankle (grade 2)",
    "Confirmation of healing sprain",
    "Ibuprofen",
    "Physical therapy",
    "N/A",
    "Crutches"
  ),
];

const TableComponent = () => {
  return (
    <div style={{ marginBottom: "3vh" }}>
      <div style={{ fontSize: 24, fontWeight: 600, marginBottom: "1vh" }}>
        History
      </div>
      <TableContainer component={Paper}>
        <Table sx={{ minWidth: 650 }} aria-label="simple table">
          <TableHead style={{ backgroundColor: "#F5F5F5" }}>
            <TableRow>
              <TableCell>Date</TableCell>
              <TableCell align="right">Disease</TableCell>
              <TableCell align="right">Diagnosis</TableCell>
              <TableCell align="right">Medicine Prescribed</TableCell>
              <TableCell align="right">Referrals</TableCell>
              <TableCell align="right">Lab Reports</TableCell>
              <TableCell align="right">Devices</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => (
              <TableRow
                key={row.date}
                sx={{ "&:last-child td, &:last-child th": { border: 0 } }}
              >
                <TableCell component="th" scope="row">
                  {row.date}
                </TableCell>
                <TableCell align="right">{row.disease}</TableCell>
                <TableCell align="right">{row.diagnosis}</TableCell>
                <TableCell align="right">{row.medicinePrescribed}</TableCell>
                <TableCell align="right">{row.referrals}</TableCell>
                <TableCell align="right">{row.labReports}</TableCell>
                <TableCell align="right">{row.devices}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </div>
  );
};

export function PatientViewPage() {
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

  const dispatch = useDispatch();
  const Config = window.Config;

  interface Patient {
    resourceType: string;
    gender: string;
    telecom: Telecom[];
    id: string;
    identifier: Identifier[];
    address: Address[];
    birthDate: string;
    meta: Meta;
    name: Name[];
  }

  interface Telecom {
    system: string;
    use?: string;
    value: string;
  }

  interface Identifier {
    system: string;
    value: string;
  }

  interface Address {
    country: string;
    city: string;
    line: string[];
    postalCode: string;
    state: string;
  }

  interface Meta {
    profile: string[];
  }

  interface Name {
    given: string[];
    use: string;
    family: string;
  }

  const [fetchedPatient, setPatientDetails] = useState<Patient | null>(null);

  useEffect(() => {
    console.log("Current Patient:", currentPatient);

    const fetchPatientDetails = async () => {
      try {
        console.log("Fetching patient details...");
        dispatch(resetCdsRequest());
        dispatch(resetCdsResponse());
        const req_url = Config.patient + "/" + currentPatient.id;
        dispatch(updateRequestMethod("GET"));
        dispatch(updateRequestUrl("https://unitedcare.com/fhir/r4/Patient/" + currentPatient.id));

        axios.get(req_url).then((response) => {
          console.log("Patient details:", response.data);
          dispatch(
            updateCdsResponse({
              cards: response.data,
              systemActions: {},
            })
          );
          setPatientDetails(response.data);
        });
      } catch (error) {
        console.error("Error fetching patient details:", error);
      }
    };
    fetchPatientDetails();
  }, [currentPatient, dispatch]);

  return (
    <div className="profile-page">
      <div className="cover-photo">
        <img src="/cover.jpg" alt="Cover" />
      </div>
      <div className="profile-photo">
        <img src="/profile-patient.jpg" alt="Profile" />
      </div>
      <div className="profile-content">
        <h1>
          {currentPatient.name[0].given[0] +
            " " +
            currentPatient.name[0].family}
        </h1>
        <div>
          Last visited:{" "}
          <span style={{ color: "grey" }}>11/03/2024, Thursday, 9:30 a.m</span>
        </div>
        <hr />
        <div style={{ fontSize: 24, fontWeight: 600, marginTop: "3vh" }}>
          Personal Details
        </div>
        <div>
          <div>
            <Form>
              <div
                style={{
                  display: "flex",
                  gap: "20px",
                }}
              >
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>ID</Form.Label>
                  <Form.Control
                    type="text"
                    value={fetchedPatient?.id}
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Gender</Form.Label>
                  <Form.Control
                    type="text"
                    value={fetchedPatient?.gender.toUpperCase()}
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Birth Date</Form.Label>
                  <Form.Control
                    type="text"
                    value={fetchedPatient?.birthDate}
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Phone</Form.Label>
                  <Form.Control
                    type="text"
                    value={
                      fetchedPatient?.telecom.find(
                        (contact) => contact.system === "phone"
                      )?.value
                    }
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Email</Form.Label>
                  <Form.Control
                    type="text"
                    value={
                      fetchedPatient?.telecom.find(
                        (contact) => contact.system === "email"
                      )?.value
                    }
                    disabled
                  />
                </Form.Group>
              </div>
              <div
                style={{
                  display: "flex",
                  gap: "20px",
                }}
              >
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Address</Form.Label>
                  <Form.Control
                    type="text"
                    value={
                      fetchedPatient?.address[0].line.join(", ") +
                      ", " +
                      fetchedPatient?.address[0].city +
                      ", " +
                      fetchedPatient?.address[0].state +
                      ", " +
                      fetchedPatient?.address[0].postalCode +
                      ", " +
                      fetchedPatient?.address[0].country
                    }
                    disabled
                  />
                </Form.Group>
              </div>
            </Form>

            <hr style={{ marginTop: "50px" }} />

            <div style={{ fontSize: 24, fontWeight: 600, marginTop: "3vh" }}>
              Known Allergies
            </div>

            <Form>
              <div
                style={{
                  display: "flex",
                  gap: "20px",
                }}
              >
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Control type="text" value="Peanut Allergy" disabled />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Control
                    type="text"
                    value="Lactose Intolerant"
                    disabled
                  />
                </Form.Group>
              </div>
            </Form>
          </div>
        </div>

        <div style={{ fontSize: 24, fontWeight: 600, marginTop: "3vh" }}>
          Latest Vitals
        </div>

        <Form>
          <div
            style={{
              display: "flex",
              gap: "20px",
            }}
          >
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Blood Glucose Level</Form.Label>
              <Form.Control type="text" value="90mg/dt" disabled />
              <Form.Control
                type="text"
                value="Before meal - 11/03/2024"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Body Temperature</Form.Label>
              <Form.Control type="text" value="98.1 °F" disabled />
              <Form.Control
                type="text"
                value="Today"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Blood pressure</Form.Label>
              <Form.Control type="text" value="120/80 mm hg" disabled />
              <Form.Control
                type="text"
                value="Today"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Blood Glucose Level</Form.Label>
              <Form.Control type="text" value="120mg/dt" disabled />
              <Form.Control
                type="text"
                value="After meal - 11/03/2024"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Label>Body Weight</Form.Label>
              <Form.Control type="text" value="55kg" disabled />
              <Form.Control
                type="text"
                value="11/03/2024"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
          </div>
        </Form>

        <div style={{ fontSize: 24, fontWeight: 600, marginTop: "3vh" }}>
          Emergency Contact
        </div>

        <Form>
          <div
            style={{
              display: "flex",
              gap: "20px",
            }}
          >
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Control type="text" value="Mr. Moscow" disabled />
              <Form.Control
                type="text"
                value="Father"
                style={{ marginTop: 5 }}
              />
              <Form.Control
                type="text"
                value="+94 771231231"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Control type="text" value="Mrs. Moscow" disabled />
              <Form.Control
                type="text"
                value="Mother"
                style={{ marginTop: 5 }}
              />
              <Form.Control
                type="text"
                value="+94 771231232"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
            <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
              <Form.Control type="text" value="Mr. Elbow" disabled />
              <Form.Control
                type="text"
                value="Brother"
                style={{ marginTop: 5 }}
              />
              <Form.Control
                type="text"
                value="+94 771231233"
                style={{ marginTop: 5 }}
              />
            </Form.Group>
          </div>
        </Form>

        <div style={{ height: "4vh" }} />
        <TableComponent />
      </div>
    </div>
  );
}
