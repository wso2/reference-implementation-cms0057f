// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

import { useSelector, useDispatch } from "react-redux";
import "../index.css";
import Card from "react-bootstrap/Card";
import Form from "react-bootstrap/Form";
import { useEffect } from "react";
import axios from "axios";
import { updateLoggedUser } from "../redux/loggedUserSlice";
import {
  updateRequestMethod,
  updateRequestUrl,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";

export function DoctorViewPage() {
  const Config = window.Config;
  const dispatch = useDispatch();
  const loggedUser = useSelector((state: any) => state.loggedUser);

  useEffect(() => {
    const fetchPractitionerDetails = async () => {
      try {
        dispatch(resetCdsResponse());
        dispatch(updateRequestMethod("GET"));
        const req_url = Config.practitioner_new + "?name=" + loggedUser.username;
        dispatch(updateRequestUrl("https://unitedcare.com/fhir/r4/Practitioner?name=" + loggedUser.username));

        console.log("Fetching practitioner details...");

        axios
          .get(req_url)
          .then((response) => {
            console.log("Practitioner details:", response.data);
            dispatch(
              updateCdsResponse({
                cards: response.data,
                systemActions: {},
              })
            );
            const user = response.data.entry[0];
            console.log("Practitioner details:", response.data);
            dispatch(
              updateLoggedUser({
                prefix: user.resource.name[0].prefix[0],
                id: user.resource.id,
                phone: user.resource.telecom[0].value,
                email: user.resource.telecom[1].value,
                first_name: user.resource.name[0].given[0],
                last_name: user.resource.name[0].family,
                address:
                  user.resource.address[0].line[0] +
                  ", " +
                  user.resource.address[0].city +
                  ", " +
                  user.resource.address[0].state +
                  ", " +
                  user.resource.address[0].postalCode,
              })
            );
          })
          .catch((error) => {
            console.error("Error submitting claim:", error);

            dispatch(
              updateCdsResponse({
                cards: error,
                systemActions: {},
              })
            );
          });
      } catch (error) {
        console.error("Error fetching practitioner details:", error);
      }
    };

    fetchPractitionerDetails();
  }, [dispatch, Config]);


  return (
    <div className="profile-page">
      <div className="cover-photo">
        <img src="/cover-M.jpg" alt="Cover" />
      </div>
      <div className="profile-photo">
        <img src="/doctor.jpg" alt="Profile" />
      </div>
      <div className="profile-content">
        <h1>
          {loggedUser.prefix} {loggedUser.first_name} {loggedUser.last_name}
        </h1>

        <Card style={{ marginTop: "30px", padding: "20px" }}>
          <Card.Body>
            <Card.Title>My Details</Card.Title>
            <Form>
              <div
                style={{
                  display: "flex",
                  gap: "20px",
                }}
              >
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>First Name</Form.Label>
                  <Form.Control
                    type="text"
                    value={loggedUser.first_name}
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Last Name</Form.Label>
                  <Form.Control
                    type="text"
                    value={loggedUser.last_name}
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Username</Form.Label>
                  <Form.Control
                    type="text"
                    value={loggedUser.username}
                    disabled
                  />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>User ID</Form.Label>
                  <Form.Control type="text" value={loggedUser.id} disabled />
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
                  <Form.Control type="text" value={loggedUser.email} disabled />
                </Form.Group>
                <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                  <Form.Label>Phone</Form.Label>
                  <Form.Control type="text" value={loggedUser.phone} disabled />
                </Form.Group>
              </div>
              <Form.Group style={{ marginTop: "20px", flex: "1 1 100%" }}>
                <Form.Label>Address</Form.Label>
                <Form.Control type="text" value={loggedUser.address} disabled />
              </Form.Group>
            </Form>
          </Card.Body>
        </Card>
      </div>
    </div>
  );
}
