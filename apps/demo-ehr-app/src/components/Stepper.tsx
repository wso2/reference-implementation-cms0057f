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

import * as React from "react";
import Box from "@mui/material/Box";
import Stepper from "@mui/material/Stepper";
import Step from "@mui/material/Step";
import StepButton from "@mui/material/StepButton";
import { useDispatch, useSelector } from "react-redux";
import {
  resetCurrentRequest,
  updateCurrentHook,
  updateCurrentRequest,
  updateCurrentRequestMethod,
  updateCurrentRequestUrl,
  updateCurrentResponse,
  updateIsProcess,
} from "../redux/currentStateSlice";
import { useEffect } from "react";
import {
  StepStatus,
  Steps,
  updateStepsArray,
} from "../redux/commonStoargeSlice";
import {
  CDS_HOOK,
  CDS_REQUEST,
  CDS_REQUEST_METHOD,
  CDS_REQUEST_URL,
  CDS_RESPONSE,
  CLAIM_REQUEST,
  CLAIM_REQUEST_METHOD,
  CLAIM_REQUEST_URL,
  CLAIM_RESPONSE,
  CLAIM_PAYER_NOTIFICATION,
  MEDICATION_REQUEST,
  MEDICATION_REQUEST_METHOD,
  MEDICATION_REQUEST_URL,
  MEDICATION_RESPONSE,
  QUESTIONNAIRE_PACKAGE_REQUEST,
  QUESTIONNAIRE_PACKAGE_REQUEST_METHOD,
  QUESTIONNAIRE_PACKAGE_RESPONSE,
  QUESTIONNAIRE_PACKAGE_URL,
  QUESTIONNAIRE_RESPONSE,
  QUESTIONNAIRE_RESPONSE_METHOD,
  QUESTIONNAIRE_RESPONSE_REQUEST,
  QUESTIONNAIRE_RESPONSE_URL,
  STEPS,
} from "../constants/localStorageVariables";

type DevConsolePanelTheme = "dark" | "light";

export default function HorizontalNonLinearStepper({
  panelTheme = "light",
}: {
  panelTheme?: DevConsolePanelTheme;
}) {
  const dispatch = useDispatch();

  useEffect(() => {
    const stepsString = localStorage.getItem(STEPS);
    if (stepsString) {
      const parsed = JSON.parse(stepsString);
      if (parsed.length === 5) {
        parsed.push({ name: "Payer notification", status: StepStatus.NOT_STARTED });
      }
      dispatch(updateStepsArray(parsed));
    }
  }, [dispatch]);

  const stepsArray: Steps[] = useSelector(
    (state: any) => state.commonStoarge.stepsArray
  );

  const handleStep = (step: number) => () => {
    switch (step) {
      case 0: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const medicationRequestString =
          localStorage.getItem(MEDICATION_REQUEST);
        const medicationRequest = medicationRequestString
          ? JSON.parse(medicationRequestString)
          : {};
        dispatch(updateCurrentRequest(medicationRequest));

        const medicationResponseString =
          localStorage.getItem(MEDICATION_RESPONSE);
        const medicationResponse = medicationResponseString
          ? JSON.parse(medicationResponseString)
          : {};
        dispatch(updateCurrentResponse(medicationResponse));

        dispatch(
          updateCurrentRequestUrl(localStorage.getItem(MEDICATION_REQUEST_URL))
        );

        dispatch(
          updateCurrentRequestMethod(
            localStorage.getItem(MEDICATION_REQUEST_METHOD)
          )
        );
        break;
      }
      case 1: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const cdsRequestString = localStorage.getItem(CDS_REQUEST);
        const cdsRequest = cdsRequestString ? JSON.parse(cdsRequestString) : {};
        dispatch(updateCurrentRequest(cdsRequest));

        const cdsResponseString = localStorage.getItem(CDS_RESPONSE);
        const cdsResponse = cdsResponseString
          ? JSON.parse(cdsResponseString)
          : {};
        dispatch(updateCurrentResponse(cdsResponse));

        dispatch(
          updateCurrentRequestUrl(localStorage.getItem(CDS_REQUEST_URL))
        );
        dispatch(
          updateCurrentRequestMethod(localStorage.getItem(CDS_REQUEST_METHOD))
        );
        dispatch(updateCurrentHook(localStorage.getItem(CDS_HOOK)));

        break;
      }
      case 2: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const questionnaireRequestString = localStorage.getItem(
          QUESTIONNAIRE_PACKAGE_REQUEST
        );
        const questionnaireRequest = questionnaireRequestString
          ? JSON.parse(questionnaireRequestString)
          : {};
        dispatch(updateCurrentRequest(questionnaireRequest));

        const questionnaireResponseString = localStorage.getItem(
          QUESTIONNAIRE_PACKAGE_RESPONSE
        );
        const questionnaireResponse = questionnaireResponseString
          ? JSON.parse(questionnaireResponseString)
          : {};
        dispatch(updateCurrentResponse(questionnaireResponse));

        dispatch(
          updateCurrentRequestUrl(
            localStorage.getItem(QUESTIONNAIRE_PACKAGE_URL)
          )
        );
        dispatch(
          updateCurrentRequestMethod(
            localStorage.getItem(QUESTIONNAIRE_PACKAGE_REQUEST_METHOD)
          )
        );
        break;
      }
      case 3: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const questionnaireResponseRequestString = localStorage.getItem(
          QUESTIONNAIRE_RESPONSE_REQUEST
        );
        const questionnaireRequest = questionnaireResponseRequestString
          ? JSON.parse(questionnaireResponseRequestString)
          : {};
        dispatch(updateCurrentRequest(questionnaireRequest));

        const questionnaireResponseString = localStorage.getItem(
          QUESTIONNAIRE_RESPONSE
        );
        const questionnaireResponse = questionnaireResponseString
          ? JSON.parse(questionnaireResponseString)
          : {};
        dispatch(updateCurrentResponse(questionnaireResponse));

        dispatch(
          updateCurrentRequestUrl(
            localStorage.getItem(QUESTIONNAIRE_RESPONSE_URL)
          )
        );
        dispatch(
          updateCurrentRequestMethod(
            localStorage.getItem(QUESTIONNAIRE_RESPONSE_METHOD)
          )
        );
        break;
      }
      case 4: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const claimRequestString = localStorage.getItem(CLAIM_REQUEST);
        console.log(claimRequestString);
        const claimRequest = claimRequestString
          ? JSON.parse(claimRequestString)
          : {};
        dispatch(updateCurrentRequest(claimRequest));

        const claimResponseString = localStorage.getItem(CLAIM_RESPONSE);
        const claimResponse = claimResponseString
          ? JSON.parse(claimResponseString)
          : {};
        dispatch(updateCurrentResponse(claimResponse));

        dispatch(
          updateCurrentRequestUrl(localStorage.getItem(CLAIM_REQUEST_URL))
        );
        dispatch(
          updateCurrentRequestMethod(localStorage.getItem(CLAIM_REQUEST_METHOD))
        );
        break;
      }
      case 5: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        dispatch(
          updateCurrentRequest({
            "(no outbound request)": "Received from payer via webhook",
          })
        );

        const payerNotificationString =
          localStorage.getItem(CLAIM_PAYER_NOTIFICATION);
        const payerNotification = payerNotificationString
          ? JSON.parse(payerNotificationString)
          : {};
        dispatch(updateCurrentResponse(payerNotification));

        dispatch(
          updateCurrentRequestUrl("Payer notification (received via webhook)")
        );
        dispatch(updateCurrentRequestMethod("N/A"));
        break;
      }
      default: {
        break;
      }
    }
  };

  const [currentStep, setCurrentStep] = React.useState(-1);
  const globalActiveStep = useSelector(
    (state: any) => state.commonStoarge.activeStep
  );

  useEffect(() => {
    setCurrentStep(globalActiveStep);
  }, [globalActiveStep]);

  const labelActive =
    panelTheme === "light" ? "rgba(15,23,42,0.92)" : "rgba(255,255,255,0.92)";
  const labelMuted =
    panelTheme === "light" ? "rgba(15,23,42,0.62)" : "rgba(255,255,255,0.62)";
  const connectorColor =
    panelTheme === "light" ? "rgba(15,23,42,0.22)" : "rgba(255,255,255,0.35)";

  return (
    <Box
      sx={{
        marginBottom: "12px",
        paddingLeft: "4px",
        paddingRight: "4px",
      }}
    >
      <Stepper
        alternativeLabel
        nonLinear
        activeStep={currentStep}
        sx={{
          width: "100%",
          alignItems: "flex-start",
          "& .MuiStepConnector-line": {
            borderColor: connectorColor,
            borderTopWidth: 2,
          },
          "& .MuiStepConnector-root.Mui-active .MuiStepConnector-line, & .MuiStepConnector-root.Mui-completed .MuiStepConnector-line":
            {
              borderColor: panelTheme === "light" ? "#1976d2" : "#90caf9",
            },
          "& .MuiStepLabel-labelContainer": {
            minHeight: 52,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            width: "100%",
          },
          "& .MuiStepLabel-label": {
            color: labelActive,
            textAlign: "center",
            lineHeight: 1.25,
            whiteSpace: "normal",
            fontSize: "0.72rem",
            fontWeight: 600,
            maxWidth: "6.8rem",
          },
        }}
      >
        {stepsArray.map((step, index) => (
          <Step
            key={step.name}
            completed={step.status == StepStatus.COMPLETED}
            sx={{
              flex: "1 1 0",
              minWidth: 0,
              px: 0.125,
            }}
          >
            <StepButton
              disableRipple
              disabled={step.status == StepStatus.NOT_STARTED}
              onClick={handleStep(index)}
              sx={{
                width: "100%",
                py: 0.5,
                px: 0.25,
                borderRadius: 1,
                "&:hover": {
                  backgroundColor:
                    panelTheme === "light"
                      ? "rgba(15,23,42,0.04)"
                      : "rgba(255,255,255,0.06)",
                },
                "&.Mui-disabled": {
                  backgroundColor: "transparent !important",
                  opacity: 1,
                },
                "& .MuiStepLabel-label": {
                  color:
                    step.status === StepStatus.NOT_STARTED ? labelMuted : labelActive,
                },
                "&.Mui-disabled .MuiStepLabel-label": {
                  color: labelMuted,
                },
              }}
            >
              {step.name}
            </StepButton>
          </Step>
        ))}
      </Stepper>
    </Box>
  );
}
