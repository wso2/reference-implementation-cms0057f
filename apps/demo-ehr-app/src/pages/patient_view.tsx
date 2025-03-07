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

import { useSelector } from "react-redux";
import { PATIENT_DETAILS, VITALS, EMERGENCY_CONTACTS } from "../constants/data";
import { SCREEN_WIDTH } from "../constants/page";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TableRow from "@mui/material/TableRow";
import Paper from "@mui/material/Paper";

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
    <TableContainer component={Paper}>
      <Table sx={{ minWidth: 650 }} aria-label="simple table">
        <TableHead>
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

  const age =
    new Date().getFullYear() - new Date(currentPatient.birthDate).getFullYear();

  return (
    <div style={{ marginLeft: "2vw" }}>
      <div style={{ display: "flex", flexDirection: "row" }}>
        <div>
          <div style={{ display: "flex", flexDirection: "row" }}>
            <img
              src="/patient_img.png"
              alt="Patient"
              style={{ width: "10vw", height: "auto" }}
            />
            <div style={{ width: "5vw" }} />
            <div>
              <div style={{ fontSize: 30, fontWeight: 800 }}>
                {currentPatient.name[0].given[0] +
                  " " +
                  currentPatient.name[0].family}
              </div>
              <div style={{ display: "flex", flexDirection: "row" }}>
                <div>{currentPatient.gender.toUpperCase()}</div>
                <div style={{ width: "5vw" }} />
                <div>Age: {age}</div>
              </div>
              <div style={{ height: "1vh" }} />
              <div style={{ color: "#5F79FF", fontSize: 16 }}>
                +94 773213213
              </div>
              <div style={{ color: "#5F79FF", fontSize: 16 }}>
                {currentPatient.name[0].given[0].toLocaleLowerCase()}
                @gmail.com
              </div>
            </div>
          </div>
          <div
            style={{ display: "flex", flexDirection: "row", color: "#939191" }}
          >
            <div>Last visited</div>
            <div style={{ width: "2vw" }} />
            <div>11/03/2024, Thursday, 9:30 a.m</div>
          </div>

          <div style={{ height: "2vh" }} />

          <div style={{ fontSize: 24, fontWeight: 600 }}>Known Allergies</div>

          <div
            style={{
              display: "flex",
              flexDirection: "row",
              gap: "10px",
              marginTop: "10px",
            }}
          >
            <div
              style={{
                height: "5vh",
                width: "9vw",
                backgroundColor: "#BED7DC",
                textAlign: "center",
                borderRadius: "10px",
                fontSize: 16,
              }}
            >
              Peanut Allergy
            </div>
            <div
              style={{
                height: "5vh",
                width: "11vw",
                backgroundColor: "#BED7DC",
                textAlign: "center",
                borderRadius: "10px",
                fontSize: 16,
              }}
            >
              Lactose Intolerant
            </div>
          </div>
        </div>

        <div style={{ marginLeft: "8vw" }}>
          <div style={{ fontSize: 24, fontWeight: 800 }}>Latest Vitals</div>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(3, 1fr)",
              gap: "50px",
              marginRight: 0,
            }}
          >
            {VITALS.map((item) => (
              <div>
                <div>{item.first}</div>
                <div>{item.second}</div>
                <div>{item.third}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ fontSize: 24, fontWeight: 600, marginTop: "1vh" }}>
        Emergency Contact
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          width: SCREEN_WIDTH / 2,
          marginLeft: "-2vw",
        }}
      >
        {EMERGENCY_CONTACTS.map((item) => (
          <div
            style={{
              height: "16vh",
              width: "15vw",
              borderStyle: "solid",
              borderRadius: "10px",
              marginLeft: "2vw",
            }}
          >
            <div style={{ marginLeft: "20px" }}>{item.name}</div>
            <div style={{ marginLeft: "20px" }}>{item.relationship}</div>
            <div style={{ marginLeft: "20px" }}>{item.phone}</div>
          </div>
        ))}
      </div>

      <div style={{ height: "4vh" }} />
      <TableComponent />
    </div>
  );
}
