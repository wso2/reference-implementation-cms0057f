// Copyright (c) 2024-2025, WSO2 LLC. (http://www.wso2.com).
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

import {
  createContext,
  useContext,
  useState,
  ReactNode,
  useEffect,
} from "react";
import { useLocation, useNavigate } from "react-router-dom";

interface AuthContextType {
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);
const POST_LOGIN_REDIRECT_KEY = "dtrPostLoginRedirect";

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const location = useLocation();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const navigate = useNavigate();
  const originalPath = location.pathname;
  const originalSearch = location.search;

  const query = useQuery();

  const getAuthenticationIfo = async () => {
    const response = await fetch("/auth/userinfo");

    saveQueryParamsToSessionStorage();

    if (response.status == 200) {
      const isAuthPopupWindow =
        !!window.opener && window.name === "dtr-auth-popup";

      if (isAuthPopupWindow) {
        // Notify the opener iframe page and close popup automatically.
        window.opener.postMessage({ type: "DTR_AUTH_SUCCESS" }, "*");
        window.close();
        return;
      }

      setIsAuthenticated(true);
      const storedRedirect = sessionStorage.getItem(POST_LOGIN_REDIRECT_KEY);
      const redirectTo =
        originalPath === "/login"
          ? (storedRedirect || "/")
          : `${originalPath || "/"}${originalSearch || ""}`;
      sessionStorage.removeItem(POST_LOGIN_REDIRECT_KEY);
      navigate(redirectTo, { replace: true });
    } else {
      setIsAuthenticated(false);
      // Preserve the launch route (with query params) so we can restore
      // the iframe URL after completing login in a popup.
      if (originalPath !== "/login" && originalPath !== "/fetching") {
        sessionStorage.setItem(
          POST_LOGIN_REDIRECT_KEY,
          `${originalPath || "/"}${originalSearch || ""}`
        );
      }
      navigate("/login");
    }
  };

  const saveQueryParamsToSessionStorage = () => {
    const coverageId = query.get("coverageId");
    const medicationRequestId = query.get("medicationRequestId");
    const serviceRequestId = query.get("serviceRequestId");
    const questionnaire = query.get("questionnaire");
    const patientId = query.get("patientId");

    // Mandatory: patientId must always be present.
    // Flow 1: coverageId and medicationRequestId (standard drug flow)
    // Flow 2: questionnaire (MRI flow)
    const isStandardFlow = coverageId && medicationRequestId;
    const isQuestionnaireFlow = questionnaire;

    if (!patientId || (!isStandardFlow && !isQuestionnaireFlow)) {
      navigate("/fetching");
      return;
    }

    if (coverageId) sessionStorage.setItem("coverageId", coverageId);
    if (medicationRequestId) sessionStorage.setItem("medicationRequestId", medicationRequestId);
    if (serviceRequestId) sessionStorage.setItem("serviceRequestId", serviceRequestId);
    if (questionnaire) sessionStorage.setItem("questionnaire", questionnaire);
    if (patientId) sessionStorage.setItem("patientId", patientId);
  }

  useEffect(() => {
    getAuthenticationIfo();
  }, []);

  return (
    <AuthContext.Provider value={{ isAuthenticated }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
