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

import {
  Typography,
  Button,
  Box,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  TextField,
  FormGroup,
  FormControlLabel,
  Checkbox,
  Snackbar,
  Alert,
  Tooltip,
} from "@mui/material";
import { useEffect, useState } from "react";
import Header from "../common/Header";
import { Navigate } from "react-router-dom";
import { useAuth } from "../common/AuthProvider";
import axios from "axios";
import { ORGANIZATION_SERVICE_URL } from "../../configs/Constants";
import { useDispatch, useSelector } from "react-redux";
import {
  updateRequestUrl,
  updateRequest,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";
import Profile from "../common/Profile";
import CoverageDetails from "../common/CoverageDetails";
import { updateLoggedUser, updateCoverageIds } from "../redux/loggedUserSlice";

interface Payer {
  id: number;
  name: string;
}

export const LandingPage = () => {
  const avatarUrl = "https://i.pravatar.cc/100?img=58";

  const { isAuthenticated } = useAuth();
  const [isPatientDataLoaded, setIsPatientDataLoaded] = useState(false);

  const [payerList, setPayerList] = useState<Payer[]>([]);
  const [isExchanging, setIsExchanging] = useState(false);
  const [consentAll, setConsentAll] = useState(false);
  const [coverageStartDate, setCoverageStartDate] = useState("");
  const [coverageEndDate, setCoverageEndDate] = useState("");

  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);
  const [coverageId, setCoverageId] = useState(""); // This need to be updated when multiple payer export is supported.

  const dispatch = useDispatch();

  // State to manage selected options
  const [selectedOrgId, setSelectedOrgId] = useState<number>(50);
  const Config = window.Config;
  const loggedUser = useSelector((state: any) => state.loggedUser);

  const handleCloseSnackbar = () => {
    setOpenSnackbar(false);
  };

  useEffect(() => {
    const fetchUserInfo = async () => {
      const loggedUser = await fetch("/auth/userinfo")
        .then((response) => response.json())
        .then((data) => {
          setIsPatientDataLoaded(true);
          return data;
        });

      if (loggedUser) {
        dispatch(
          updateLoggedUser({
            username: loggedUser.username,
            first_name: loggedUser.first_name,
            last_name: loggedUser.last_name,
            id: loggedUser.id,
          })
        );

        // Fetch coverage resources for the logged-in patient
        try {
          const coverageUrl = Config.fhir + "/Coverage";
          const coverageRes = await axios.get(
            `${coverageUrl}?patient=Patient/${loggedUser.id}`
          );
          const coverageIds = (coverageRes.data.entry || []).map(
            (entry: any) => entry.resource.id
          );
          dispatch(updateCoverageIds(coverageIds));
        } catch (error) {
          console.error("Error fetching coverage resources:", error);
        }
      }
    };

    fetchUserInfo();
  }, [dispatch]);

  useEffect(() => {
    const fetchOrganizations = async (): Promise<Payer[]> => {
      try {
        const response = await fetch(ORGANIZATION_SERVICE_URL);
        const data = await response.json();
        return data.entry.map((entry: any) => ({
          id: entry.resource.id,
          name: entry.resource.name,
        }));
      } catch (error) {
        console.error("Error fetching organizations:", error);
        return [];
      }
    };

    const loadOrganizations = async () => {
      const payers = await fetchOrganizations();
      setPayerList(payers);
      setSelectedOrgId(payers[0]?.id);
    };

    loadOrganizations();
  }, []);

  const selectOrgChange = (event: { target: { value: any } }) => {
    const { value } = event.target;
    setSelectedOrgId(value);
  };

  const handleConsentChange = () => {
    setConsentAll((prev) => !prev);
  };

  const handleStartDataExchange = async () => {

    if (!coverageId) {
      setAlertMessage("Previous Coverage ID cannot be empty!");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return;
    }

    if (!consentAll) {
      setAlertMessage("Please provide consent before proceeding!");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return;
    }

    if (coverageStartDate && coverageEndDate && coverageStartDate > coverageEndDate) {
      setAlertMessage("Coverage start date must be before end date.");
      setAlertSeverity("error");
      setOpenSnackbar(true);
      return;
    }

    setIsExchanging(true);

    const selectedPayer = payerList.find((p) => p.id === selectedOrgId);

    const payload = {
      memberId: loggedUser.id,
      oldPayerName: selectedPayer?.name || "",
      oldPayerId: String(selectedOrgId),
      oldCoverageId: coverageId,
      coverageStartDate: coverageStartDate || "",
      coverageEndDate: coverageEndDate || "",
      consent: "approved",
    };

    try {
      dispatch(updateRequestMethod("POST"));
      dispatch(updateRequestUrl(Config.pdexExchangeUrl));
      dispatch(updateRequest(payload));
      dispatch(resetCdsResponse());

      const response = await axios.post(Config.pdexExchangeUrl, payload, {
        headers: { "Content-Type": "application/json" },
      });

      dispatch(
        updateCdsResponse({ cards: response.data, systemActions: {} })
      );
      setAlertMessage("Data exchange initiated successfully!");
      setAlertSeverity("success");
      setOpenSnackbar(true);
    } catch (error) {
      console.error("Error:", error);
      setAlertMessage("Data exchange failed. Please retry!");
      setAlertSeverity("error");
      setOpenSnackbar(true);
    } finally {
      setIsExchanging(false);
    }
  };

  return isAuthenticated ? (
    <div
      style={{
        paddingLeft: "50px",
        paddingRight: "50px",
        paddingTop: "20px",
      }}
    >
      <Header
        userName={loggedUser.first_name}
        avatarUrl={avatarUrl}
        isLoggedIn={true}
      />
      {isPatientDataLoaded ? (
        <div>
          <Profile
            userName={loggedUser.username}
            firstName={loggedUser.first_name}
            lastName={loggedUser.last_name}
            id={loggedUser.id}
          />
          <CoverageDetails patientId={loggedUser.id} />

          <Box sx={{ mt: 4, mb: 4, ml: 2, mr: 2 }}>
            <Box>
              <Typography variant="h4">Fetch previous payer data</Typography>
              <Typography variant="h6" sx={{ mt: 2, mb: 4 }}>
                Welcome to the UnitedCare Health Member Portal. If you haven't
                yet synced your data with your previous payer, please select
                your previous payer, provide consent for the data categories
                you wish to share, and click 'Start Data Exchange' to securely
                transfer your data to UnitedCare Health.
              </Typography>
            </Box>

            <Box
              sx={{
                p: 2,
                border: "1px dashed grey",
                padding: 4,
                borderRadius: 2,
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "15px",
                  marginTop: "15px",
                }}
              >
                <FormGroup style={{ flex: "1 1 50%" }}>
                  <FormControl fullWidth variant="outlined">
                    <InputLabel id="select-payer-label">
                      Select previous payer
                    </InputLabel>
                    <Select
                      labelId="select-payer-label"
                      id="select-payer"
                      value={selectedOrgId}
                      onChange={selectOrgChange}
                      label="Select previous payer"
                    >
                      {payerList.map((payer, index) => (
                        <MenuItem key={index} value={payer.id}>
                          {payer.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </FormGroup>
                <FormGroup style={{ flex: "1 1 25%" }}>
                  <TextField
                    required
                    id="coverage-id"
                    label="Previous Coverage ID"
                    value={coverageId}
                    onChange={(e) => setCoverageId(e.target.value)}
                  />
                </FormGroup>
                <FormGroup style={{ flex: "1 1 25%" }}>
                  <TextField
                    id="coverage-start-date"
                    label="Coverage Start Date"
                    type="date"
                    value={coverageStartDate}
                    onChange={(e) => setCoverageStartDate(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </FormGroup>
                <FormGroup style={{ flex: "1 1 25%" }}>
                  <TextField
                    id="coverage-end-date"
                    label="Coverage End Date"
                    type="date"
                    value={coverageEndDate}
                    onChange={(e) => setCoverageEndDate(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </FormGroup>
              </div>

              <Box sx={{ mt: 3, mb: 2 }}>
                <Typography variant="h6">
                  Consent for Data Exchange
                </Typography>
                <Typography
                  variant="body2"
                  sx={{ mt: 1, mb: 1, color: "text.secondary" }}
                >
                  By checking the box below, you authorize UnitedCare Health to
                  request and receive your health records from your previous
                  payer. This consent is valid for one year from today. You may
                  revoke this consent at any time by contacting member services.
                </Typography>
                <FormGroup>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={consentAll}
                        onChange={handleConsentChange}
                      />
                    }
                    label="I consent to the transfer of all my health data from the selected previous payer."
                  />
                </FormGroup>
              </Box>

              <div
                style={{
                  display: "flex",
                  justifyContent: "center",
                  marginTop: "15px",
                }}
              >
                <Tooltip
                  title={
                    !consentAll
                      ? "Please provide consent before starting the data exchange"
                      : ""
                  }
                  arrow
                >
                  <span style={{ width: "100%" }}>
                    <Button
                      variant="contained"
                      color="primary"
                      onClick={handleStartDataExchange}
                      disabled={isExchanging || !consentAll}
                      style={{ height: "55px", width: "100%" }}
                    >
                      {isExchanging ? "Exchanging..." : "Start Data Exchange"}
                    </Button>
                  </span>
                </Tooltip>
              </div>
            </Box>
          </Box>
        </div>
      ) : (
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: "50vh",
          }}
        >
          <Typography variant="h6">Loading...</Typography>
        </div>
      )}
      <Snackbar
        open={openSnackbar}
        autoHideDuration={6000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
      >
        <Alert onClose={handleCloseSnackbar} severity={alertSeverity}>
          {alertMessage}
        </Alert>
      </Snackbar>
    </div>
  ) : (
    <Navigate to="/login" replace />
  );
};
