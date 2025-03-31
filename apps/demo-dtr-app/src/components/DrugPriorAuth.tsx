import { useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthProvider";
import DetailsDiv from "./DetailsDiv";
import PrescribedForm from "./PrescribedForm";
import QuestionnniarForm from "./QuestionnniarForm";

const useQuery = () => {
  return new URLSearchParams(window.location.search);
};

export default function DrugPiorAuth() {
  const { isAuthenticated } = useAuth();
  const query = useQuery();

  const coverageId = query.get("coverageId") || sessionStorage.getItem("coverageId") || "";
  const medicationRequestId = query.get("medicationRequestId") || sessionStorage.getItem("medicationRequestId") || "";
  const patientId = query.get("patientId") || sessionStorage.getItem("patientId") || "";

  console.log("coverageId", coverageId);
  console.log("medicationRequestId", medicationRequestId);
  console.log("patientId", patientId);
  console.log("isAuthenticated", isAuthenticated);

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
