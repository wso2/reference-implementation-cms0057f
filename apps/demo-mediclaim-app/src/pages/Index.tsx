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

import FhirConnectionForm from "@/components/FhirConnectionForm";
import { Database } from "lucide-react";

const Index = () => {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center fhir-gradient-bg p-4">
      <div className="w-full max-w-md mb-8">
        <div className="flex flex-col items-center justify-center mb-6">
          <Database className="h-16 w-16 text-primary mb-4" />
          <h1 className="text-3xl font-bold text-center text-primary mb-2">
            MediClaim
          </h1>
          <p className="text-center text-muted-foreground">
            FHIR APIs Explorer
          </p>
        </div>
      </div>
      <FhirConnectionForm />
    </div>
  );
};

export default Index;
