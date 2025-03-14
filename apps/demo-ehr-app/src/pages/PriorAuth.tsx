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
import { Navigate } from "react-router-dom";

function LabTest() {
  const { isAuthenticated } = useAuth();
  const form_selector_width = SCREEN_WIDTH * 0.3;
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );

  const vertical = "bottom";
  const horizontal = "right";

  const [enableNotification1, setEnableNotification1] = useState(false);
  const [enableNotification2, setEnableNotification2] = useState(false);

  const [patientId, setPatientId] = useState("PA2347");
  const [practionerId, setPractionerId] = useState("PT567498");
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

  const handleScheduleClick = () => {
    setPatientId("");
    setPractionerId("");
    setEnableNotification1(true);
    setSelectedTestType("");
    setSelectedArea("");
    setDescription("");
    setFile("");

    setIsTestTypeChanged(false);
    setIsSelectedAreaChanged(false);
    setIsFileUploadChanged(false);
  };

  const isFormValid = () => {
    return selectedTestType != "" && selectedArea != "" && file != "";
  };

  useEffect(() => {
    dispatch(updateCdsHook("order-sign"));
  }, [selectedPatientId, description, dispatch]);

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
              disabled={!isFormValid()}
              style={{
                borderRadius: "50px",
                marginLeft: 20,
                marginTop: 50,
              }}
            >
              Submit
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
