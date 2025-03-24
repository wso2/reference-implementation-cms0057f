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

import Button from "react-bootstrap/Button";
import { PATIENT_DETAILS } from "../constants/data";

function LoginV2() {
  const patients: { [key: string]: string } = {};

  PATIENT_DETAILS.forEach((patient) => {
    const fullName = patient.name[0].given[0] + " " + patient.name[0].family;
    patients[patient.id] = fullName;
  });

  return (
    <div>
      <div
        style={{
          backgroundImage: `url('/background-gray-med.svg')`,
          backgroundSize: "cover",
          height: "100vh",
          width: "100vw",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: "100%",
            fontSize: "3rem",
            backgroundColor: "rgba(255, 255, 255, 0.8)",
          }}
        >
          <div
            style={{
              textAlign: "center",
              padding: "20px",
              display: "flex",
              flexDirection: "column",
              justifyContent: "center",
              alignItems: "center",
            }}
          >
            <img
              src="/welcome-img.svg"
              alt="Doctor"
              style={{ width: "300px", marginBottom: "20px" }}
            />
            <h1 style={{ color: "#4C585B" }}>Welcome</h1>
            <p style={{ color: "#4C585B" }}>to your Healthcare HQ</p>
            <Button
              variant="success"
              style={{
                paddingLeft: "50px",
                paddingRight: "50px",
                marginTop: "20px",
                fontSize: "1.5rem",
              }}
              onClick={() => {
                window.location.href = "/auth/login";
              }}
            >
              Sign In
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default LoginV2;
