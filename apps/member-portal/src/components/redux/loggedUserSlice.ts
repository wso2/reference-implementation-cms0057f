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

const initialState = {
  username: "",
  first_name: "",
  last_name: "",
  id:"",
};

const loggedUserSlice = createSlice({
  name: "loggedUser",
  initialState,
  reducers: {
    updateLoggedUser(state, action) {
      state.username = action.payload.username;
      state.first_name = action.payload.first_name;
      state.last_name = action.payload.last_name;
      state.id = action.payload.id;
    },
    resetLoggedUser() {
      return initialState;
    },
  },
});

export const { updateLoggedUser, resetLoggedUser } = loggedUserSlice.actions;
export default loggedUserSlice.reducer;
