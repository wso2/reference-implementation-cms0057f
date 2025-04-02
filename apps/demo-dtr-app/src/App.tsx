/**
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import './App.css'
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from './components/AuthProvider';
import DrugPiorAuthPage from './pages/drug_prior_auth';
import { Provider } from 'react-redux';
import { ExpandedContextProvider } from "./utils/expanded_context.tsx";
import { PersistGate } from "redux-persist/integration/react";
import { store, persistor } from "./redux/store.ts";
import LoginPage from './pages/login_v2';
import MissingParamPage from './pages/missing_param';
import NavBar from './components/NavBar';

// Extend the Window interface to include the Config property
declare global {
  interface Window {
    Config: {
      baseUrl: string;
      demoBaseUrl: string;
      medication_request: string;
      questionnaire_package: string;
      questionnaire_response: string;
      patient: string;
      medicationRequest: string;
      ehr_baseUrl: string;
    };
  }
}

function App() {
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <ExpandedContextProvider>
          <BrowserRouter>
            <AuthProvider>
              <div style={{ width: "100vw", height: "100vh", backgroundColor: "#f0f0f0" }}>
                <NavBar />
                <div
                  style={{
                    width: "80vw",
                    margin: "auto",
                    marginTop: "30px",
                    border: "1px solid #ccc",
                    borderRadius: "8px",
                    overflow: "hidden",
                    boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)",
                  }}
                >
                  <div
                    style={{
                      width: "100%",
                      height: "85vh",
                      overflow: "auto",
                      backgroundColor: "#f9f9f9",
                    }}
                  >
                    <Routes>
                      <Route path="/" element={<DrugPiorAuthPage />} />
                      <Route path="/login" element={<LoginPage />} />
                      <Route path="/invalid-req" element={<MissingParamPage />} />
                    </Routes>
                  </div>
                </div>
              </div>
            </AuthProvider>
          </BrowserRouter>
        </ExpandedContextProvider>
      </PersistGate>
    </Provider>
  )
}

export default App;
