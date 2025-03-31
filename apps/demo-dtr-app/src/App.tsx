import './App.css'
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from './components/AuthProvider';
import DrugPiorAuthPage from './pages/drug_prior_auth';
import { Provider } from 'react-redux';
import { ExpandedContextProvider } from "./utils/expanded_context.tsx";
import { PersistGate } from "redux-persist/integration/react";
import { store, persistor } from "./redux/store.ts";
import LoginPage from './pages/login_v2';

// Extend the Window interface to include the Config property
declare global {
  interface Window {
    Config: {
      baseUrl: string;
      demoBaseUrl: string;
      medication_request: string;
      prescribe_medication: string;
      questionnaire_package: string;
      questionnaire_response: string;
      claim_submit: string;
      radiology_order: string;
      book_imaging_center: string;
      practitioner: string;
      practitioner_new: string;
      slot: string;
      location: string;
      appointment: string;
      patient: string;
      medicationRequest: string;
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
              <Routes>
                <Route path="/" element={<DrugPiorAuthPage />} />
                <Route path="/login" element={<LoginPage />} />
              </Routes>
            </AuthProvider>
          </BrowserRouter>
        </ExpandedContextProvider>
      </PersistGate>
    </Provider>
  )
}

export default App
