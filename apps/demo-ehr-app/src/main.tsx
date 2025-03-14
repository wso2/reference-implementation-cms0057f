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

import ReactDOM from "react-dom/client";
import { ExpandedContextProvider } from "./utils/expanded_context.tsx";
import PatientEncounter from "./pages/patient_encounter_start.tsx";
import PractionerDashBoard from "./pages/practitioner_dashboard.tsx";
import AppointmentBookPage from "./pages/appointment_book_page.tsx";
import AppointmentReceipt from "./components/appointment_receipt.tsx";
import DrugOrderPage from "./pages/drug_order_page.tsx";
import DrugOrderPageV2 from "./pages/drug_order_page_v2.tsx";
import { DrugDetailsPage } from "./pages/drug_details_page.tsx";
import DeviceOrderPage from "./pages/device_order_page.tsx";
import { DeviceDetailsPage } from "./pages/device_details_page.tsx";
import { PatientViewPage } from "./pages/patient_view.tsx";
import { CoverageCardDisplayPage } from "./pages/coverage_card_display_page.tsx";
import { Layout } from "./components/layout.tsx";
import { Provider } from "react-redux";
import { PersistGate } from "redux-persist/integration/react";
import { store, persistor } from "./redux/store.ts";
import "./index.css";
import { BrowserRouter } from "react-router-dom";
import { Routes, Route } from "react-router-dom";
import { LocalizationProvider } from "@mui/x-date-pickers";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import MedicalImaging from "./pages/MedicalImaging.tsx";
import PriorAuth from "./pages/PriorAuth.tsx";
import DrugPiorAuthPage from "./pages/drug_prior_auth.tsx";
import DeviceOrderPageV2 from "./pages/device_order_page_v2.tsx";
import DrugClaimPage from "./pages/drug_claim_page.tsx";
import Login from "./pages/login.tsx";
import { AuthProvider } from "./components/AuthProvider.tsx";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <Provider store={store}>
    <PersistGate loading={null} persistor={persistor}>
      <ExpandedContextProvider>
        <LocalizationProvider dateAdapter={AdapterDayjs}>
          <BrowserRouter>
            <AuthProvider>
              <Routes>
                <Route path="/login" element={<Login />} />
                <Route path="/" element={<PatientEncounter />} />
                <Route path="dashboard/*" element={<Layout />}>
                  <Route index element={<PractionerDashBoard />} />
                  <Route path="medical-imaging" element={<MedicalImaging />} />
                  <Route
                    path="medical-imaging/prior-auth"
                    element={<PriorAuth />}
                  />
                  <Route
                    path="appointment-schedule"
                    element={<AppointmentBookPage />}
                  />
                  <Route
                    path="appointment-receipt"
                    element={<AppointmentReceipt />}
                  />
                  <Route
                    path="appointment-schedule/coverage-preview"
                    element={<CoverageCardDisplayPage />}
                  />
                  <Route
                    path="appointment-schedule/coverage"
                    element={<CoverageCardDisplayPage />}
                  />
                  <Route path="drug-order" element={<DrugOrderPage />} />
                  <Route path="drug-order-v2" element={<DrugOrderPageV2 />} />
                  <Route
                    path="drug-order-v2/prior-auth/*"
                    element={<DrugPiorAuthPage />}
                  />
                  <Route
                    path="drug-order-v2/claim-submit/*"
                    element={<DrugClaimPage />}
                  />
                  <Route
                    path="drug-order/:drugName"
                    element={<DrugDetailsPage />}
                  />
                  <Route
                    path="drug-order/:drugName/coverage-preview"
                    element={<CoverageCardDisplayPage />}
                  />
                  <Route
                    path="drug-order/:drugName/coverage"
                    element={<CoverageCardDisplayPage />}
                  />
                  <Route path="device-order" element={<DeviceOrderPage />} />
                  <Route
                    path="device-order-v2"
                    element={<DeviceOrderPageV2 />}
                  />
                  <Route
                    path="device-order/:deviceName"
                    element={<DeviceDetailsPage />}
                  />
                  <Route
                    path="device-order/:deviceName/coverage-preview"
                    element={<CoverageCardDisplayPage />}
                  />
                  <Route
                    path="device-order/:deviceName/coverage"
                    element={<CoverageCardDisplayPage />}
                  />
                  <Route path="patient" element={<PatientViewPage />} />
                </Route>

                <Route path="settings" element={<div>Not Implemented</div>} />
              </Routes>
            </AuthProvider>
          </BrowserRouter>
        </LocalizationProvider>
      </ExpandedContextProvider>
    </PersistGate>
  </Provider>
);
