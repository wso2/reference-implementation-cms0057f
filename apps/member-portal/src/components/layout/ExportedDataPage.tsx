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

import axios from "axios";
import { useState } from "react";
import {
  Button,
  ToggleButtonGroup,
  ToggleButton,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableContainer,
  TableBody,
  Paper,
} from "@mui/material";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import React from "react";
import { useDispatch } from "react-redux";
import {
  updateRequestUrl,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";

export const ExportedDataPage = () => {
  const [currentType, setType] = React.useState("");
  const [view, setView] = React.useState("Simple");
  const [parsedData, setParsedData] = useState<any[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);
  const [parsedDataKeys, setParsedDataKeys] = useState<string[]>([]);
  const [openSnackbar, setOpenSnackbar] = useState(false);
  const [alertMessage, setAlertMessage] = useState<string | null>(null);

  const Config = window.Config;
  const savedExportId = localStorage.getItem("exportId");
  console.log("Saved exportId: ", savedExportId);
  const dispatch = useDispatch();

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
    Claim: {
      tableHeadings: [
        "Payer",
        "Claim Type",
        "Cause",
        "Hospital",
        "Billing Start Date:Time",
        "Billing End Date:Time",
        "Amount",
        "Currency",
        "Status",
      ],
      tableData: [
        "insurance[0].coverage.display",
        "type.coding[0].code",
        "item[0].productOrService.text",
        "provider.display",
        "billablePeriod.start",
        "billablePeriod.end",
        "total.value",
        "total.currency",
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

  const handleTypeChange = (
    event: React.MouseEvent<HTMLElement>,
    newValue: string
  ) => {
    setType(newValue);
    fetchDataAndParse(newValue);
  };

  const handleViewChange = (
    event: React.MouseEvent<HTMLElement>,
    newValue: string
  ) => {
    setView(newValue);
  };

  function fetchDataAndParse(resource: string) {
    setIsLoaded(false);
    const fallbackExportID = "01f00853-7663-11c8";

    const exportId =
      savedExportId && savedExportId.length > 0
        ? savedExportId
        : fallbackExportID;
    console.log("Fetching data for:", exportId);

    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());
    dispatch(updateRequestMethod("GET"));
    dispatch(
      updateRequestUrl(
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
        console.log("Fetching data:\n", response.data);
        console.log("type:", typeof response.data);

        if (typeof response.data === "string") {
          const newData = response.data.split("\n");
          dispatch(
            updateCdsResponse({
              cards: newData,
              systemActions: {},
            })
          );

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
          console.log("Parsed JSON Data:", jsonData);
          setParsedData(jsonData);
          if (jsonData.length > 0) {
            setParsedDataKeys(Object.keys(jsonData[0]));
          }
          setIsLoaded(true);
        } else {
          console.log("Data is not a string");
          dispatch(
            updateCdsResponse({
              cards: response.data,
              systemActions: {},
            })
          );
          setParsedData([response.data]);
          setParsedDataKeys(Object.keys(response.data));
          setIsLoaded(true);
        }
      })
      .catch((error) => {
        console.log("error", error);
      });
  }

  function MappedTable({ type }: { type: string }) {
    return (
      <div style={{ marginTop: "20px", marginBottom: "20px" }}>
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
                            if (part.includes("[") && part.includes("]")) {
                              const [arrayPart, indexPart] = part
                                .split(/[[\]]/)
                                .filter(Boolean);
                              return (
                                acc &&
                                acc[arrayPart] &&
                                acc[arrayPart][parseInt(indexPart, 10)]
                              );
                            }
                            return acc && acc[part];
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

  function FullTable() {
    return (
      <div style={{ marginTop: "20px", marginBottom: "20px" }}>
        <TableContainer component={Paper}>
          <Table sx={{ minWidth: 650 }} size="small" aria-label="a dense table">
            <TableHead>
              <TableRow style={{ backgroundColor: "lightgrey" }}>
                {parsedDataKeys.map((key) => (
                  <TableCell key={key}>
                    <div
                      style={
                        key.charAt(0).toUpperCase() + key.slice(1) === "Id"
                          ? { minWidth: "200px" }
                          : {}
                      }
                    >
                      {key.charAt(0).toUpperCase() + key.slice(1)}
                    </div>
                  </TableCell>
                ))}
              </TableRow>
            </TableHead>
            <TableBody>
              {parsedData.map((row, rowIndex) => (
                <TableRow key={rowIndex}>
                  {parsedDataKeys.map((key) => (
                    <TableCell key={`${rowIndex}-${key}`}>
                      {typeof row[key] === "object" ? (
                        <>
                          <Button
                            variant="outlined"
                            onClick={() => {
                              setAlertMessage(
                                JSON.stringify(row[key], null, 2)
                              );
                              setOpenSnackbar(true);
                            }}
                          >
                            View
                          </Button>
                        </>
                      ) : (
                        row[key]
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </div>
    );
  }

  function SimpleTable() {
    if (isLoaded) {
      console.log("currentType", currentType);
      return <MappedTable type={currentType} />;
    } else {
      return (
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
          Select Resource Type to fetch ...
        </div>
      );
    }
  }

  return (
    <div style={{ margin: "20px" }}>
      <h4>Exported Data</h4>
      <div style={{ flex: 1, marginTop: "10px" }}>
        <ToggleButtonGroup
          color="primary"
          value={view}
          exclusive
          onChange={handleViewChange}
          aria-label="Platform"
          fullWidth
        >
          <ToggleButton value="Simple">Simple</ToggleButton>
          <ToggleButton value="Full">Full</ToggleButton>
        </ToggleButtonGroup>
      </div>
      <div
        style={{
          marginTop: "10px",
          display: "flex",
          justifyContent: "space-between",
        }}
      >
        <div style={{ flex: 1 }}>
          <ToggleButtonGroup
            color="primary"
            value={currentType}
            exclusive
            onChange={handleTypeChange}
            aria-label="Platform"
            fullWidth
          >
            <ToggleButton value="Encounter">Encounter</ToggleButton>
            <ToggleButton value="Claim">Claim</ToggleButton>
            <ToggleButton value="DiagnosticReport">
              Diagnostic Report
            </ToggleButton>
          </ToggleButtonGroup>
        </div>
      </div>
      {alertMessage && openSnackbar && (
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
      )}

      {isLoaded && view === "Full" ? (
        <FullTable />
      ) : isLoaded && view === "Simple" ? (
        <SimpleTable />
      ) : (
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
          Select Resource Type to fetch ...
        </div>
      )}
    </div>
  );
};
