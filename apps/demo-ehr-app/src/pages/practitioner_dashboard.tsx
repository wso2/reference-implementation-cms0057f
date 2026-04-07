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

import { SERVICE_CARD_DETAILS } from "../constants/data";
import { ServiceCardListProps } from "../components/interfaces/card";
import MultiActionAreaCard from "../components/serviceCard";
import { useContext, useEffect } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { useDispatch } from "react-redux";
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
import { Box, Typography } from "@mui/material";

function ServiceCardList({ services, expanded }: ServiceCardListProps) {
  return (
    <Box
      sx={{
        display: "grid",
        gridTemplateColumns: expanded
          ? "minmax(0, 1fr)"
          : {
              xs: "minmax(0, 1fr)",
              sm: "repeat(2, minmax(0, 1fr))",
              lg: "repeat(3, minmax(0, 1fr))",
            },
        gap: { xs: 2.5, md: 3 },
        width: "100%",
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
    </Box>
  );
}

const DetailsDiv = () => {
  const dispatch = useDispatch();

  useEffect(() => {
    const savedPatientId = localStorage.getItem(SELECTED_PATIENT_ID);
    if (savedPatientId) {
      dispatch(selectPatient(savedPatientId));
    }
  }, [dispatch]);

  return (
    <Box sx={{ mb: 1 }}>
      <PatientInfo />
    </Box>
  );
};

function PractitionerDashBoard() {
  const { isAuthenticated } = useAuth();
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(resetCurrentRequest());
    dispatch(updateIsProcess(false));
    clearLocalStorageForPAPrococess();
  }, [dispatch]);

  return isAuthenticated ? (
    <Box
      component="main"
      sx={{
        width: "100%",
        maxWidth: 1180,
        mx: "auto",
        px: { xs: 2, sm: 3, md: 4 },
        pb: 6,
        pt: { xs: 1, md: 2 },
      }}
    >
      <DetailsDiv />

      <Box
        sx={{
          mb: 3,
          pb: 2.5,
          borderBottom: "1px solid",
          borderColor: "divider",
        }}
      >
        <Typography
          variant="h4"
          component="h1"
          sx={{
            fontWeight: 800,
            letterSpacing: "-0.03em",
            color: "text.primary",
            fontSize: { xs: "1.65rem", sm: "2rem" },
          }}
        >
          E-Health Services
        </Typography>
        <Typography
          variant="body1"
          color="text.secondary"
          sx={{ mt: 1, maxWidth: 640, lineHeight: 1.6 }}
        >
          Select a service to open the workflow. Your current patient context
          is shown above.
        </Typography>
      </Box>

      <ServiceCardList services={SERVICE_CARD_DETAILS} expanded={expanded} />
    </Box>
  ) : (
    <Navigate to="/" replace />
  );
}

export default PractitionerDashBoard;
