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

import { createSlice } from "@reduxjs/toolkit";

export enum StepStatus {
  NOT_STARTED,
  IN_PROGRESS,
  COMPLETED,
}

export interface Steps {
  name: string;
  status: StepStatus;
}

const steps: Steps[] = [
  { name: "Medication request", status: StepStatus.NOT_STARTED },
  { name: "Check Payer Requirements", status: StepStatus.NOT_STARTED },
  { name: "Questionnaire package", status: StepStatus.NOT_STARTED },
  { name: "Questionnaire Response", status: StepStatus.NOT_STARTED },
  { name: "Claim Submit", status: StepStatus.NOT_STARTED },
];

const initialState = {
  activeStep: -1,
  stepsArray: steps,
};

const commonStoargeSlice = createSlice({
  name: "commonStoarge",
  initialState,
  reducers: {
    updateActiveStep(state, action) {
      state.activeStep = action.payload;
      localStorage.setItem("activeStep", action.payload);
    },
    updateStepsArray(state, action) {
      state.stepsArray = action.payload;
      localStorage.setItem("steps", JSON.stringify(state.stepsArray));
    },
    updateSingleStep(state, action) {
      state.stepsArray = state.stepsArray.map((step: Steps) =>
        step.name === action.payload.stepName
          ? { ...step, status: action.payload.newStatus }
          : step
      );
      console.log(state.stepsArray);
      localStorage.setItem("steps", JSON.stringify(state.stepsArray));
    },
    resetCommonStorage() {
      return initialState;
    },
  },
});

export const {
  resetCommonStorage,
  updateActiveStep,
  updateStepsArray,
  updateSingleStep,
} = commonStoargeSlice.actions;
export default commonStoargeSlice.reducer;
