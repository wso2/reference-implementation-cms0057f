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

import { configureStore } from "@reduxjs/toolkit";
import { persistStore, persistReducer, FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER } from "redux-persist";
import patientReducer from "./patientSlice";
import cdsRequestSlice from "./cdsRequestSlice";
import cdsResponseSlice from "./cdsResponseSlice";
import medicationFormDataReducer from "./medicationFormDataSlice";
import loggedUserSlice from "./loggedUserSlice";
import commonStoargeSlice from "./commonStoargeSlice";
import currentStateSlice from "./currentStateSlice";

const createNoopStorage = () => ({
  getItem: async (_key: string) => null,
  setItem: async (_key: string, value: string) => value,
  removeItem: async (_key: string) => undefined,
});

const createBrowserStorage = () => {
  try {
    if (typeof window !== "undefined" && window.localStorage) {
      return {
        getItem: async (key: string) => window.localStorage.getItem(key),
        setItem: async (key: string, value: string) => {
          window.localStorage.setItem(key, value);
          return value;
        },
        removeItem: async (key: string) => {
          window.localStorage.removeItem(key);
        },
      };
    }
  } catch {
    // Fall through to no-op storage.
  }

  return createNoopStorage();
};

const storage = createBrowserStorage();

const persistConfig = {
  key: "root",
  storage,
};

const persistedReducer = persistReducer(
  persistConfig,
  medicationFormDataReducer
);

const store = configureStore({
  reducer: {
    patient: patientReducer,
    cdsRequest: cdsRequestSlice,
    cdsResponse: cdsResponseSlice,
    medicationFormData: persistedReducer,
    loggedUser: loggedUserSlice,
    currentState: currentStateSlice,
    commonStoarge: commonStoargeSlice,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
      },
    }),
});

const persistor = persistStore(store);

export { store, persistor };
