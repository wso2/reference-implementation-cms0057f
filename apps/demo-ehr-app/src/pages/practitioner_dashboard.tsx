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

import { SERVICE_CARD_DETAILS, PATIENT_DETAILS } from "../constants/data";
import { ServiceCardListProps } from "../components/interfaces/card";
import MultiActionAreaCard from "../components/serviceCard";
import { useContext, useEffect } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { useSelector, useDispatch } from "react-redux";
import { selectPatient } from "../redux/patientSlice";
import { useAuth } from "../components/AuthProvider";
import { Navigate } from "react-router-dom";
import PatientInfo from "../components/PatientInfo";
import {
  resetCurrentRequest,
  updateIsProcess,
} from "../redux/currentStateSlice";
import { SELECTED_PATIENT_ID } from "../constants/localStorageVariables";
import { clearLocalStorageForPAPrococess } from "../utils/clearLocalStorage";

function ServiceCardList({ services, expanded }: ServiceCardListProps) {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: expanded ? "repeat(1, 1fr)" : "repeat(3, 1fr)",
        gap: "20px",
      }}
    >
      {services.map((service, index) => (
        <MultiActionAreaCard
          key={index}
          serviceImagePath={service.serviceImagePath}
          serviceName={service.serviceName}
          serviceDescription={service.serviceDescription}
          path={service.path}
        />
      ))}
    </div>
  );
}

const DetailsDiv = () => {
  const dispatch = useDispatch();

  const savedPatientId = localStorage.getItem(SELECTED_PATIENT_ID);
  console.log("savedPatientId", savedPatientId);
  if (savedPatientId) {
    dispatch(selectPatient(savedPatientId));
  }

  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

  return (
    <div>
      <PatientInfo />
    </div>
  );
};

function PractitionerDashBoard() {
  const { isAuthenticated } = useAuth();
  const { expanded } = useContext(ExpandedContext);
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(resetCurrentRequest());
    dispatch(updateIsProcess(false));
    clearLocalStorageForPAPrococess();
  }, []);

  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

  const handleSmartLaunch = async () => {
    const iss = window.Config.fhirServerUrl;
    const aud = window.Config.smartAppUrl;
    const patientId = localStorage.getItem(SELECTED_PATIENT_ID) ?? "";

    const response = await fetch(
      window.Config.smartLaunchServiceUrl,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ aud, patientId }),
      }
    );

    if (!response.ok) {
      console.error("Failed to create SMART launch context");
      return;
    }

    const { launchId } = await response.json();
    const issEncoded = encodeURIComponent(iss);
    window.open(
      `${window.Config.smartAppUrl}?launch=${launchId}&iss=${issEncoded}`,
      "_blank"
    );
  };

  return isAuthenticated ? (
    <div style={{ marginLeft: 50, marginBottom: 50 }}>
      <DetailsDiv />
      <div
        style={{
          display: "flex",
          flexDirection: expanded ? "column" : "row",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      ></div>
      <br />
      <div className="page-heading" style={{ marginTop: "10px" }}>
        E-Health Services
      </div>
      <div style={{ marginBottom: "40px" }}>
        <ServiceCardList services={SERVICE_CARD_DETAILS} expanded={expanded} />
      </div>
      <div className="page-heading" style={{ marginTop: "10px" }}>
        SMART App Launch
      </div>
      <div>
        <MultiActionAreaCard
          serviceImagePath="/encounter_start.png"
          serviceName="Diagnostic Reports Viewer"
          serviceDescription="Launch a SMART on FHIR application in the context of this EHR session."
          path=""
          onClick={handleSmartLaunch}
        />
      </div>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}

export default PractitionerDashBoard;
