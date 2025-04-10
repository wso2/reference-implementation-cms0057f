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
import { Loader2, Database, SendHorizontal, ShieldAlert } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useSearchParams } from "react-router-dom";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import {  } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';

// Define the FHIR operations with their required parameters
const fhirOperations = [
  {
    id: "patient-search",
    name: "Patient Search",
    endpoint: "/Patient",
    params: [
      {
        name: "_id",
        label: "Patient ID",
        type: "text",
        required: false,
        default: "1",
      },
      { name: "given", label: "Given Name", type: "text", required: false },
      { name: "family", label: "Family Name", type: "text", required: false },
      {
        name: "address-state",
        label: "Address State",
        type: "text",
        required: false,
      },
      {
        name: "address-city",
        label: "Address City",
        type: "text",
        required: false,
      },
    ],
  },
  {
    id: "explanation-of-benefits",
    name: "Explanation of Benefits",
    endpoint: "/ExplanationOfBenefit",
    params: [
      {
        name: "patient",
        label: "Patient ID",
        type: "text",
        required: false,
        default: "1",
      },
      {
        name: "_id",
        label: "Explanation of Benefits ID",
        type: "text",
        required: false,
      },
      { name: "_profile", label: "Profile", type: "text", required: false },
      {
        name: "_lastUpdated",
        label: "Last Updated",
        type: "date",
        required: false,
      },
      {
        name: "identifier",
        label: "Identifier",
        type: "text",
        required: false,
      },
      { name: "created", label: "Created", type: "date", required: false },
    ],
  },
  {
    id: "coverage",
    name: "Coverage",
    endpoint: "/Coverage",
    params: [
      {
        name: "patient",
        label: "Patient ID",
        type: "text",
        required: false,
        default: "1",
      },
      { name: "_id", label: "Coverage ID", type: "text", required: false },
    ],
  },
];

interface ConnectionData {
  baseUrl: string;
  consumerKey: string;
  consumerSecret: string;
  redirectUri: string;
  practitionerMode: boolean;
}

interface AuthToken {
  access_token: string;
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
  const { toast } = useToast();
  const navigate = useNavigate();
  const [selectedOperation, setSelectedOperation] = useState<string>("");
  const [paramValues, setParamValues] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [responseData, setResponseData] = useState<any>(null);
  const [connectionData, setConnectionData] = useState<ConnectionData | null>(
    null
  );
  const [authToken, setAuthToken] = useState<AuthToken | null>(null);

  const [searchParams] = useSearchParams();

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
      toast({
        title: "User Authenticated",
        description: "User is authenticated successfully.",
        variant: "default",
      });
      console.log("Already authenticated, redirecting to API view...");
      navigate("/api-view");
      return;
    }

    if (code && state && storedSmartConfig && storedConnection) {
      setConnectionData(storedConnection);
      fetchToken();
    } else {
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
          if (param.default) {
            initialParams[param.name] = param.default;
          } else {
            initialParams[param.name] = "";
          }
        });
        setParamValues(initialParams);
      }
    }
  }, [selectedOperation]);

  const handleParamChange = (paramName: string, value: string) => {
    setParamValues((prev) => ({
      ...prev,
      [paramName]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setResponseData(null);

    // Find the selected operation
    const operation = fhirOperations.find((op) => op.id === selectedOperation);
    if (!operation || !connectionData) {
      setIsLoading(false);
      return;
    }

    // Build the URL
    let url = `${connectionData.baseUrl}${operation.endpoint}`;
    const hasParams = Object.values(paramValues).some((value) => value);
    if (hasParams) {
      url += "?";
    }

    // Add parameters
    const params = new URLSearchParams();
    Object.entries(paramValues).forEach(([key, value]) => {
      if (value) {
        params.append(key, value);
      }
    });

    url += params.toString();

    try {
      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authToken?.access_token}`,
          Accept: "application/fhir+json",
        },
      });

      // if (!response.ok) {
      //   throw new Error(`HTTP error ${response.status}`);
      // }

      const data = await response.json();
      setResponseData(data);
    } catch (error) {
      console.error("Error fetching data:", error);
      toast({
        title: "Request failed",
        description: "Could not retrieve data from the FHIR server.",
        variant: "destructive",
      });
      sessionStorage.clear();
      navigate("/");
    } finally {
      setIsLoading(false);
    }
  };

  const getCurrentOperation = () => {
    return fhirOperations.find((op) => op.id === selectedOperation);
  };

  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-b from-orange-50 to-white">
      <div className="flex-grow py-6 px-2 sm:px-4 w-full">
        <div className="max-w-full mx-auto space-y-6">
          <div className="text-center mb-6">
            <h1 className="text-3xl font-bold text-primary">
              FHIR API Explorer
            </h1>
            <p className="text-muted-foreground">
              Select an operation and configure request parameters
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
                    ? "Configure the parameters for this request"
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
                          />
                        </div>
                      ))}
                    </div>

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
                <CardHeader className="pb-3">
                  <CardTitle className="text-xl">Response</CardTitle>
                  <CardDescription>FHIR API response data</CardDescription>
                </CardHeader>
                <CardContent>
                  {isLoading ? (
                    <div className="h-64 flex items-center justify-center">
                      <Loader2 className="h-8 w-8 animate-spin text-primary" />
                      <span className="ml-2">Fetching data...</span>
                    </div>
                  ) : responseData ? (
                    <div>
                      <SyntaxHighlighter
                        language="json"
                        style={vscDarkPlus}
                        showLineNumbers={true}
                        // customStyle={{ margin: 0, backgroundColor: 'transparent' }}
                      >
                        {JSON.stringify(responseData, null, 2)}
                      </SyntaxHighlighter>
                    </div>
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
