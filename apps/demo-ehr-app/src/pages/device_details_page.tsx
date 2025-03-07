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

/* eslint-disable @typescript-eslint/no-unused-vars */

import { useNavigate, useParams } from "react-router-dom";
import { useState, useEffect } from "react";
import { Box } from "@mui/material";
import { DEVICE } from "../constants/data";
import { SCREEN_WIDTH } from "../constants/page";
import { DropDownBox } from "../components/dropDown";
import { SelectChangeEvent } from "@mui/material/Select";
import Button from "@mui/material/Button";
import { QUATERNARY_COLOR } from "../constants/color";
import { useContext } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import TextField from "@mui/material/TextField";
import { DeviceRequestResourceConstructor } from "../utils/device_request_resource_constructor";
import { useDispatch, useSelector } from "react-redux";
import { updateCdsHook, updateCdsContext } from "../redux/cdsRequestSlice";

export function DeviceDetailsPage() {
  const { deviceName } = useParams();
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );

  // In the actual implementation, this would be fetched from a backend API
  const device = DEVICE.find(
    (device) => device.name.toLowerCase() === deviceName?.toLowerCase()
  );

  const [selectedIntent, setSelectedIntent] = useState("");
  const [selectedPriority, setSelectedPriority] = useState("");
  const [description, setDescription] = useState("");

  const INTENT = [
    "proposal",
    "plan",
    "directive",
    "order",
    "original-order",
    "reflex-order",
    "filler-order",
    "instance-order",
    "option",
  ];

  const PRIORITY = ["routine", "urgent", "ASAP", "STAT"];

  const handlePreviewClick = (contextData: string) => {
    navigate("coverage-preview", { state: contextData });
  };

  const handleOrderClick = (contextData: string) => {
    navigate("coverage", { state: contextData });
  };

  const handleChangeDescription = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setDescription(event.target.value);
  };

  const handleChangeIntent = (event: SelectChangeEvent) => {
    setSelectedIntent(event.target.value);
  };

  const handleChangePriority = (event: SelectChangeEvent) => {
    setSelectedPriority(event.target.value);
  };

  useEffect(() => {
    const deviceRequestResource = DeviceRequestResourceConstructor(
      selectedIntent,
      selectedPriority,
      description,
      selectedPatientId,
      "device_id"
    );

    const orderSignContext = {
      patientId: selectedPatientId,
      userId: "1895AD3",
      encounterId: "456",
      draftOrders: {
        resourceType: "Bundle",
        entry: [deviceRequestResource],
      },
    };

    dispatch(updateCdsHook("order-sign"));
    dispatch(updateCdsContext(orderSignContext));
  }, [
    dispatch,
    selectedIntent,
    selectedPriority,
    description,
    selectedPatientId,
  ]);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: expanded ? "column" : "row",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          width: expanded ? "100%" : "50%",
          overflowY: expanded ? "visible" : "hidden",
        }}
      >
        <img
          src="/gloco_meter.png"
          alt="drug"
          style={{
            width: expanded ? "80%" : "35%",
            height: expanded ? "80%" : "60%",
            marginLeft: expanded ? "10%" : "5%",
            marginTop: expanded ? "2%" : "2%",
            position: expanded ? "relative" : "fixed",
          }}
        />
      </div>

      <div
        style={{
          alignContent: "center",
          width: expanded ? "100%" : "50%",
          overflowY: "scroll",
          overflowX: "hidden",
          marginLeft: expanded ? SCREEN_WIDTH * 0.05 : 0,
          scrollbarWidth: "none", // for Firefox
          msOverflowStyle: "none", // for Internet Explorer and Edge
        }}
      >
        <Box fontSize={36} fontWeight={600} marginBottom={expanded ? 1 : 4}>
          {deviceName}
        </Box>
        <Box textAlign="justify" width="80%">
          {device?.large_description}
        </Box>

        <Box
          marginLeft={1}
          marginTop={2}
          display={"flex"}
          flexDirection={"row"}
        >
          <DropDownBox
            dropdown_label="Intent"
            dropdown_options={INTENT}
            selectedValue={selectedIntent}
            handleChange={handleChangeIntent}
            form_selector_width={SCREEN_WIDTH * 0.15}
          />

          <Box marginLeft={expanded ? 6 : 14} />
          <DropDownBox
            dropdown_label="Priority"
            dropdown_options={PRIORITY}
            selectedValue={selectedPriority}
            handleChange={handleChangePriority}
            form_selector_width={SCREEN_WIDTH * 0.15}
          />
        </Box>

        <TextField
          id="outlined-multiline-static"
          label="Usage Instructions"
          multiline
          rows={6}
          value={description}
          onChange={handleChangeDescription}
          sx={{
            marginLeft: 2,
            minWidth: expanded ? SCREEN_WIDTH * 0.35 : SCREEN_WIDTH * 0.4,
            marginTop: 2,
          }}
        />

        <div style={{ display: "flex", flexDirection: "row" }}>
          <Button
            variant="contained"
            onClick={() => handlePreviewClick("preview")}
            style={{
              borderRadius: "50px",
              marginLeft: expanded ? SCREEN_WIDTH * 0.2 : SCREEN_WIDTH * 0.25,
              marginTop: 20,
              backgroundColor: QUATERNARY_COLOR,
            }}
          >
            Preview
          </Button>
          <Button
            variant="contained"
            onClick={() => handleOrderClick("schedule")}
            style={{
              borderRadius: "50px",
              marginLeft: 20,
              marginTop: 20,
              backgroundColor: QUATERNARY_COLOR,
            }}
          >
            Order
          </Button>
        </div>
      </div>
    </div>
  );
}
