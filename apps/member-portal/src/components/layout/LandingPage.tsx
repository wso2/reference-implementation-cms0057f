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
  LinearProgress,
  FormGroup,
  Snackbar,
  Alert,
} from "@mui/material";
import { useEffect, useState } from "react";
import Header from "../common/Header";
import { Navigate } from "react-router-dom";
import { useAuth } from "../common/AuthProvider";
import axios from "axios";
import {
  BULK_EXPORT_KICKOFF_URL,
  ORGANIZATION_SERVICE_URL,
} from "../../configs/Constants";
import { useDispatch, useSelector } from "react-redux";
import {
  updateRequestUrl,
  updateRequest,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";
import Profile from "../common/Profile";
import { updateLoggedUser } from "../redux/loggedUserSlice";
import { memberMatchPayload } from "../constants/data";

interface Payer {
  id: number;
  name: string;
}

export const LandingPage = () => {
  const avatarUrl = "https://i.pravatar.cc/100?img=58";

  const { isAuthenticated } = useAuth();
  const [isPatientDataLoaded, setIsPatientDataLoaded] = useState(false);

  const [exportButtonLabel, setExportButtonLabel] = useState("Export");
  const [payerList, setPayerList] = useState<Payer[]>([]);
  const [oldMemberId, setOldMemberId] = useState("");
  const [exportId, setExportId] = useState("");

  const [error, setError] = useState("");
  const [isExporting, setIsExporting] = useState(false);
  const [exportPercentage, setExportPercentage] = useState("0");
  const [isExportCompleted, setIsExportCompleted] = useState(false);
  const [status, setStatus] = useState("Member Not Resolved.");

  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [alertSeverity, setAlertSeverity] = useState<
    "error" | "warning" | "info" | "success"
  >("info");
  const [openSnackbar, setOpenSnackbar] = useState(false);

  const dispatch = useDispatch();

  // State to manage selected options
  const [selectedOrgId, setSelectedOrgId] = useState<number | null>(null);
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
      setSelectedOrgId(payers[0]?.id || null);
    };

    loadOrganizations();
  }, []);

  const selectOrgChange = (event: { target: { value: any } }) => {
    const { value } = event.target;
    setSelectedOrgId(value);
  };

  const handleFetchMemberID = () => {
    setOldMemberId("");
    setExportButtonLabel("Export");
    setIsExportCompleted(false);
    handleMemberMatch();
  };

  const handleMemberMatch = () => {
    setStatus("Matching Member ID...");
    const payload = memberMatchPayload;

    const coverageId = (
      document.getElementById("coverage-id") as HTMLInputElement
    )?.value;

    if (!coverageId) {
      setAlertMessage("Coverage ID cannot be empty!");
      setAlertSeverity("error");
      setStatus("Member Not Resolved.");
      setOpenSnackbar(true);
      return;
    }

    try {
      axios
        .get(
          Config.oldPayerCoverageGet + "/" + selectedOrgId + "/" + coverageId
        )
        .then((res) => {
          if (res.status >= 200 && res.status < 300) {
            const coverageResource = res.data;

            // Replace coverage resource in payload
            payload.parameter = payload.parameter.map((param: any) => {
              if (param.name === "CoverageToLink") {
                return {
                  ...param,
                  resource: coverageResource,
                };
              }
              return param;
            });

            // Replace patient resource in payload
            const patientResource = JSON.parse(
              localStorage.getItem("patientResource") || "{}"
            );
            payload.parameter = payload.parameter.map((param: any) => {
              if (param.name === "MemberPatient") {
                return {
                  ...param,
                  resource: patientResource,
                };
              }
              return param;
            });

            dispatch(updateRequestMethod("POST"));
            dispatch(updateRequestUrl("/member-service/v1.0/match"));
            dispatch(updateRequest(payload));
            dispatch(resetCdsResponse());

            axios
              .post(Config.memberMatch, payload, {
                headers: {
                  "Content-Type": "application/fhir+json",
                },
              })
              .then((response) => {
                dispatch(
                  updateCdsResponse({
                    cards: response.data,
                    systemActions: {},
                  })
                );
                if (response.status === 201) {
                  setOldMemberId(
                    response.data?.parameter?.valueIdentifier?.value
                  );
                  setError("");
                  setStatus("Ready to Export.");
                } else {
                  setError("Match failed. Please retry");
                  setAlertMessage("Match failed. Please retry!");
                  setAlertSeverity("error");
                  setOpenSnackbar(true);
                }
              })
              .catch((error) => {
                console.error("Error:", error);
                setError("Match failed. Please retry");
                setStatus("Member Not Resoved.");
                setAlertMessage("Match failed. Please retry!");
                setAlertSeverity("error");
                setOpenSnackbar(true);
              })
          } else {
            console.error("Error fetching coverage:", res);
            setAlertMessage("Error fetching coverage!");
            setAlertSeverity("error");
            setOpenSnackbar(true);
          }
        })
        .catch((err) => {
          console.log("Error fetching coverage:", err);
          setAlertMessage("Error fetching coverage!");
          setAlertSeverity("error");
          setOpenSnackbar(true);
        });
    } catch (error) {
      console.error("Error:", error);
      setAlertMessage("Error fetching coverage!");
      setAlertSeverity("error");
      setOpenSnackbar(true);
    }
  };

  const handleSubmit = (e: { preventDefault: () => void }) => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());

    e.preventDefault();
    setExportButtonLabel("Exporting...");
    setStatus("Exporting...");

    setIsExporting(true);

    const postOrganizationId = async () => {
      const memberID = oldMemberId;
      const payload = [{ id: memberID }];
      dispatch(updateRequestMethod("POST"));
      dispatch(updateRequestUrl("/bulk-export-client/v1.0/export"));
      dispatch(updateRequest({ id: memberID }));

      try {
        const response = await axios.post(BULK_EXPORT_KICKOFF_URL, payload, {
          headers: {
            "Content-Type": "application/json",
          },
        });
        dispatch(
          updateCdsResponse({
            cards: response.data,
            systemActions: {},
          })
        );

        const diagnostics: string = response.data.issue?.[0]?.diagnostics || "";
        const match = diagnostics.match(/ExportId:\s([\w-]+)/);
        if (match && match[1]) {
          setExportId(match[1]);
          localStorage.setItem("exportId", match[1]);
          checkStatusUntilDownloaded(match[1]);
        } else {
          console.warn("Export ID not found in diagnostics message.");
        }
      } catch (error) {
        console.error("Error posting data:", error);
      }
    };

    const checkStatusUntilDownloaded = async (exportId: string) => {
      const interval = setInterval(async () => {
        try {
          const response = await axios.get(Config.bulkExportStatusUrl, {
            params: { exportId: exportId },
          });
          const currentStatus = response.data.lastStatus;

          setStatus(currentStatus);

          if (currentStatus === "Downloaded") {
            clearInterval(interval);
            setStatus("Export Completed.");
            setIsExportCompleted(true);
            setExportPercentage("100");
            setIsExporting(false);
          }
        } catch (error) {
          console.error("Error checking status:", error);
        }
      }, 300); // Check every 0.3 seconds
    };

    postOrganizationId();
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

          <Box sx={{ mt: 4, mb: 4, ml: 2, mr: 2 }}>
            <Box>
              <Typography variant="h4">Fetch previous payer data</Typography>
              <Typography variant="h6" sx={{ mt: 2, mb: 4 }}>
                Welcome to the UnitedCare Health Member Portal. If you haven't yet
                synced your data with your previous, please select your previous
                payer(s) and click 'Export' to securely transfer your data to
                UnitedCare Health. The transfer will run in the background, and you will
                be notified once the process is complete.
              </Typography>
            </Box>

            <Box
              component="form"
              onSubmit={handleSubmit}
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
                <FormGroup style={{ flex: "1 1 70%" }}>
                  <FormControl fullWidth variant="outlined">
                    <InputLabel id="select-payer-label">
                      Select old payer to fetch Member ID
                    </InputLabel>
                    <Select
                      labelId="select-payer-label"
                      id="select-payer"
                      value={selectedOrgId}
                      onChange={selectOrgChange}
                      label="Select old payer to fetch Member ID"
                    >
                      {payerList.map((payer, index) => (
                        <MenuItem key={index} value={payer.id}>
                          {payer.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </FormGroup>
                <FormGroup style={{ flex: "1 1 30%" }}>
                  <TextField
                    required
                    id="coverage-id"
                    label="Coverage ID"
                    defaultValue="367"
                  ></TextField>
                </FormGroup>
              </div>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "15px",
                  marginTop: "15px",
                }}
              >
                <FormGroup style={{ flex: "1 1 70%" }}>
                  <TextField
                    required
                    id="member-id"
                    label="Member ID"
                    value={oldMemberId}
                    aria-readonly
                  ></TextField>
                </FormGroup>
                <Button
                  variant="contained"
                  style={{ height: "55px" }}
                  color="primary"
                  onClick={handleFetchMemberID}
                >
                  Fetch Member ID
                </Button>
              </div>

              <Box
                sx={{
                  mt: 2,
                  mb: 4,
                  border: "1px solid lightGrey",
                  padding: 2,
                  borderRadius: 1,
                }}
              >
                <Typography variant="h5">Status: {status}</Typography>
                <Box sx={{ display: "flex", alignItems: "center" }}>
                  <Box sx={{ width: "100%", mt: 2, height: 6 }}>
                    <LinearProgress
                      variant="determinate"
                      value={+exportPercentage}
                    />
                  </Box>
                  <Box sx={{ minWidth: 40, paddingLeft: 2, height: 10 }}>
                    <Typography
                      variant="body2"
                      sx={{ color: "text.secondary" }}
                    >{`${Math.round(+exportPercentage)}%`}</Typography>
                  </Box>
                </Box>
                {isExportCompleted && (
                  <Typography variant="body1" sx={{ mt: 2, color: "black" }}>
                    Export ID: {exportId}
                  </Typography>
                )}
              </Box>
              <div
                style={{
                  display: "flex",
                  justifyContent: "center",
                  gap: "15px",
                  marginTop: "15px",
                }}
              >
                {isExportCompleted ? (
                  <>
                    <Button
                      variant="contained"
                      color="primary"
                      onClick={() => window.open("/exported-data", "_blank")}
                      // sx={{ mt: 2 }}
                      style={{ height: "55px", width: "100%" }}
                    >
                      View Exported Data
                    </Button>
                  </>
                ) : (
                  <>
                    <Button
                      variant="contained"
                      color="primary"
                      onClick={handleSubmit}
                      disabled={
                        isExporting || error != "" || oldMemberId === ""
                      }
                      style={{ height: "55px", width: "100%" }}
                    >
                      {exportButtonLabel}
                    </Button>
                  </>
                )}
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
