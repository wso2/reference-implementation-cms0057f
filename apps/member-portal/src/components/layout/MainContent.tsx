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

import { Box } from "@mui/material";
import { useLocation } from "react-router-dom";
import LoginPage from "./LoginPage";
import { LandingPage } from "./LandingPage";
import { Layout } from "./Layout";
import { ExportedDataPage } from "./ExportedDataPage";

interface PayersAndFhirServerMappings {
  id: number;
  fhirServerUrl: string;
}
declare global {
  interface Window {
    Config: {
      patient: string;
      organizationServiceUrl: string;
      bulkExportKickoffUrl: string;
      bulkExportStatusUrl: string;
      bulkExportFetch: string;
      memberMatch: string;
      oldPayerCoverageGet: string;
      payersAndFhirServerMappings: [PayersAndFhirServerMappings];
    };
  }
}

export const MainContent = () => {
  const location = useLocation();

  if (location.pathname === "/login") {
    return <LoginPage />;
  }
  if (location.pathname === "/") {
    return <Layout Component={LandingPage} />;
  }
  if (location.pathname.includes("/exported-data")) {
    return <Layout Component={ExportedDataPage} />;
  }

  return (
    <Box>
      <h1>This is the Header</h1>
      <Box id="main-container">
        <h4>This is the main content</h4>
      </Box>
    </Box>
  );
};
