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

import { createSlice } from "@reduxjs/toolkit";
import { v4 as uuidv4 } from "uuid";

const initialState = {
  hook: "",
  hookInstance: uuidv4(),
  context: {},
  prefetch: {},
  request: {},
  requestUrl: "",
  requestMethod: "",
};

const cdsRequestSlice = createSlice({
  name: "cdsRequest",
  initialState,
  reducers: {
    updateCdsHook(state, action) {
      state.hook = action.payload;
    },
    updateCdsContext(state, action) {
      state.context = { ...state.context, ...action.payload };
    },
    updateCdsPrefetch(state, action) {
      state.prefetch = { ...state.prefetch, ...action.payload };
    },
    updateRequest(state, action) {
      state.request = { ...state.request, ...action.payload };
    },
    updateRequestUrl(state, action) {
      state.requestUrl = action.payload;
    },
    updateRequestMethod(state, action) {
      state.requestMethod = action.payload;
    },
    resetCdsRequest() {
      return initialState;
    },
  },
});

export const {
  updateCdsHook,
  updateCdsContext,
  updateCdsPrefetch,
  resetCdsRequest,
  updateRequest,
  updateRequestUrl,
  updateRequestMethod,
} = cdsRequestSlice.actions;
export default cdsRequestSlice.reducer;
