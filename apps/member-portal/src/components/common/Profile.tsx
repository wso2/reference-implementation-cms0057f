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
import {
  resetCdsRequest,
  updateRequestMethod,
  updateRequestUrl,
} from "../redux/cdsRequestSlice";
import { resetCdsResponse, updateCdsResponse } from "../redux/cdsResponseSlice";
import { useDispatch } from "react-redux";

const Profile = ({ userName, firstName, lastName, id }: any) => {
  const Config = window.Config;
  const dispatch = useDispatch();

  interface Patient {
    resourceType: string;
    gender: string;
    telecom: Telecom[];
    id: string;
    identifier: Identifier[];
    address: Address[];
    birthDate: string;
    meta: Meta;
    name: Name[];
  }

  interface Telecom {
    system: string;
    use?: string;
    value: string;
  }

  interface Identifier {
    system: string;
    value: string;
  }

  interface Address {
    country: string;
    city: string;
    line: string[];
    postalCode: string;
    state: string;
  }

  interface Meta {
    profile: string[];
  }

  interface Name {
    given: string[];
    use: string;
    family: string;
  }

  const [fetchedPatient, setPatientDetails] = useState<Patient | null>(null);

  useEffect(() => {
    console.log("Current Patient ID:", id);

    const fetchPatientDetails = async () => {
      try {
        console.log("Fetching patient details...");
        dispatch(resetCdsRequest());
        dispatch(resetCdsResponse());
        const req_url = Config.patient + "/" + id;
        dispatch(updateRequestMethod("GET"));
        dispatch(updateRequestUrl("/fhir/r4/Patient/" + id));

        axios.get(req_url).then((response) => {
          //   console.log("Patient details:", response.data);
          dispatch(
            updateCdsResponse({
              cards: response.data,
              systemActions: {},
            })
          );
          if (response.status === 200) {
            setPatientDetails(response.data);
            localStorage.setItem("patientResource", JSON.stringify(response.data));
          }
          
        });
      } catch (error) {
        console.error("Error fetching patient details:", error);
      }
    };
    fetchPatientDetails();
  }, [Config, id, dispatch]);

  console.log("Fetched Patient Details:", fetchedPatient);

  return (
    <div style={{ marginLeft: "10px", marginTop: "4vh", marginRight: "10px" }}>
      <div>
        <h1>{firstName + " " + lastName}</h1>
        {/* Username: <span style={{ color: "grey" }}>{userName}</span> */}
      </div>
      <hr />
      {/* <Typography variant="h4">Personal Details</Typography> */}
      <div style={{ marginBottom: "5vh" }}>
        <div>
          <Form>
            <div
              style={{
                display: "flex",
                gap: "20px",
              }}
            >
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Username</Form.Label>
                <Form.Control type="text" value={userName} disabled />
              </Form.Group>
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>ID</Form.Label>
                <Form.Control type="text" value={id} disabled />
              </Form.Group>
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Gender</Form.Label>
                <Form.Control
                  type="text"
                  value={fetchedPatient?.gender?.toUpperCase()}
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Birth Date</Form.Label>
                <Form.Control
                  type="text"
                  value={fetchedPatient?.birthDate}
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Phone</Form.Label>
                <Form.Control
                  type="text"
                  value={
                    fetchedPatient?.telecom?.find(
                      (contact) => contact.system === "phone"
                    )?.value
                  }
                  disabled
                />
              </Form.Group>
            </div>
            <div
              style={{
                display: "flex",
                gap: "20px",
              }}
            >
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Email</Form.Label>
                <Form.Control
                  type="text"
                  value={
                    fetchedPatient?.telecom?.find(
                      (contact) => contact.system === "email"
                    )?.value
                  }
                  disabled
                />
              </Form.Group>
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Address</Form.Label>
                <Form.Control
                  type="text"
                  value={
                    fetchedPatient?.address?.[0]
                      ? `${fetchedPatient.address[0].line?.join(", ")}, ${
                          fetchedPatient.address[0].city
                        }, ${fetchedPatient.address[0].state}, ${
                          fetchedPatient.address[0].postalCode
                        }, ${fetchedPatient.address[0].country}`
                      : ""
                  }
                  disabled
                />
              </Form.Group>
            </div>
          </Form>
        </div>
      </div>
      <hr />
    </div>
  );
};

export default Profile;
