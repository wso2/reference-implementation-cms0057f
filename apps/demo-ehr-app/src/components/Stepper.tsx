import * as React from "react";
import Box from "@mui/material/Box";
import Stepper from "@mui/material/Stepper";
import Step from "@mui/material/Step";
import StepButton from "@mui/material/StepButton";
import { useDispatch, useSelector } from "react-redux";
import {
  resetCurrentRequest,
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

export default function HorizontalNonLinearStepper() {
  const dispatch = useDispatch();

  useEffect(() => {
    const stepsString = localStorage.getItem("steps");
    if (stepsString) {
      updateStepsArray(JSON.parse(stepsString));
    }
  }, []);

  const stepsArray: Steps[] = useSelector(
    (state: any) => state.commonStoarge.stepsArray
  );

  const Config = window.Config;

  const [activeStep, setActiveStep] = React.useState(-1);
  const patientId = localStorage.getItem("selectedPatientId");
  const timestamp = localStorage.getItem("timestamp");

  const loadQuestionnaireResponse = () => {
    axios
      .get(
        Config.questionnaire_response +
          `?subject=Patient/${patientId}&authored=ge${timestamp}`
      )
      .then(async (response) => {
        if (response.data.entry.length > 0) {
          console.log("IF");
          const questionnaireResponse = response.data.entry[0].resource;
          console.log(questionnaireResponse);
          if (questionnaireResponse) {
            console.log("Called");
            localStorage.setItem(
              "questionnaireResponse",
              JSON.stringify(questionnaireResponse)
            );

            const resource = questionnaireResponse;
            delete resource.id;
            delete resource.authored;
            localStorage.setItem(
              "questionnaireResponseRequest",
              JSON.stringify(resource)
            );

            localStorage.setItem("questionnaireResponseRequestMethod", "POST");
            localStorage.setItem(
              "questionnaireResponseUrl",
              Config.questionnaire_response
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
            "questionnaireResponse",
            JSON.stringify({
              message:
                "Cannot find a request payload. Make sure you submit the Answers to the questions",
            })
          );
          localStorage.setItem(
            "questionnaireResponseRequest",
            JSON.stringify({
              message:
                "Cannot find a request payload. Make sure you submit the Answers to the questions",
            })
          );

          localStorage.setItem("questionnaireResponseRequestMethod", "");
          localStorage.setItem("questionnaireResponseUrl", "");
          return;
        }
      })
      .catch((error) => {
        console.error("Error fetching questionnaire:", error);
      });
  };

  const handleStep = (step: number) => () => {
    setActiveStep(step);

    switch (step) {
      case 0: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const medicationRequestString =
          localStorage.getItem("medicationRequest");
        const medicationRequest = medicationRequestString
          ? JSON.parse(medicationRequestString)
          : {};
        dispatch(updateCurrentRequest(medicationRequest));

        const medicationResponseString =
          localStorage.getItem("medicationResponse");
        const medicationResponse = medicationResponseString
          ? JSON.parse(medicationResponseString)
          : {};
        dispatch(updateCurrentResponse(medicationResponse));

        dispatch(
          updateCurrentRequestUrl(localStorage.getItem("medicationRequestUrl"))
        );

        dispatch(
          updateCurrentRequestMethod(
            localStorage.getItem("medicationRequestMethod")
          )
        );
        break;
      }
      case 1: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const cdsRequestString = localStorage.getItem("cdsRequest");
        const cdsRequest = cdsRequestString ? JSON.parse(cdsRequestString) : {};
        dispatch(updateCurrentRequest(cdsRequest));

        const cdsResponseString = localStorage.getItem("cdsResponse");
        const cdsResponse = cdsResponseString
          ? JSON.parse(cdsResponseString)
          : {};
        dispatch(updateCurrentResponse(cdsResponse));

        dispatch(
          updateCurrentRequestUrl(localStorage.getItem("cdsRequestUrl"))
        );
        dispatch(
          updateCurrentRequestMethod(localStorage.getItem("cdsRequestMethod"))
        );
        dispatch(updateCurrentRequestMethod(localStorage.getItem("cdsHook")));

        break;
      }
      case 2: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const questionnaireRequestString = localStorage.getItem(
          "questionnairePackageRequest"
        );
        const questionnaireRequest = questionnaireRequestString
          ? JSON.parse(questionnaireRequestString)
          : {};
        dispatch(updateCurrentRequest(questionnaireRequest));

        const questionnaireResponseString = localStorage.getItem(
          "questionnairePackageResponse"
        );
        const questionnaireResponse = questionnaireResponseString
          ? JSON.parse(questionnaireResponseString)
          : {};
        dispatch(updateCurrentResponse(questionnaireResponse));

        dispatch(
          updateCurrentRequestUrl(
            localStorage.getItem("questionnairePackageUrl")
          )
        );
        dispatch(
          updateCurrentRequestMethod(
            localStorage.getItem("questionnairePackageRequestMethod")
          )
        );
        break;
      }
      case 3: {
        loadQuestionnaireResponse();
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const questionnaireResponseRequestString = localStorage.getItem(
          "questionnaireResponseRequest"
        );
        const questionnaireRequest = questionnaireResponseRequestString
          ? JSON.parse(questionnaireResponseRequestString)
          : {};
        dispatch(updateCurrentRequest(questionnaireRequest));

        const questionnaireResponseString = localStorage.getItem(
          "questionnaireResponse"
        );
        const questionnaireResponse = questionnaireResponseString
          ? JSON.parse(questionnaireResponseString)
          : {};
        dispatch(updateCurrentResponse(questionnaireResponse));

        dispatch(
          updateCurrentRequestUrl(
            localStorage.getItem("questionnaireResponseUrl")
          )
        );
        dispatch(
          updateCurrentRequestMethod(
            localStorage.getItem("questionnaireResponseRequestMethod")
          )
        );
        break;
      }
      case 4: {
        dispatch(resetCurrentRequest());
        dispatch(updateIsProcess(true));

        const claimRequestString = localStorage.getItem("claimRequest");
        console.log(claimRequestString);
        const claimRequest = claimRequestString
          ? JSON.parse(claimRequestString)
          : {};
        dispatch(updateCurrentRequest(claimRequest));

        const claimResponseString = localStorage.getItem("claimResponse");
        const claimResponse = claimResponseString
          ? JSON.parse(claimResponseString)
          : {};
        dispatch(updateCurrentResponse(claimResponse));

        dispatch(
          updateCurrentRequestUrl(localStorage.getItem("claimRequestUrl"))
        );
        dispatch(
          updateCurrentRequestMethod(localStorage.getItem("claimRequestMethod"))
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
