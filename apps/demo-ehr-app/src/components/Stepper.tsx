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
  updateSingleStep,
  updateStepsArray,
} from "../redux/commonStoargeSlice";
import axios from "axios";
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
  SELECTED_PATIENT_ID,
  STEPS,
  TIMESTAMP,
} from "../constants/localStorageVariables";
import { HTTP_METHODS } from "../constants/enum";

export default function HorizontalNonLinearStepper() {
  const dispatch = useDispatch();

  useEffect(() => {
    const stepsString = localStorage.getItem(STEPS);
    if (stepsString) {
      updateStepsArray(JSON.parse(stepsString));
    }
  }, []);

  const stepsArray: Steps[] = useSelector(
    (state: any) => state.commonStoarge.stepsArray
  );

  const Config = window.Config;

  const patientId = localStorage.getItem(SELECTED_PATIENT_ID);
  const timestamp = localStorage.getItem(TIMESTAMP);

  const loadQuestionnaireResponse = () => {
    axios
      .get(
        Config.questionnaire_response +
          `?subject=Patient/${patientId}&authored=ge${timestamp}`
      )
      .then(async (response) => {
        if (response.data.entry.length > 0) {
          const questionnaireResponse = response.data.entry[0].resource;
          console.log(questionnaireResponse);
          if (questionnaireResponse) {
            localStorage.setItem(
              QUESTIONNAIRE_RESPONSE,
              JSON.stringify(questionnaireResponse)
            );

            const resource = questionnaireResponse;
            delete resource.id;
            delete resource.authored;
            localStorage.setItem(
              QUESTIONNAIRE_RESPONSE_REQUEST,
              JSON.stringify(resource)
            );

            localStorage.setItem(
              QUESTIONNAIRE_RESPONSE_METHOD,
              HTTP_METHODS.POST
            );
            localStorage.setItem(
              QUESTIONNAIRE_RESPONSE_URL,
              Config.demoBaseUrl + Config.questionnaire_response
            );
            dispatch(
              updateSingleStep({
                stepName: "Questionnaire Response",
                newStatus: StepStatus.COMPLETED,
              })
            );
          }
          return;
        } else {
          console.log("Else");
          localStorage.setItem(
            QUESTIONNAIRE_RESPONSE,
            JSON.stringify({
              message:
                "Cannot find a request payload. Make sure you submit the Answers to the questions",
            })
          );
          localStorage.setItem(
            QUESTIONNAIRE_RESPONSE_REQUEST,
            JSON.stringify({
              message:
                "Cannot find a request payload. Make sure you submit the Answers to the questions",
            })
          );

          localStorage.setItem(QUESTIONNAIRE_RESPONSE_METHOD, "");
          localStorage.setItem(QUESTIONNAIRE_RESPONSE_URL, "");
          return;
        }
      })
      .catch((error) => {
        console.error("Error fetching questionnaire:", error);
      });
  };

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
        loadQuestionnaireResponse();
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
    console.log(globalActiveStep);
    setCurrentStep(globalActiveStep);
  }, [globalActiveStep]);

  return (
    <Box
      sx={{
        marginBottom: "40px",
        paddingLeft: "10px",
        paddingRight: "10px",
        borderColor: "#000000",
      }}
    >
      <Stepper alternativeLabel nonLinear activeStep={currentStep}>
        {stepsArray.map((step, index) => (
          <Step key={step.name} completed={step.status == StepStatus.COMPLETED}>
            <StepButton
              disabled={step.status == StepStatus.NOT_STARTED}
              onClick={handleStep(index)}
            >
              {step.name}
            </StepButton>
          </Step>
        ))}
      </Stepper>
    </Box>
  );
}
