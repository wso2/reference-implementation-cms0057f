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

import axios from "axios";
import { useEffect, useState } from "react";
import {
  Button,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableContainer,
  TableBody,
  Paper,
} from "@mui/material";
import Form from "react-bootstrap/Form";
import Select, { SingleValue } from "react-select";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import React from "react";
import { useDispatch } from "react-redux";
import {
  resetCurrentRequest,
  updateCurrentRequest,
  updateCurrentRequestMethod,
  updateCurrentRequestUrl,
  updateCurrentResponse,
} from "../redux/currentStateSlice";
import { HTTP_METHODS } from "../constants/enum";
import { SELECTED_PATIENT_ID } from "../constants/localStorageVariables";
import { resetCdsResponse } from "../redux/cdsResponseSlice";
import { ThreeDots } from "react-loader-spinner";
import PatientInfo from "../components/PatientInfo";

export const PatientHistoryPage = () => {
  const [currentType, setType] = React.useState("");
  const [parsedData, setParsedData] = useState<any[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);
  const [openSnackbar, setOpenSnackbar] = useState(false);
  const [alertMessage, setAlertMessage] = useState<string | null>(null);
  const [fetchedExportId, setExportId] = useState<string | null>(null);
  const [isExportCompleted, setIsExportCompleted] = useState(false);
  const [loadingMessage, setLoadingMessage] = useState(
    "Select a type to load data"
  );

  const Config = window.Config;
  const dispatch = useDispatch();

  const OPTIONS = [
    {
      label: "Encounter History",
      value: "Encounter",
    },
    {
      label: "Diagnostic Reports",
      value: "DiagnosticReport",
    },
  ];

  const simpleMappings: {
    [key: string]: { tableHeadings: string[]; tableData: string[] };
  } = {
    Encounter: {
      tableHeadings: [
        "Clinician",
        "Hospital",
        "Encounter Started At",
        "Encounter Finished At",
        "Status",
      ],
      tableData: [
        "participant[0].individual.display",
        "serviceProvider.display",
        "period.start",
        "period.end",
        "status",
      ],
    },
    DiagnosticReport: {
      tableHeadings: [
        "Category",
        "Test Name",
        "Performed On",
        "Report Issued On",
        "Test Result(s)",
        "Status",
      ],
      tableData: [
        "category[0].coding[0].display",
        "code.text",
        "effectiveDateTime",
        "issued",
        "result[0].display",
        "status",
      ],
    },
  };

  const currentPatientId = localStorage.getItem(SELECTED_PATIENT_ID);

  useEffect(() => {
    const fetchPatientDetails = async () => {
      try {
        setLoadingMessage("Loading patient details");
        dispatch(resetCurrentRequest());
        const req_url = Config.patient + "/" + currentPatientId;
        dispatch(updateCurrentRequestMethod(HTTP_METHODS.GET));
        dispatch(updateCurrentRequestUrl(Config.demoHospitalUrl + req_url));

        axios.get(req_url).then((response) => {
          dispatch(
            updateCurrentResponse({
              cards: response.data,
              systemActions: {},
            })
          );
          setLoadingMessage("Getting member ID");
          const fetchedPatient_ = response.data;
          const memberId = fetchedPatient_?.identifier?.find(
            (id: { system: string; }) => id.system === "urn:oid:wso2.healthcare.payer.memberID"
          )?.value;
          console.log("MemberId : ", memberId);
          fetchExportId(memberId);
        });
      } catch (error) {
        console.error("Error fetching patient details:", error);
      }
    };
    fetchPatientDetails();
  }, []);

  const fetchExportId = (memberID: string | undefined) => {
    if (!memberID) {
      console.warn("Member ID is null or undefined.");
      return;
    }

    setIsExportCompleted(false);
    setLoadingMessage("Fetching export ID");

    const postOrganizationId = async () => {
      const payload = [{ id: memberID }];
      dispatch(resetCurrentRequest());
      dispatch(resetCdsResponse());
      dispatch(updateCurrentRequestMethod(HTTP_METHODS.POST));
      dispatch(updateCurrentRequestUrl("/bulk-export-client/v1.0/export"));
      dispatch(updateCurrentRequest({ id: memberID }));

      try {
        const response = await axios.post(
          Config.bulkExportKickoffUrl,
          payload,
          {
            headers: {
              "Content-Type": "application/json",
            },
          }
        );
        dispatch(
          updateCurrentResponse({
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
      setLoadingMessage("Please wait for exported data to be fetched");
      const interval = setInterval(async () => {
        try {
          const response = await axios.get(Config.bulkExportStatusUrl, {
            params: { exportId: exportId },
          });
          const currentStatus = response.data.lastStatus;

          if (currentStatus === "Downloaded") {
            console.log("Export completed successfully.");
            clearInterval(interval);
            setIsExportCompleted(true);
            setLoadingMessage(
              "Export completed successfully. Select a type to load data."
            );
          }
        } catch (error) {
          console.error("Error checking status:", error);
        }
      }, 10000); // Check every 1 second
      // setTimeout(() => {
      //   clearInterval(interval);
      // }, 30000); // Stop checking after 30 seconds
    };

    postOrganizationId();
  };

  const handleTypeChange = (
    selectedOption: SingleValue<{ value: string | null }>
  ) => {
    setLoadingMessage("Loading, please wait...");
    if (selectedOption && selectedOption.value) {
      setType(selectedOption.value);
      fetchDataAndParse(selectedOption.value);
    }
  };

  function fetchDataAndParse(resource: string) {
    setIsLoaded(false);
    const fallbackExportID = "";
    console.log("Fetched Export ID:", fetchedExportId);

    const exportId =
      fetchedExportId && fetchedExportId.length > 0
        ? fetchedExportId
        : fallbackExportID;

    dispatch(resetCurrentRequest());
    dispatch(updateCurrentRequestMethod(HTTP_METHODS.GET));
    dispatch(
      updateCurrentRequestUrl(
        "/bulk-export-client/file-service/v1.0/fetch" +
          "?exportId=" +
          exportId +
          "&resourceType=" +
          resource
      )
    );

    axios
      .get(Config.bulkExportFetch, {
        params: {
          exportId: exportId,
          resourceType: resource,
        },
      })
      .then((response) => {

        if (typeof response.data === "string") {
          const newData = response.data.split("\n");
          dispatch(updateCurrentResponse(newData));

          const jsonData = newData
            .filter((row: string) => {
              try {
                JSON.parse(row);
                return true;
              } catch {
                return false;
              }
            })
            .map((row: string) => JSON.parse(row));
          setParsedData(jsonData);
          setIsLoaded(true);
        } else {
          console.log("Data is not a string");
          dispatch(updateCurrentResponse(response.data));
          setParsedData([response.data]);
          setIsLoaded(true);
        }
      })
      .catch((error) => {
        console.log("error", error);
      });
  }

  function MappedTable({ type }: { type: string }) {
    return (
      <div style={{ marginTop: "30px", marginBottom: "20px" }}>
        <TableContainer component={Paper}>
          <Table sx={{ minWidth: 650 }} size="small" aria-label="a dense table">
            <TableHead>
              <TableRow style={{ backgroundColor: "lightgrey" }}>
                {simpleMappings[type]?.tableHeadings.map((heading, index) => (
                  <TableCell key={index}>{heading}</TableCell>
                ))}
                <TableCell>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {parsedData.map((row, rowIndex) => (
                <TableRow key={rowIndex}>
                  {simpleMappings[type].tableData.map((dataPath, index) => (
                    <TableCell key={index}>
                      {(() => {
                        const value = dataPath
                          .split(".")
                          .reduce((acc, part) => {
                            if (!acc || typeof acc !== "object")
                              return undefined;
                            if (part.includes("[") && part.includes("]")) {
                              const [arrayPart, indexPart] = part
                                .split(/[[\]]/)
                                .filter(Boolean);
                              return (
                                acc[arrayPart] &&
                                acc[arrayPart][parseInt(indexPart, 10)]
                              );
                            }
                            return acc[part];
                          }, row);

                        if (
                          typeof value === "string" &&
                          !isNaN(Date.parse(value))
                        ) {
                          return new Date(value).toLocaleString();
                        }

                        return value;
                      })()}
                    </TableCell>
                  ))}
                  <TableCell>
                    <Button
                      variant="outlined"
                      onClick={() => {
                        setAlertMessage(JSON.stringify(row, null, 2));
                        setOpenSnackbar(true);
                      }}
                    >
                      View
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </div>
    );
  }

  function SimpleTable() {
    return <MappedTable type={currentType} />;
  }

  function TableTabs() {
    return (
      <div
        style={{
          marginTop: "10px",
          display: "flex",
          justifyContent: "space-between",
        }}
      >
        <div style={{ flex: 1 }}>
          {/* <ToggleButtonGroup
            color="primary"
            value={currentType}
            exclusive
            onChange={handleTypeChange}
            aria-label="Platform"
            fullWidth
          >
            <ToggleButton value="Encounter">Encounters</ToggleButton>
            <ToggleButton value="DiagnosticReport">
              Diagnostic Reports
            </ToggleButton>
          </ToggleButtonGroup> */}
          <Form>
            <Form.Group>
              <Select
                name="treatingSickness"
                options={OPTIONS}
                value={OPTIONS.find((option) => option.value === currentType)}
                isSearchable
                onChange={handleTypeChange}
                required
              />
            </Form.Group>
          </Form>
        </div>
      </div>
    );
  }

  return (
    <div style={{ marginLeft: "50px" }}>
      <h4>Patient History Records</h4>
      <PatientInfo />

      {alertMessage && openSnackbar ? (
        <div
          style={{
            position: "fixed",
            top: "50%",
            left: "50%",
            borderRadius: "10px",
            transform: "translate(-50%, -50%)",
            backgroundColor: "white",
            padding: "10px",
            boxShadow: "0px 0px 10px rgba(0, 0, 0, 0.1)",
            zIndex: 1000,
          }}
        >
          <div style={{ borderRadius: "10px", maxHeight: "80vh" }}>
            <SyntaxHighlighter
              language="json"
              showLineNumbers={false}
              customStyle={{
                maxHeight: "70vh",
                maxWidth: "70vw",
                overflow: "auto",
              }}
            >
              {alertMessage || ""}
            </SyntaxHighlighter>
          </div>
          <Button
            variant="contained"
            onClick={() => setAlertMessage(null)}
            style={{ float: "right", marginTop: "5px" }}
          >
            Close
          </Button>
        </div>
      ) : !isExportCompleted ? (
        <div
          style={{
            marginTop: "10px",
            textAlign: "center",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            height: "50vh",
          }}
        >
          <div style={{ paddingRight: 20 }}>{loadingMessage}</div>
          <ThreeDots
            visible={true}
            height="30"
            width="50"
            color="#4fa94d"
            radius="9"
            ariaLabel="three-dots-loading"
            wrapperStyle={{}}
            wrapperClass=""
          />
        </div>
      ) : isLoaded && isExportCompleted ? (
        <>
          <div style={{ marginTop: 20 }}>Select record type</div>
          <TableTabs />
          <SimpleTable />
        </>
      ) : (
        <>
          <div style={{ marginTop: 20 }}>Select record type</div>
          <TableTabs />
          <div
            style={{
              marginTop: "10px",
              textAlign: "center",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              height: "50vh",
            }}
          >
            {loadingMessage}
          </div>
        </>
      )}
    </div>
  );
};
