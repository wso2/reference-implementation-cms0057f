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
import { IS_PROCESS } from "../constants/localStorageVariables";

const initialState = {
  request: {},
  response: {},
  requestUrl: "",
  requestMethod: "",
  hook: "",
  isProcess: false,
};

const currentStateSlice = createSlice({
  name: "currentState",
  initialState,
  reducers: {
    updateCurrentRequest(state, action) {
      state.request = action.payload;
    },
    updateCurrentResponse(state, action) {
      state.response = action.payload;
    },
    updateCurrentRequestUrl(state, action) {
      state.requestUrl = action.payload;
    },
    updateCurrentRequestMethod(state, action) {
      state.requestMethod = action.payload;
    },
    updateCurrentHook(state, action) {
      state.hook = action.payload;
    },
    updateIsProcess(state, action) {
      state.isProcess = action.payload;
      localStorage.setItem(IS_PROCESS, action.payload);
    },
    resetCurrentRequest() {
      return initialState;
    },
  },
});

export const {
  resetCurrentRequest,
  updateCurrentRequest,
  updateCurrentResponse,
  updateCurrentRequestUrl,
  updateCurrentRequestMethod,
  updateCurrentHook,
  updateIsProcess,
} = currentStateSlice.actions;
export default currentStateSlice.reducer;
