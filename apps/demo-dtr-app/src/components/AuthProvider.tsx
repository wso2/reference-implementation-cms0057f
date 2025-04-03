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

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const location = useLocation();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const navigate = useNavigate();
  const originalPath = location.pathname;

  const query = useQuery();

  const getAuthenticationIfo = async () => {
    const response = await fetch("/auth/userinfo");

    saveQueryParamsToSessionStorage();

    if (response.status == 200) {
      setIsAuthenticated(true);
      const redirectTo = originalPath || "/";
      navigate(redirectTo, { replace: true });
    } else if (response.status == 401) {
      setIsAuthenticated(false); 
      navigate("/login");
    }
  };

  const saveQueryParamsToSessionStorage = () => {
    const coverageId = query.get("coverageId");
    const medicationRequestId = query.get("medicationRequestId");
    const patientId = query.get("patientId");

    if (!coverageId || !medicationRequestId || !patientId) {
      navigate("/fetching");
      return;
    }

    sessionStorage.setItem("coverageId", coverageId);
    sessionStorage.setItem("medicationRequestId", medicationRequestId);
    sessionStorage.setItem("patientId", patientId);
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
