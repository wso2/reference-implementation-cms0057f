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
import ToggleGrpButton from "../components/toggleGrpButton";
import React, { useState, useEffect } from "react";
import { Box } from "@mui/material";
import { DRUG_DETAILS } from "../constants/data";
import { SCREEN_WIDTH } from "../constants/page";
import {
  NumberInput,
  NumberInputField,
  NumberInputStepper,
  NumberIncrementStepper,
  NumberDecrementStepper,
} from "@chakra-ui/react";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { DropDownBox } from "../components/dropDown";
import { SelectChangeEvent } from "@mui/material/Select";
import Button from "@mui/material/Button";
import { QUATERNARY_COLOR } from "../constants/color";
import { useContext } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { Dayjs } from "dayjs";
import { constructMedicationRequestResource } from "../utils/medication_request_resource_constructor";
import { useDispatch, useSelector } from "react-redux";
import { updateCdsHook, updateCdsContext } from "../redux/cdsRequestSlice";

export function DrugDetailsPage() {
  const { drugName } = useParams();
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );

  // In the actual implementation, this would be fetched from a backend API
  const drug = DRUG_DETAILS.find((drug) => drug.name === drugName);

  const [selectedDosage, setSelectedDosage] = useState("");
  const [selectedNumberOfTablets] = useState(0);
  const [selectedTime, setSelectedTime] = useState("");
  const [selectedFrequency, setSelectedFrequency] = useState("");
  const [selectedStartDate, setSelectedStartDate] = useState<Dayjs | null>(
    null
  );
  const [selectedEndDate, setSelectedEndDate] = useState<Dayjs | null>(null);

  const Times = ["Ten", "Twenty", "Thirty"];

  const Freqeuncies = ["Once a day", "Twice a day", "Thrice a day"];

  const handlePreviewClick = (contextData: string) => {
    navigate("coverage-preview", { state: contextData });
  };

  const handleOrderClick = (contextData: string) => {
    navigate("coverage", { state: contextData });
  };

  const handleStartDateChange = (date: Dayjs | null) => {
    setSelectedStartDate(date);
  };

  const handleEndDateChange = (date: Dayjs | null) => {
    setSelectedEndDate(date);
  };

  const handleChangeFrequency = (event: SelectChangeEvent) => {
    setSelectedFrequency(event.target.value);
  };

  const handleChangeTime = (event: SelectChangeEvent) => {
    setSelectedTime(event.target.value);
  };

  const handleDosageChange = (
    _event: React.MouseEvent<HTMLElement>,
    value: string
  ) => {
    setSelectedDosage(value);
  };

  useEffect(() => {
    let formattedStartDate = selectedStartDate?.format("YYYY-MM-DD");
    let formattedEndDate = selectedEndDate?.format("YYYY-MM-DD");

    if (!formattedEndDate) {
      formattedEndDate = "";
    }
    if (!formattedStartDate) {
      formattedStartDate = "";
    }

    const medicationRequest = constructMedicationRequestResource(
      drugName ? drugName : "",
      selectedDosage,
      selectedNumberOfTablets,
      formattedStartDate,
      formattedEndDate,
      selectedFrequency,
      selectedPatientId
    );

    const orderSignContext = {
      patientId: selectedPatientId,
      userId: "1895AD3",
      encounterId: "456",
      draftOrders: {
        resourceType: "Bundle",
        entry: [medicationRequest],
      },
    };

    dispatch(updateCdsHook("order-sign"));
    dispatch(updateCdsContext(orderSignContext));
  }, [
    dispatch,
    selectedDosage,
    selectedNumberOfTablets,
    selectedTime,
    selectedFrequency,
    selectedStartDate,
    selectedEndDate,
    drugName,
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
          src="/drug_1.png"
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
          {drugName}
        </Box>
        <Box textAlign="justify" width="80%">
          {drug?.large_description}
        </Box>

        <Box margin={4}>
          <ToggleGrpButton
            dosages={drug?.dosages || []}
            selectedDosage={selectedDosage}
            handleDosageChange={handleDosageChange}
          />
        </Box>

        <Box display="flex" marginLeft={2}>
          <div style={{ marginRight: SCREEN_WIDTH * 0.1 }}>
            <Box fontSize={18} marginBottom={1}>
              No. of Tablets
            </Box>
            <NumberInput
              maxW={50}
              defaultValue={0}
              min={0}
              max={10}
              fontSize={13}
              allowMouseWheel
            >
              <NumberInputField height={20} />
              <NumberInputStepper>
                <NumberIncrementStepper />
                <NumberDecrementStepper />
              </NumberInputStepper>
            </NumberInput>
          </div>

          <DropDownBox
            dropdown_label="Time"
            dropdown_options={Times}
            selectedValue={selectedTime}
            handleChange={handleChangeTime}
            form_selector_width={SCREEN_WIDTH * 0.11}
          />
        </Box>

        <Box marginLeft={1} marginTop={1}>
          <DropDownBox
            dropdown_label="Frequency"
            dropdown_options={Freqeuncies}
            selectedValue={selectedFrequency}
            handleChange={handleChangeFrequency}
            form_selector_width={SCREEN_WIDTH * 0.3}
          />
        </Box>

        <Box marginLeft={2} marginTop={2} display={"inline-flex"}>
          <Box display={"flex"} flexDirection={"column"}>
            Start Date
            <DatePicker
              sx={{ maxWidth: SCREEN_WIDTH * 0.15 }}
              value={selectedStartDate}
              onChange={handleStartDateChange}
            />
          </Box>
          <div style={{ width: "50px" }} />
          <Box display={"flex"} flexDirection={"column"}>
            End Date
            <DatePicker
              sx={{ maxWidth: SCREEN_WIDTH * 0.15 }}
              value={selectedEndDate}
              onChange={handleEndDateChange}
            />
          </Box>
        </Box>

        <div style={{ display: "flex", flexDirection: "row" }}>
          <Button
            variant="contained"
            onClick={() => handlePreviewClick("preview")}
            style={{
              borderRadius: "50px",
              marginLeft: SCREEN_WIDTH * 0.22,
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
