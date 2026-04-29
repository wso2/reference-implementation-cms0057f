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

import {
  TextField,
  Button,
  SelectChangeEvent,
  Box,
  Alert,
  Snackbar,
} from "@mui/material";
import { DropDownBox } from "../components/dropDown";
import { SCREEN_WIDTH, SCREEN_HEIGHT } from "../constants/page";
import { useContext, useEffect, useState } from "react";
import { updateCdsHook } from "../redux/cdsRequestSlice";
import { useDispatch, useSelector } from "react-redux";
import { LAB_TEST } from "../constants/data";
import { ExpandedContext } from "../utils/expanded_context";
import { useAuth } from "../components/AuthProvider";
import { Navigate, useLocation } from "react-router-dom";
import { CREATE_PAS_CLAIM_BUNDLE } from "../constants/data";
import axios from "axios";

function LabTest() {
  const { isAuthenticated } = useAuth();
  const form_selector_width = SCREEN_WIDTH * 0.3;
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  const loggedUserId = useSelector((state: { loggedUser: { id: string } }) => state.loggedUser.id);

  const vertical = "bottom";
  const horizontal = "right";

  const [enableNotification1, setEnableNotification1] = useState(false);
  const [enableNotification2, setEnableNotification2] = useState(false);

  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const urlPatientId = queryParams.get("patientId") || "PA2347";
  const serviceRequestId = queryParams.get("serviceRequestId");
  const questionnaireResponseId = queryParams.get("questionnaireResponseId");

  const [patientId] = useState(urlPatientId);
  const practionerId = loggedUserId || "456";

  const [questionnaireResponseResource, setQuestionnaireResponseResource] = useState<any>(null);
  const [coverageResource, setCoverageResource] = useState<any>(null);
  const [practitionerResource, setPractitionerResource] = useState<any>(null);
  const [serviceRequestResource, setServiceRequestResource] = useState<any>(null);
  const [patientResource, setPatientResource] = useState<any>(null);

  const [loading, setLoading] = useState(false);
  const [selectedTestType, setSelectedTestType] = useState("");
  const [selectedArea, setSelectedArea] = useState("");
  const [description, setDescription] = useState("");
  const [file, setFile] = useState("");

  const [isTestTypeChanged, setIsTestTypeChanged] = useState(false);
  const [isSelectedAreaChanged, setIsSelectedAreaChanged] = useState(false);
  const [isFileUploadChanged, setIsFileUploadChanged] = useState(false);

  const validateError = (
    <>
      <Alert severity="error" sx={{ marginLeft: 1, width: 490 }}>
        This is an mandotary field.
      </Alert>
    </>
  );

  const handleChangeTestType = (event: SelectChangeEvent) => {
    setSelectedTestType(event.target.value);
  };

  const handleChangeArea = (event: SelectChangeEvent) => {
    setSelectedArea(event.target.value);
  };

  const handleChangeDescription = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setDescription(event.target.value);
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    setIsFileUploadChanged(true);
    setFile(event.target.value);
  };

  const handleOnBlurTestType = () => {
    setIsTestTypeChanged(true);
  };

  const handleOnBlurArea = () => {
    setIsSelectedAreaChanged(true);
  };

  const handleScheduleClick = async () => {
    setLoading(true);
    const Config = (window as any).Config;

    const providerOrg = {
      resourceType: "Organization",
      id: "provider-01",
      meta: {
        profile: [
          "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-requestor-organization",
        ],
      },
      identifier: [
        {
          system: "http://hl7.org/fhir/sid/us-npi",
          value: "9999999999",
        },
      ],
      name: "General Hospital Radiology",
    };

    const payerOrg = {
      resourceType: "Organization",
      id: "payer-01",
      meta: {
        profile: [
          "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-insurer-organization",
        ],
      },
      name: "WSO2 Healthcare Payer",
    };

    const bundle = CREATE_PAS_CLAIM_BUNDLE(
      patientResource,
      serviceRequestResource,
      questionnaireResponseResource,
      coverageResource,
      providerOrg,
      payerOrg,
      practionerId,
      practitionerResource
    );

    try {
      const response = await axios.post(Config.claim_submit, bundle, {
        headers: {
          "Content-Type": "application/fhir+json",
        },
      });

      if (response.status >= 200 && response.status < 300) {
        setEnableNotification1(true);
        // Clear form or navigate
      } else {
        console.error("Failed to submit PAS claim:", response.data);
      }
    } catch (error) {
      console.error("Error submitting PAS claim:", error);
    } finally {
      setLoading(false);
    }
  };



  useEffect(() => {
    const fetchResources = async () => {
      const Config = (window as any).Config;
      try {
        // Fetch Practitioner
        if (practionerId) {
          const practRes = await axios.get(`${Config.practitioner}/${practionerId}`);
          setPractitionerResource(practRes.data);
        }

        // Fetch Patient
        const patRes = await axios.get(`${Config.patient}/${patientId}`);
        setPatientResource(patRes.data);

        // Fetch ServiceRequest
        if (serviceRequestId) {
          const srRes = await axios.get(`${Config.service_request}/${serviceRequestId}`);
          setServiceRequestResource(srRes.data);
          setSelectedTestType(srRes.data.code?.coding?.[0]?.display || "");
        }

        // Fetch QuestionnaireResponse
        if (questionnaireResponseId) {
          const qrRes = await axios.get(`${Config.questionnaire_response}/${questionnaireResponseId}`);
          setQuestionnaireResponseResource(qrRes.data);
        } else {
          // Attempt to fetch latest QuestionnaireResponse for this patient
          const qrSearchRes = await axios.get(`${Config.baseUrl}/fhir/r4/QuestionnaireResponse?patient=${patientId}&_count=1`);
          if (qrSearchRes.data.entry && qrSearchRes.data.entry.length > 0) {
            setQuestionnaireResponseResource(qrSearchRes.data.entry[0].resource);
          }
        }

        // Fetch Coverage (implied search or direct by ID if we had it, for now assume there's one for patient)
        const covRes = await axios.get(`${Config.baseUrl}/fhir/r4/Coverage?patient=${patientId}`);
        if (covRes.data.entry && covRes.data.entry.length > 0) {
          setCoverageResource(covRes.data.entry[0].resource);
        } else {
          // Fallback static coverage if not found in server for demo purposes
          setCoverageResource({
            resourceType: "Coverage",
            id: "cov-01",
            status: "active",
            beneficiary: { reference: `Patient/${patientId}` },
            payor: [{ reference: "Organization/payer-01" }],
            subscriberId: "588675dc-e80e-4528-a78f-af10f9755f23",
          });
        }
      } catch (err) {
        console.error("Error fetching resources for Prior Auth:", err);
      }
    };

    fetchResources();
    dispatch(updateCdsHook("order-sign"));
  }, [selectedPatientId, description, dispatch, patientId, serviceRequestId, questionnaireResponseId, practionerId]);

  return isAuthenticated ? (
    <>
      <Box
        style={{
          display: "flex",
          flexDirection: expanded ? "column" : "row",
          marginLeft: SCREEN_WIDTH * 0.07,
        }}
      >
        {expanded && (
          <img
            src="/appointment_book.png"
            alt="Healthcare"
            style={{
              marginLeft: SCREEN_WIDTH * 0.05,
              height: SCREEN_HEIGHT * 0.5,
              width: SCREEN_WIDTH * 0.3,
            }}
          />
        )}

        <Box style={{ marginLeft: SCREEN_WIDTH * 0.07, flexDirection: "row" }}>
          <Box
            style={{
              fontSize: 40,
              fontWeight: 700,
              marginBottom: 30,
            }}
          >
            Send a Prior-Authorization Request
          </Box>
          <TextField
            disabled
            label="Patient Id *"
            variant="outlined"
            defaultValue={patientId}
            sx={{
              width: 520,
              marginLeft: 1,
              marginBottom: 2,
            }}
          />
          <TextField
            disabled
            label="Practioner Id *"
            variant="outlined"
            defaultValue={practionerId}
            sx={{ width: 520, marginLeft: 1, marginBottom: 1 }}
          />

          <DropDownBox
            dropdown_label="Test Type *"
            dropdown_options={LAB_TEST.test}
            selectedValue={selectedTestType}
            handleChange={handleChangeTestType}
            handleOnBlur={handleOnBlurTestType}
            form_selector_width={form_selector_width}
            borderColor={
              isTestTypeChanged && selectedTestType === "" ? "red" : ""
            }
          />
          {isTestTypeChanged && selectedTestType === "" && validateError}

          <DropDownBox
            dropdown_label="Targeted area for diagnosis *"
            dropdown_options={LAB_TEST.area}
            selectedValue={selectedArea}
            handleChange={handleChangeArea}
            handleOnBlur={handleOnBlurArea}
            form_selector_width={form_selector_width}
            borderColor={
              isSelectedAreaChanged && selectedArea === "" ? "red" : ""
            }
          />
          {isSelectedAreaChanged && selectedArea === "" && validateError}

          <TextField
            id="outlined-multiline-static"
            label="Diagnosis Summary"
            multiline
            value={description}
            onChange={handleChangeDescription}
            rows={5}
            sx={{
              marginLeft: 1,
              minWidth: form_selector_width,
              marginTop: 1,
            }}
          />
          <Box marginLeft={1} marginTop={2}>
            <Button
              variant="contained"
              component="label"
              sx={{ marginRight: 2 }}
            >
              Upload relevant document *
              <input type="file" hidden onChange={handleFileUpload} />
            </Button>
            {file.split("\\fakepath\\")[1]}
          </Box>
          {isFileUploadChanged && file === "" && validateError}

          <Box>
            <Button
              variant="contained"
              onClick={handleScheduleClick}
              disabled={loading}
              style={{
                borderRadius: "50px",
                marginLeft: 20,
                marginTop: 50,
              }}
            >
              {loading ? "Submitting..." : "Submit"}
            </Button>
          </Box>
        </Box>

        <Box
          style={{
            marginLeft: SCREEN_WIDTH * 0.1,
            marginTop: SCREEN_HEIGHT * 0.07,
          }}
        >
          {!expanded && (
            <img
              src="/appointment_book.png"
              alt="Healthcare"
              style={{ marginLeft: SCREEN_WIDTH * 0.05 }}
            />
          )}
        </Box>

        {enableNotification1 && (
          <Snackbar
            anchorOrigin={{ vertical, horizontal }}
            open={true}
            autoHideDuration={3000}
            onClose={() => {
              setEnableNotification1(false);
            }}
            message="Note archived"
            action={true}
            key={vertical + horizontal}
          >
            <Alert
              onClose={() => {
                setEnableNotification1(false);
              }}
              severity="info"
              variant="filled"
              sx={{ width: "100%" }}
            >
              Prior-Authorzation request sent successfully!
            </Alert>
          </Snackbar>
        )}

        {enableNotification2 && (
          <Snackbar
            anchorOrigin={{ vertical, horizontal }}
            open={true}
            autoHideDuration={3000}
            onClose={() => {
              setEnableNotification2(false);
            }}
            message="Note archived"
            action={true}
            key={vertical + horizontal}
          >
            <Alert
              onClose={() => {
                setEnableNotification2(false);
              }}
              severity="info"
              variant="filled"
              sx={{ width: "100%" }}
            >
              Result will be notified soon.
            </Alert>
          </Snackbar>
        )}
      </Box>
    </>
  ) : (
    <Navigate to="/" replace />
  );
}

export default LabTest;
