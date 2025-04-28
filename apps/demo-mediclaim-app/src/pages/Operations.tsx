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

import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Loader2,
  Database,
  SendHorizontal,
  ShieldAlert,
  Table as TableIcon,
  LayoutGrid,
} from "lucide-react";
import { useToast } from "@/custom_hooks/use-toast";
import { useSearchParams } from "react-router-dom";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { vscDarkPlus } from "react-syntax-highlighter/dist/esm/styles/prism";
import { fhirOperationConfigs } from "@/utils/constants";
import { jwtDecode } from "jwt-decode";
import { Switch } from "@/components/ui/switch";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

interface ConnectionData {
  baseUrl: string;
  consumerKey: string;
  consumerSecret: string;
  redirectUri: string;
  practitionerMode: boolean;
}

interface AuthToken {
  access_token: string;
  id_token: string;
  token_type: string;
  expires_in: number;
  scope: string;
}

interface SmartConfiguration {
  authorization_endpoint: string;
  token_endpoint: string;
  capabilities: string[];
}

const Operations: React.FC = () => {
  const fhirOperations = fhirOperationConfigs;
  const { toast } = useToast();
  const navigate = useNavigate();
  const [selectedOperation, setSelectedOperation] =
    useState<string>("patient-search");
  const [patient, setPatient] = useState<string>("");
  const [paramValues, setParamValues] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [responseData, setResponseData] = useState<any>(null);
  const [connectionData, setConnectionData] = useState<ConnectionData | null>(
    null
  );
  const [authToken, setAuthToken] = useState<AuthToken | null>(null);

  const [searchParams] = useSearchParams();
  const [viewMode, setViewMode] = useState<"json" | "table">("table");

  // New state for patient details
  const [patientDetails, setPatientDetails] = useState({
    givenName: "",
    familyName: "",
    addressCity: "",
    addressCountry: "",
  });

  useEffect(() => {
    // Function to fetch the token
    const fetchToken = async () => {
      try {
        const response = await fetch(storedSmartConfig.token_endpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            grant_type: "authorization_code",
            code,
            redirect_uri: storedConnection.redirectUri,
            client_id: storedConnection.consumerKey,
            client_secret: storedConnection.consumerSecret,
          }),
        });

        if (!response.ok) {
          toast({
            title: "Authentication Failed",
            description: "Could not retrieve access token",
            variant: "destructive",
          });
          sessionStorage.clear();
          navigate("/");
        }

        const tokenData: AuthToken = await response.json();
        sessionStorage.setItem("fhirAuthToken", JSON.stringify(tokenData));

        toast({
          title: "Authentication Successful",
          description: "Access token retrieved successfully",
          variant: "default",
        });
        navigate("/api-view");
      } catch (error) {
        console.error("Error fetching token:", error);
        toast({
          title: "Authentication Failed",
          description: "Could not retrieve access token",
          variant: "destructive",
        });
        sessionStorage.clear();
        navigate("/");
      }
    };

    const code = searchParams.get("code");
    const state = searchParams.get("state");

    const storedConnection = sessionStorage.getItem("fhirConnection")
      ? JSON.parse(sessionStorage.getItem("fhirConnection")!)
      : null;
    const storedSmartConfig = sessionStorage.getItem("fhirSmartConfig")
      ? JSON.parse(sessionStorage.getItem("fhirSmartConfig")!)
      : null;
    const storedAuthToken = sessionStorage.getItem("fhirAuthToken")
      ? JSON.parse(sessionStorage.getItem("fhirAuthToken")!)
      : null;

    if (storedAuthToken) {
      setAuthToken(storedAuthToken);
      setConnectionData(storedConnection);
      if (storedAuthToken.id_token) {
        try {
          const decodedToken: any = jwtDecode(storedAuthToken.id_token);
          if (decodedToken.patient) {
            console.log("Patient ID:", decodedToken.patient);
            setPatient(decodedToken.patient);
            navigate("/api-view");
            return;
          } else {
            toast({
              title: "Patient Not found",
              description: "Logged in user is not a registered patient",
              variant: "destructive",
            });
            sessionStorage.clear();
            navigate("/");
          }
        } catch (error) {
          console.error("Error decoding id_token:", error);
          toast({
            title: "Authentication Failed",
            description: "Could not retrieve data from id_token",
            variant: "destructive",
          });
          sessionStorage.clear();
          navigate("/");
        }
      } else {
        console.log("No id_token found");
        toast({
          title: "Authentication Failed",
          description: "Could not retrieve id_token",
          variant: "destructive",
        });
        sessionStorage.clear();
        navigate("/");
      }
    }

    if (code && state && storedSmartConfig && storedConnection) {
      setConnectionData(storedConnection);
      fetchToken();
    } else {
      sessionStorage.clear();
      navigate("/");
    }
  }, [searchParams, toast, navigate]);

  useEffect(() => {
    setResponseData(null);
    if (selectedOperation) {
      const operation = fhirOperations.find(
        (op) => op.id === selectedOperation
      );
      if (operation) {
        const initialParams: Record<string, string> = {};
        operation.params.forEach((param) => {
          if (param.label === "Patient ID") {
            initialParams[param.name] = patient;
          }
          if (param.defaultValue) {
            initialParams[param.name] = param.defaultValue;
          }
        });
        setParamValues(initialParams);

        // Auto-execute API request
        executeApiRequest(initialParams, operation);
      }
    }
  }, [selectedOperation, authToken]);

  // Effect to extract patient details when response data changes
  useEffect(() => {
    if (
      responseData &&
      selectedOperation === "patient-search" &&
      responseData.entry &&
      responseData.entry.length > 0
    ) {
      const patient = responseData.entry[0].resource;

      // Extract patient details
      const givenName =
        patient.name && patient.name[0]?.given
          ? patient.name[0].given[0] || ""
          : "";
      const familyName = (patient.name && patient.name[0]?.family) || "";

      // Extract address details if available
      let addressCity = "";
      let addressCountry = "";

      if (patient.address && patient.address.length > 0) {
        addressCity = patient.address[0].city || "";
        addressCountry = patient.address[0].country || "";
      }

      // Set patient details
      setPatientDetails({
        givenName,
        familyName,
        addressCity,
        addressCountry,
      });

      // Update param values with extracted details
      setParamValues((prev) => ({
        ...prev,
        given: givenName,
        family: familyName,
        "address-city": addressCity,
        "address-country": addressCountry,
      }));
    }
  }, [responseData, selectedOperation]);

  const handleParamChange = (paramName: string, value: string) => {
    setParamValues((prev) => ({
      ...prev,
      [paramName]: value,
    }));
  };

  const executeApiRequest = async (
    params: Record<string, string>,
    operation: any
  ) => {
    setIsLoading(true);
    setResponseData(null);

    if (!connectionData) {
      setIsLoading(false);
      return;
    }

    // Build the URL
    let url = `${connectionData.baseUrl}${operation.endpoint}`;
    const hasParams = Object.values(params).some((value) => value);
    if (hasParams) {
      url += "?";
    }

    // Add parameters
    const urlParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value) {
        urlParams.append(key, value);
      }
    });

    url += urlParams.toString();

    try {
      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authToken?.access_token}`,
          Accept: "application/fhir+json",
        },
      });

      const data = await response.json();
      console.log("Response data:", data);
      setResponseData(data);
      if (response.status === 401) {
        toast({
          title: "Session Expired",
          description: "Please loggin in again.",
          variant: "destructive",
        });
        sessionStorage.clear();
        navigate("/");
        return;
      }
    } catch (error) {
      console.error("Error fetching data:", error);
      toast({
        title: "Request failed",
        description: "Could not retrieve data from the FHIR server.",
        variant: "destructive",
      });
      // sessionStorage.clear();
      // navigate("/");
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Find the selected operation
    const operation = fhirOperations.find((op) => op.id === selectedOperation);
    if (!operation) return;

    executeApiRequest(paramValues, operation);
  };

  const getCurrentOperation = () => {
    return fhirOperations.find((op) => op.id === selectedOperation);
  };

  // Function to render table based on resource type
  const renderResourceTable = () => {
    if (
      !responseData ||
      !responseData.entry ||
      responseData.entry.length === 0
    ) {
      return (
        <div className="text-center py-6 text-muted-foreground">
          No data available to display in table view
        </div>
      );
    }

    // Get the resource type from the first entry
    const resourceType = responseData.entry[0]?.resource?.resourceType;

    switch (resourceType) {
      case "Patient":
        return renderPatientTable();
      case "ExplanationOfBenefit":
        return renderExplanationOfBenefitTable();
      case "Coverage":
        return renderCoverageTable();
      case "ClaimResponse":
        return renderClaimResponseTable();
      default:
        return (
          <div className="text-center py-6 text-muted-foreground">
            Table view not available for {resourceType} resources
          </div>
        );
    }
  };

  // Function to render Patient table
  const renderPatientTable = () => {
    return (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>ID</TableHead>
            <TableHead>Family Name</TableHead>
            <TableHead>Given Name</TableHead>
            <TableHead>Address</TableHead>
            <TableHead>Gender</TableHead>
            <TableHead>Birthdate</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {responseData.entry.map((entry: any, index: number) => {
            const patient = entry.resource;
            const name =
              patient.name && patient.name.length > 0 ? patient.name[0] : null;
            const address =
              patient.address && patient.address.length > 0
                ? patient.address[0]
                : null;

            return (
              <TableRow key={`patient-${index}`}>
                <TableCell>{patient.id || "N/A"}</TableCell>
                <TableCell>{name?.family || "N/A"}</TableCell>
                <TableCell>{name?.given?.join(" ") || "N/A"}</TableCell>
                <TableCell>
                  {address
                    ? `${address.line ? address.line.join(", ") : ""}
                     ${address.city || ""}
                     ${address.state || ""}
                     ${address.postalCode || ""}`.trim()
                    : "N/A"}
                </TableCell>
                <TableCell>{patient?.gender.toUpperCase() || "N/A"}</TableCell>
                <TableCell>{patient.birthDate || "N/A"}</TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    );
  };

  // Function to render ExplanationOfBenefit table
  const renderExplanationOfBenefitTable = () => {
    return (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>ID</TableHead>
            <TableHead>Created Date</TableHead>
            <TableHead>Service Provider</TableHead>
            <TableHead>Service Display</TableHead>
            <TableHead>Diagnosis Code Display</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {responseData.entry.map((entry: any, index: number) => {
            const eob = entry.resource;
            const serviceProvider = eob?.serviceProvider;

            // Find service display in items if available
            const serviceDisplay =
              eob.item && eob.item.length > 0
                ? eob.item[0].service?.display || "N/A"
                : "N/A";

            // Find diagnosis code display if available
            const diagnosisDisplay =
              eob.diagnosis && eob.diagnosis.length > 0
                ? eob.diagnosis[0].diagnosisCode?.display || "N/A"
                : "N/A";

            return (
              <TableRow key={`eob-${index}`}>
                <TableCell>{eob.id || "N/A"}</TableCell>
                <TableCell>{eob.created || "N/A"}</TableCell>
                <TableCell>{serviceProvider || "N/A"}</TableCell>
                <TableCell>{serviceDisplay}</TableCell>
                <TableCell>{diagnosisDisplay}</TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    );
  };

  // Function to render Coverage table
  const renderCoverageTable = () => {
    return (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>ID</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Issued Date</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Effective Period</TableHead>
            <TableHead>Payor</TableHead>
            <TableHead>Class</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {responseData.entry.map((entry: any, index: number) => {
            const coverage = entry.resource;

            // Get type display
            const typeDisplay =
              coverage.type?.coding && coverage.type.coding.length > 0
                ? coverage.type.coding[0].display || coverage.type.text || "N/A"
                : "N/A";

            // Get effective period
            const effectiveStart = coverage.effectivePeriod?.start || "N/A";
            const effectiveEnd = coverage.effectivePeriod?.end || "N/A";
            const effectivePeriod = `${effectiveStart} to ${effectiveEnd}`;

            // Get payor
            const payor =
              coverage.payor && coverage.payor.length > 0
                ? coverage.payor[0].display ||
                  coverage.payor[0].reference ||
                  "N/A"
                : "N/A";

            // Get class display
            const classDisplay =
              coverage.class?.coding && coverage.class.coding.length > 0
                ? coverage.class.coding[0].display || "N/A"
                : "N/A";

            return (
              <TableRow key={`coverage-${index}`}>
                <TableCell>{coverage.id || "N/A"}</TableCell>
                <TableCell>{coverage.status || "N/A"}</TableCell>
                <TableCell>{coverage.issued || "N/A"}</TableCell>
                <TableCell>{typeDisplay}</TableCell>
                <TableCell>{effectivePeriod}</TableCell>
                <TableCell>{payor}</TableCell>
                <TableCell>{classDisplay}</TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    );
  };

  // Function to render ExplanationOfBenefit table
  const renderClaimResponseTable = () => {
    return (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>ID</TableHead>
            <TableHead>Created Date</TableHead>
            <TableHead>Use</TableHead>
            <TableHead>Insurer</TableHead>
            <TableHead>Payment</TableHead>
            <TableHead>Outcome</TableHead>
            <TableHead>Disposition</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {responseData.entry.map((entry: any, index: number) => {
            const eob = entry.resource;
            const payment =
              eob?.payment?.amount?.value +
                " " +
                eob?.payment?.amount?.currency || "N/A";

            return (
              <TableRow key={`eob-${index}`}>
                <TableCell>{eob?.id || "N/A"}</TableCell>
                <TableCell>{eob?.created || "N/A"}</TableCell>
                <TableCell>{eob?.use || "N/A"}</TableCell>
                <TableCell>{eob?.insurer?.reference || "N/A"}</TableCell>
                <TableCell>{payment}</TableCell>
                <TableCell>{eob?.outcome || "N/A"}</TableCell>
                <TableCell>{eob?.disposition || "N/A"}</TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    );
  };

  // Determine if we should disable the inputs and hide the button
  const isPatientOperation = selectedOperation === "patient-search";

  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-b from-orange-50 to-white">
      <div className="flex-grow py-6 px-2 sm:px-6 lg:px-8 w-full">
        <div className="max-w-full mx-auto space-y-6">
          <div className="text-center mb-6">
            <h1 className="text-3xl font-bold text-primary">Medical Info</h1>
            <p className="text-muted-foreground">
              Perform an operation to retrieve your relavant medical
              information.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
            {/* Operation Selection Card */}
            <Card className="lg:col-span-3">
              <CardHeader className="pb-3">
                <CardTitle className="text-xl">Select Operation</CardTitle>
                <CardDescription>
                  Choose a FHIR operation to perform
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Select
                  value={selectedOperation}
                  onValueChange={setSelectedOperation}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select operation..." />
                  </SelectTrigger>
                  <SelectContent>
                    {fhirOperations.map((operation) => (
                      <SelectItem key={operation.id} value={operation.id}>
                        {operation.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                {connectionData && (
                  <div className="mt-4 p-3 bg-accent/50 rounded-md text-xs">
                    <p className="font-medium mb-1">Connected to:</p>
                    <p className="truncate">{connectionData.baseUrl}</p>
                    {authToken ? (
                      <div className="mt-2 text-green-600 font-medium text-sm flex items-center">
                        <span className="w-2 h-2 rounded-full bg-green-600 mr-1.5"></span>
                        Authenticated
                      </div>
                    ) : (
                      <div className="mt-2 text-amber-600 font-medium text-sm flex items-center">
                        <ShieldAlert className="h-3.5 w-3.5 mr-1" />
                        Demo Mode (No Auth)
                      </div>
                    )}
                    {connectionData.practitionerMode && (
                      <div className="mt-2 text-primary font-medium text-sm">
                        Practitioner Mode Active
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Parameters Form */}
            <Card className="lg:col-span-9">
              <CardHeader className="pb-3">
                <CardTitle className="text-xl">
                  {getCurrentOperation()?.name || "Operation Parameters"}
                </CardTitle>
                <CardDescription>
                  {selectedOperation
                    ? isPatientOperation
                      ? "Automatically retrieving patient data..."
                      : "Configure the parameters for this request"
                    : "Select an operation to view parameters"}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {selectedOperation ? (
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {getCurrentOperation()?.params.map((param) => (
                        <div className="space-y-2" key={param.name}>
                          <Label htmlFor={param.name}>
                            {param.label}
                            {param.required && (
                              <span className="text-destructive ml-1">*</span>
                            )}
                          </Label>
                          <Input
                            id={param.name}
                            type={param.type}
                            value={paramValues[param.name] || ""}
                            onChange={(e) =>
                              handleParamChange(param.name, e.target.value)
                            }
                            required={param.required}
                            placeholder={`Enter ${param.label.toLowerCase()}`}
                            disabled={isPatientOperation || param.disabled}
                            className={isPatientOperation ? "bg-gray-100" : ""}
                          />
                        </div>
                      ))}
                    </div>

                    {!isPatientOperation && (
                      <Button
                        type="submit"
                        className="w-full mt-4 group"
                        disabled={isLoading || !selectedOperation}
                      >
                        {isLoading ? (
                          <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            Processing...
                          </>
                        ) : (
                          <>
                            Send Request
                            <SendHorizontal className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                          </>
                        )}
                      </Button>
                    )}
                  </form>
                ) : (
                  <div className="flex flex-col items-center justify-center py-8 text-muted-foreground">
                    <Database className="h-12 w-12 mb-4 opacity-30" />
                    <p>
                      Please select an operation to view available parameters
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Response Viewer */}
            {(responseData || isLoading) && (
              <Card className="lg:col-span-12">
                <CardHeader className="pb-3 flex flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-xl">Response</CardTitle>
                    <CardDescription>FHIR API response data</CardDescription>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="flex items-center space-x-2">
                      {viewMode === "json" ? (
                        <LayoutGrid className="h-4 w-4 text-muted-foreground" />
                      ) : (
                        <TableIcon className="h-4 w-4 text-muted-foreground" />
                      )}
                      <span className="text-sm text-muted-foreground mr-2">
                        {viewMode === "json" ? "JSON" : "Table"} View
                      </span>
                    </div>
                    <Switch
                      checked={viewMode === "table"}
                      onCheckedChange={(checked) =>
                        setViewMode(checked ? "table" : "json")
                      }
                    />
                  </div>
                </CardHeader>
                <CardContent>
                  {isLoading ? (
                    <div className="h-64 flex items-center justify-center">
                      <Loader2 className="h-8 w-8 animate-spin text-primary" />
                      <span className="ml-2">Fetching data...</span>
                    </div>
                  ) : responseData ? (
                    viewMode === "json" ? (
                      <div className="rounded-md p-1 border border-border">
                        <SyntaxHighlighter
                          language="json"
                          style={vscDarkPlus}
                          showLineNumbers={true}
                        >
                          {JSON.stringify(responseData, null, 2)}
                        </SyntaxHighlighter>
                      </div>
                    ) : (
                      <div className="overflow-x-auto">
                        {renderResourceTable()}
                      </div>
                    )
                  ) : null}
                </CardContent>
                <CardFooter className="text-xs text-muted-foreground">
                  {responseData &&
                    responseData.entry &&
                    `Received ${responseData.entry.length || 0} ${
                      responseData.entry.length === 1 ? "entry." : "entries."
                    }`}
                </CardFooter>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Operations;
