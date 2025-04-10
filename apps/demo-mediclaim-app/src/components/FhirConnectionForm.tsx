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

import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { ArrowRight, Link, Key, Globe, Shield, Loader2 } from "lucide-react";
import { useToast } from "@/custom_hooks/use-toast";
import * as uuid from "uuid";

interface FormData {
  baseUrl: string;
  consumerKey: string;
  consumerSecret: string;
  redirectUri: string;
  practitionerMode: boolean;
}

interface SmartConfiguration {
  authorization_endpoint: string;
  token_endpoint: string;
  capabilities: string[];
}

const FhirConnectionForm: React.FC = () => {
  const { toast } = useToast();
  const [formData, setFormData] = useState<FormData>({
    baseUrl: "https://openhealthcare.testdmain.online/fhir/r4",
    consumerKey: "W18lqgP3_UXGPXhhMFupu94AznUa",
    consumerSecret: "",
    redirectUri: `${window.location.origin}/api-view`,
    practitionerMode: false,
  });

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleCheckboxChange = (checked: boolean) => {
    setFormData((prev) => ({
      ...prev,
      practitionerMode: checked,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    // Ensure baseUrl doesn't end with a slash
    const baseUrl = formData.baseUrl.endsWith("/")
      ? formData.baseUrl.slice(0, -1)
      : formData.baseUrl;

    // Store the provided FHIR Connection data in sessionStorage
    sessionStorage.setItem(
      "fhirConnection",
      JSON.stringify({
        ...formData,
        baseUrl,
      })
    );

    console.log(
      "Stored FHIR connection data in sessionStorage <fhirConnection>:",
      sessionStorage.getItem("fhirConnection")
    );

    setTimeout(() => {
      // Fetch SMART configuration from well-known endpoint
      const smartConfigUrl = `${baseUrl}/.well-known/smart-configuration`;
      console.log(`Fetching SMART configuration from: ${smartConfigUrl}`);
      fetch(smartConfigUrl)
        .then((response) => {
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }
          console.log("Wellknown response:", response);
          return response.json();
        })
        .then((smartConfig: SmartConfiguration) => {
          console.log("SMART configuration fetched:", smartConfig);

          // Store the SMART configuration in sessionStorage
          sessionStorage.setItem(
            "fhirSmartConfig",
            JSON.stringify({
              ...smartConfig,
              baseUrl,
            })
          );

          toast({
            title: "Connection successful",
            description:
              "Connection to FHIR server successful. Redirecting to authorization...",
          });

          // Redirect to the authorization endpoint with appropriate parameters
          const authorizationUrl = `${
            smartConfig.authorization_endpoint
          }?response_type=code&client_id=${encodeURIComponent(
            formData.consumerKey
          )}&redirect_uri=${encodeURIComponent(
            formData.redirectUri
          )}&scope=openid%20fhirUser%20launch/patient&state=
            ${uuid.v4()}&aud=${encodeURIComponent(baseUrl)}`;

          console.log("Redirecting to authorization URL:", authorizationUrl);
          window.location.href = authorizationUrl;
        })
        .catch((err) => {
          setIsLoading(false);
          setError("Failed to fetch SMART configuration");
          toast({
            title: "Connection failed",
            description:
              "Could not fetch SMART configuration. Please check your details and try again.",
            variant: "destructive",
          });
          console.error("SMART configuration fetch error:", err);
        });
    }, 100);
  };

  return (
    <Card className="w-full max-w-md shadow-lg border-t-4 border-t-primary">
      <CardHeader className="space-y-1">
        <CardTitle className="text-2xl font-bold text-center">
          FHIR Connection
        </CardTitle>
        <CardDescription className="text-center">
          Connect to your FHIR healthcare server
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="baseUrl" className="flex items-center gap-2">
              <Globe className="h-4 w-4 text-muted-foreground" />
              Base FHIR URL
            </Label>
            <Input
              id="baseUrl"
              name="baseUrl"
              placeholder="https://fhir.example.com/api/fhir/r4"
              value={formData.baseUrl}
              onChange={handleInputChange}
              required
              className="transition-all focus-visible:ring-2 focus-visible:ring-primary/50"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="consumerKey" className="flex items-center gap-2">
              <Key className="h-4 w-4 text-muted-foreground" />
              Consumer Key
            </Label>
            <Input
              id="consumerKey"
              name="consumerKey"
              placeholder="Enter your consumer key"
              value={formData.consumerKey}
              onChange={handleInputChange}
              required
              className="transition-all focus-visible:ring-2 focus-visible:ring-primary/50"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="consumerSecret" className="flex items-center gap-2">
              <Shield className="h-4 w-4 text-muted-foreground" />
              Consumer Secret
            </Label>
            <Input
              id="consumerSecret"
              name="consumerSecret"
              type="password"
              placeholder="Enter your consumer secret"
              value={formData.consumerSecret}
              onChange={handleInputChange}
              required
              className="transition-all focus-visible:ring-2 focus-visible:ring-primary/50"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="redirectUri" className="flex items-center gap-2">
              <Link className="h-4 w-4 text-muted-foreground" />
              Redirect URI
            </Label>
            <Input
              id="redirectUri"
              name="redirectUri"
              placeholder="https://your-app.example.com/callback"
              value={formData.redirectUri}
              onChange={handleInputChange}
              required
              className="transition-all focus-visible:ring-2 focus-visible:ring-primary/50"
            />
          </div>

          {/* <div className="flex items-center space-x-2 pt-2">
            <Checkbox
              id="practitionerMode"
              checked={formData.practitionerMode}
              onCheckedChange={handleCheckboxChange}
            />
            <Label htmlFor="practitionerMode" className="cursor-pointer">
              Practitioner Mode
            </Label>
          </div> */}

          {error && <div className="text-sm text-destructive">{error}</div>}

          <Button
            type="submit"
            className="w-full group hover:translate-y-[-1px] transition-all"
            disabled={isLoading}
          >
            {isLoading ? (
              <span className="flex items-center">
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Connecting...
              </span>
            ) : (
              <>
                Connect
                <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform duration-200" />
              </>
            )}
          </Button>
        </form>
      </CardContent>
      <CardFooter className="flex justify-center text-xs text-muted-foreground">
        Securely connects to FHIR API resources
      </CardFooter>
    </Card>
  );
};

export default FhirConnectionForm;
