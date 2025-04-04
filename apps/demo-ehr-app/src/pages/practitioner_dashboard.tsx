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

  const savedPatientId = localStorage.getItem("selectedPatientId");
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
  }, []);

  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

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
      <div style={{ height: "5vh" }}>
        <ServiceCardList services={SERVICE_CARD_DETAILS} expanded={expanded} />
      </div>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}

export default PractitionerDashBoard;
