import React from "react";
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
