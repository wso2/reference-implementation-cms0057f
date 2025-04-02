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

import { useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../components/AuthProvider";
import DetailsDiv from "../components/DetailsDiv";
import PrescribedForm from "../components/PrescribedForm";
import QuestionnniarForm from "../components/QuestionnniarForm";

const useQuery = () => {
  return new URLSearchParams(window.location.search);
};

export default function DrugPiorAuthPage() {
  const { isAuthenticated } = useAuth();
  const query = useQuery();

  const coverageId = query.get("coverageId") || sessionStorage.getItem("coverageId") || "";
  const medicationRequestId = query.get("medicationRequestId") || sessionStorage.getItem("medicationRequestId") || "";
  const patientId = query.get("patientId") || sessionStorage.getItem("patientId") || "";

  const [isQuestionnaireResponseSubmited, setIsQuestionnaireResponseSubmited] =
    useState(false);

  return isAuthenticated ? (
    <div style={{ padding: "30px" }}>
      <div className="page-heading" style={{ fontSize: "24px", fontWeight: "bold", marginBottom: "20px" }}>
        Send a Prior-Authorizing Request for Drugs
      </div>
      <DetailsDiv patientId={patientId} />
      <PrescribedForm medicationRequestId={medicationRequestId} />
      <QuestionnniarForm
        coverageId={coverageId}
        medicationRequestId={medicationRequestId}
        isQuestionnaireResponseSubmited={isQuestionnaireResponseSubmited}
        setIsQuestionnaireResponseSubmited={setIsQuestionnaireResponseSubmited}
      />
      <style>{`
        .card {
          height: 100%;
          display: flex;
          flex-direction: column;
        }
        .card-body {
          flex: 1;
        }
      `}</style>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}
