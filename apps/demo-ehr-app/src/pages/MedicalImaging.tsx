// Copyright (c) 2024 - 2025, WSO2 LLC. (http://www.wso2.com).
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
  Button,
  SelectChangeEvent,
  CardActions,
  CardContent,
  Typography,
  Box,
  CardHeader,
  Alert,
} from "@mui/material";
import {
  DatePicker,
  DateValidationError,
  PickerChangeHandlerContext,
} from "@mui/x-date-pickers";
import { DropDownBox } from "../components/dropDown";
import { SCREEN_WIDTH, SCREEN_HEIGHT } from "../constants/page";
import { useContext, useEffect, useState } from "react";
import { updateCdsHook, updateRequest } from "../redux/cdsRequestSlice";
import { Dayjs } from "dayjs";
import { useDispatch, useSelector } from "react-redux";
import { Link } from "react-router-dom";
import { LAB_TEST, ORDER_SIGN_CDS_REQUEST2 } from "../constants/data";
import { ExpandedContext } from "../utils/expanded_context";
import { Card } from "@chakra-ui/react";
import axios from "axios";
import { updateCdsResponse } from "../redux/cdsResponseSlice";
import MedicalImagingSign from "./MedicalImagingSign";
import { baseUrl, paths } from "../config/urlConfigs";

interface Coding {
  id?: string;
  extension?: object;
  system?: string;
  version?: string;
  code?: string;
  display?: string;
  userSelected?: boolean;
}

enum ActionType {
  CREATE = "create",
  UPDATE = "update",
  DELETE = "delete",
}

interface Action {
  type: ActionType;
  description: string;
  resource?: object;
  resourceId?: string;
}

interface Source {
  label: string;
  url?: string;
  icon?: string;
  topic?: Coding;
}

interface Suggestion {
  label: string;
  uuid?: string;
  isRecommended?: boolean;
  actions?: Action[];
}

enum LinkType {
  ABSOLUTE = "absolute",
  SMART = "smart",
}

export interface CdsLink {
  label: string;
  url: string;
  type: LinkType;
  appContext?: string;
}

export interface CdsCard {
  uuid?: string;
  summary: string;
  detail?: string;
  indicator: string;
  source: Source;
  suggestions?: Suggestion[];
  selectionBehavior?: string;
  overrideReason?: Coding[];
  links?: CdsLink[];
}

export interface CdsResponse {
  cards: CdsCard[];
  systemActions?: Action[];
}

function MedicalImaging() {
  const form_selector_width = SCREEN_WIDTH * 0.3;
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();
  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );

  const [selectedTestType, setSelectedTestType] = useState("");
  const [selectedArea, setSelectedArea] = useState("");
  const [selectedDate, setSelectedDate] = useState<Dayjs | null>(null);
  const [selectedSlots, setSelectedSlots] = useState("");
  const [selectedTreatingDisease, setSelectedTreatingDisease] = useState("");

  const [isTestTypeChanged, setIsTestTypeChanged] = useState(false);
  const [isSelectedAreaChanged, setIsSelectedAreaChanged] = useState(false);
  const [isSelectedDateChanged, setIsSelectedDateChanged] = useState(false);
  const [isSelectedSlotsChanged, setIsSelectedSlotsChanged] = useState(false);
  const [
    isSelectedTreatingDiseaseChanged,
    setIsSelectedTreatingDiseaseChanged,
  ] = useState(false);

  const [enableSubmitButton, setEnableSubmitButton] = useState(false);
  const [enableNextStep, setEnableNextStep] = useState(false);
  const [isCrdCheckFinished, setCrdCheckFinished] = useState(false);
  const [cdsCards, setCdsCards] = useState<CdsCard[]>([]);

  const validateError = (
    <>
      <Alert severity="error" sx={{ marginLeft: 1 }}>
        This is an mandotary field.
      </Alert>
    </>
  );

  const [patientId] = useState("PA2347");
  const [practionerId] = useState("PT567498");

  const handleChangeTestType = (event: SelectChangeEvent) => {
    setSelectedTestType(event.target.value);
    setCrdCheckFinished(false);
  };

  const handleChangeArea = (event: SelectChangeEvent) => {
    setSelectedArea(event.target.value);
    setCrdCheckFinished(false);
  };

  const handleDateChange = (
    date: Dayjs | null,
    _context: PickerChangeHandlerContext<DateValidationError>
  ) => {
    setSelectedDate(date);
    setCrdCheckFinished(false);
  };

  const handleChangeSlots = (event: SelectChangeEvent) => {
    setSelectedSlots(event.target.value);
    setCrdCheckFinished(false);
  };

  const handleChangeTreatingDisease = (event: SelectChangeEvent) => {
    setSelectedTreatingDisease(event.target.value);
    setCrdCheckFinished(false);
  };

  const handleOnBlurTestType = () => {
    setIsTestTypeChanged(true);
  };

  const handleOnBlurArea = () => {
    setIsSelectedAreaChanged(true);
  };

  const handleOnBlurDate = () => {
    setIsSelectedDateChanged(true);
  };

  const handleOnBlurSlots = () => {
    setIsSelectedSlotsChanged(true);
  };

  const handleOnTreatingDisease = () => {
    setIsSelectedTreatingDiseaseChanged(true);
  };

  const handleScheduleClick = () => {
    setEnableNextStep(true);
  };

  const handleCrdCheck = () => {
    const payload = ORDER_SIGN_CDS_REQUEST2(
      patientId,
      practionerId,
      selectedDate?.format("YYYY-MM-DD"),
      selectedSlots
    );

    setCdsCards([]);
    setEnableSubmitButton(false);
    axios
      .post<CdsResponse>(baseUrl + paths.radiology_order, payload)
      .then<CdsResponse>((res) => {
        setCdsCards(res.data.cards);

        dispatch(
          updateCdsResponse({ cards: res.data.cards, systemActions: {} })
        );

        setEnableSubmitButton(true);
        setCrdCheckFinished(true);
        return res.data;
      })
      .catch((err) => console.log(err));
  };

  const isFormValid = () => {
    return (
      selectedTestType != "" &&
      selectedArea != "" &&
      selectedDate != null &&
      selectedSlots != "" &&
      selectedTreatingDisease != ""
    );
  };

  useEffect(() => {
    let formattedDate = selectedDate?.format("YYYY-MM-DD");
    if (!formattedDate) {
      formattedDate = "";
    }

    const a = ORDER_SIGN_CDS_REQUEST2(
      patientId,
      practionerId,
      selectedDate?.format("YYYY-MM-DD"),
      selectedSlots
    );
    console.log(a);

    dispatch(updateCdsHook("order-sign"));
    dispatch(updateRequest(a));
  }, [
    selectedSlots,
    selectedTreatingDisease,
    selectedPatientId,
    selectedDate,
    dispatch,
  ]);

  return (
    <>
      <div
        style={{
          display: "flex",
          flexDirection: expanded ? "column" : "row",
        }}
      >
        <Box boxShadow={enableNextStep ? 3 : 0}>
          <div
            style={{
              display: "flex",
              flexDirection: expanded ? "column" : "row",
            }}
          >
            {/* {expanded && (
              <img
                src={appointmentBookImg}
                alt="Healthcare"
                style={{
                  marginLeft: SCREEN_WIDTH * 0.05,
                  height: SCREEN_HEIGHT * 0.5,
                  width: SCREEN_WIDTH * 0.3,
                }}
              />
            )} */}

            <div style={{ marginLeft: 80 }}>
              <div
                style={{
                  fontSize: 35,
                  fontWeight: 700,
                  marginBottom: 30,
                  marginLeft: 10,
                }}
              >
                Book Medical Imaging
              </div>

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
                isDisabled={enableNextStep}
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
                isDisabled={enableNextStep}
              />
              {isSelectedAreaChanged && selectedArea === "" && validateError}

              <div style={{ marginLeft: 8, marginBottom: 10, marginTop: 10 }}>
                <DatePicker
                  sx={{ minWidth: form_selector_width }}
                  value={selectedDate}
                  onChange={handleDateChange}
                  onClose={handleOnBlurDate}
                  disabled={enableNextStep}
                />
              </div>
              {isSelectedDateChanged && selectedDate === null && validateError}

              <DropDownBox
                dropdown_label="Slots *"
                dropdown_options={LAB_TEST.timeSlots}
                selectedValue={selectedSlots}
                handleChange={handleChangeSlots}
                handleOnBlur={handleOnBlurSlots}
                form_selector_width={form_selector_width}
                borderColor={
                  isSelectedSlotsChanged && selectedSlots === "" ? "red" : ""
                }
                isDisabled={enableNextStep}
              />
              {isSelectedSlotsChanged && selectedSlots === "" && validateError}

              <DropDownBox
                dropdown_label="Treating *"
                dropdown_options={LAB_TEST.diseases}
                selectedValue={selectedTreatingDisease}
                handleChange={handleChangeTreatingDisease}
                handleOnBlur={handleOnTreatingDisease}
                form_selector_width={form_selector_width}
                borderColor={
                  isSelectedTreatingDiseaseChanged &&
                  selectedTreatingDisease === ""
                    ? "red"
                    : ""
                }
                isDisabled={enableNextStep}
              />
              {isSelectedTreatingDiseaseChanged &&
                selectedTreatingDisease === "" &&
                validateError}

              <div style={{ display: "flex", flexDirection: "row" }}>
                <Button
                  variant="contained"
                  onClick={() => handleCrdCheck()}
                  disabled={!isFormValid() || isCrdCheckFinished}
                  style={{
                    borderRadius: 20,
                    marginTop: 20,
                  }}
                >
                  Check Payer Requirements
                </Button>
                <Button
                  variant="contained"
                  onClick={() => handleScheduleClick()}
                  disabled={!enableSubmitButton || enableNextStep}
                  style={{
                    borderRadius: 20,
                    marginLeft: 20,
                    marginTop: 20,
                  }}
                >
                  Assign imaging center
                </Button>
              </div>
            </div>

            <div
              style={{
                marginLeft: SCREEN_WIDTH * 0.1,
                marginTop: SCREEN_HEIGHT * 0.07,
              }}
            >
              {!expanded && !enableNextStep && (
                <img
                  src="/imaging_center.webp"
                  alt="Healthcare"
                  style={{
                    marginLeft: SCREEN_WIDTH * 0.05,
                    width: 400,
                    height: 400,
                    borderRadius: 15,
                  }}
                />
              )}

              <div
                style={{
                  marginTop: expanded ? -40 : 10,
                  marginLeft: expanded ? -40 : 0,
                }}
              ></div>
            </div>
          </div>
          <Box sx={{ display: "flex", flexDirection: "row" }} padding={10}>
            {cdsCards.length > 0 &&
              cdsCards.map((card) => (
                <Box sx={{ boxShadow: 2, borderRadius: 3, marginRight: 2 }}>
                  <Card variant="outlined" width={310}>
                    <CardHeader
                      title={card.summary}
                      subheader={card.indicator}
                    />
                    <CardContent>
                      <Typography
                        gutterBottom
                        sx={{ color: "text.secondary", fontSize: 14, mb: 3 }}
                      >
                        {card.detail}
                      </Typography>
                      <Typography variant="h6" component="div">
                        Suggestions
                      </Typography>
                      <Typography sx={{ color: "text.secondary", mb: 1.5 }}>
                        {card.selectionBehavior}
                      </Typography>
                      <Typography variant="body2">
                        <ul>
                          {card.suggestions?.map((suggestion) => (
                            <li>{suggestion.label}</li>
                          ))}
                        </ul>
                      </Typography>
                    </CardContent>
                    {card.links != null && (
                      <CardActions>
                        <Link target="_blank" to={"prior-auth"}>
                          Apply
                        </Link>
                      </CardActions>
                    )}
                  </Card>
                </Box>
              ))}
          </Box>
        </Box>
        <Box boxShadow={3} marginLeft={1}>
          {enableNextStep && <MedicalImagingSign />}
        </Box>
      </div>
    </>
  );
}

export default MedicalImaging;
