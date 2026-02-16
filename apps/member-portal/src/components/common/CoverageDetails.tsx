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

import Form from "react-bootstrap/Form";
import "bootstrap/dist/css/bootstrap.min.css";
import { useEffect, useState } from "react";
import axios from "axios";

interface Coverage {
  resourceType: string;
  id: string;
  status: string;
  type?: {
    coding?: { system?: string; code?: string; display?: string }[];
    text?: string;
  };
  subscriber?: { reference?: string; display?: string };
  beneficiary?: { reference?: string; display?: string };
  relationship?: {
    coding?: { code?: string; display?: string }[];
  };
  period?: { start?: string; end?: string };
  payor?: { reference?: string; display?: string }[];
  class?: {
    type?: { coding?: { code?: string; display?: string }[] };
    value?: string;
    name?: string;
  }[];
  identifier?: { system?: string; value?: string }[];
}

const CoverageDetails = ({ patientId }: { patientId: string }) => {
  const Config = window.Config;
  const [coverages, setCoverages] = useState<Coverage[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCoverages = async () => {
      if (!patientId) return;

      try {
        const coverageUrl = Config.patient.replace(/Patient$/, "Coverage");
        const response = await axios.get(
          `${coverageUrl}?patient=Patient/${patientId}`
        );
        const entries = response.data.entry || [];
        setCoverages(entries.map((entry: any) => entry.resource));
      } catch (error) {
        console.error("Error fetching coverage details:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchCoverages();
  }, [Config, patientId]);

  if (loading) {
    return (
      <div style={{ marginLeft: "10px", marginTop: "2vh", marginRight: "10px" }}>
        <h4>Loading coverage details...</h4>
      </div>
    );
  }

  if (coverages.length === 0) {
    return (
      <div style={{ marginLeft: "10px", marginTop: "2vh", marginRight: "10px" }}>
        <h4>No coverage records found.</h4>
        <hr />
      </div>
    );
  }

  return (
    <div style={{ marginLeft: "10px", marginTop: "2vh", marginRight: "10px" }}>
      <h3>Coverage Details</h3>
      {coverages.map((coverage, index) => (
        <div key={coverage.id || index} style={{ marginBottom: "3vh" }}>
          <h5>
            Coverage {index + 1}
            {coverage.status && (
              <span
                style={{
                  marginLeft: "10px",
                  fontSize: "0.8em",
                  color: coverage.status === "active" ? "green" : "grey",
                }}
              >
                ({coverage.status})
              </span>
            )}
          </h5>
          <Form>
            <div style={{ display: "flex", gap: "20px" }}>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Coverage ID</Form.Label>
                <Form.Control type="text" value={coverage.id || ""} disabled />
              </Form.Group>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Status</Form.Label>
                <Form.Control
                  type="text"
                  value={coverage.status?.toUpperCase() || ""}
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Type</Form.Label>
                <Form.Control
                  type="text"
                  value={
                    coverage.type?.text ||
                    coverage.type?.coding?.[0]?.display ||
                    coverage.type?.coding?.[0]?.code ||
                    ""
                  }
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Subscriber</Form.Label>
                <Form.Control
                  type="text"
                  value={coverage.subscriber?.display || coverage.subscriber?.reference || ""}
                  disabled
                />
              </Form.Group>
            </div>
            <div style={{ display: "flex", gap: "20px" }}>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Period Start</Form.Label>
                <Form.Control
                  type="text"
                  value={coverage.period?.start || ""}
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Period End</Form.Label>
                <Form.Control
                  type="text"
                  value={coverage.period?.end || ""}
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Payor</Form.Label>
                <Form.Control
                  type="text"
                  value={
                    coverage.payor?.[0]?.display ||
                    coverage.payor?.[0]?.reference ||
                    ""
                  }
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "10px", flex: "1 1 100%" }}>
                <Form.Label>Beneficiary</Form.Label>
                <Form.Control
                  type="text"
                  value={coverage.beneficiary?.display || coverage.beneficiary?.reference || ""}
                  disabled
                />
              </Form.Group>
            </div>
          </Form>
          {index < coverages.length - 1 && <hr style={{ marginTop: "2vh" }} />}
        </div>
      ))}
      <hr />
    </div>
  );
};

export default CoverageDetails;
