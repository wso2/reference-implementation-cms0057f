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

import Button from "react-bootstrap/Button";
import { PATIENT_DETAILS } from "../constants/data";
import { useState } from "react";

const POPUP_AUTH_IN_PROGRESS_KEY = "dtrPopupAuthInProgress";
const POST_LOGIN_REDIRECT_KEY = "dtrPostLoginRedirect";
const POPUP_LAST_OPENED_AT_KEY = "dtrPopupLastOpenedAt";

declare global {
  interface Window {
    __dtrAuthPopupWindow?: Window | null;
  }
}

function LoginPage() {
  const patients: { [key: string]: string } = {};
  const [isSigningIn, setIsSigningIn] = useState(
    sessionStorage.getItem(POPUP_AUTH_IN_PROGRESS_KEY) === "true"
  );

  PATIENT_DETAILS.forEach((patient) => {
    const fullName = patient.name[0].given[0] + " " + patient.name[0].family;
    patients[patient.id] = fullName;
  });

  const openSignin = () => {
    const isEmbedded = window !== window.parent;

    if (!isEmbedded) {
      setIsSigningIn(true);
      window.location.href = "/auth/login";
      return;
    }

    // Guard against duplicate OAuth initiations from rapid clicks/re-renders.
    if (sessionStorage.getItem(POPUP_AUTH_IN_PROGRESS_KEY) === "true") {
      setIsSigningIn(true);
      return;
    }

    const lastOpenedAt = Number(sessionStorage.getItem(POPUP_LAST_OPENED_AT_KEY) || "0");
    if (Date.now() - lastOpenedAt < 5000) {
      setIsSigningIn(true);
      return;
    }

    if (window.__dtrAuthPopupWindow && !window.__dtrAuthPopupWindow.closed) {
      window.__dtrAuthPopupWindow.focus();
      setIsSigningIn(true);
      return;
    }

    sessionStorage.setItem(POPUP_AUTH_IN_PROGRESS_KEY, "true");
    sessionStorage.setItem(POPUP_LAST_OPENED_AT_KEY, String(Date.now()));
    setIsSigningIn(true);
    const popup = window.open("", "dtr-auth-popup", "popup,width=540,height=720");

    if (!popup) {
      // Fallback for blocked popups.
      sessionStorage.removeItem(POPUP_AUTH_IN_PROGRESS_KEY);
      sessionStorage.removeItem(POPUP_LAST_OPENED_AT_KEY);
      setIsSigningIn(false);
      window.location.href = "/auth/login";
      return;
    }
    window.__dtrAuthPopupWindow = popup;
    popup.location.href = "/auth/login";

    const pollForPopupClose = window.setInterval(() => {
      if (popup.closed) {
        window.clearInterval(pollForPopupClose);
        sessionStorage.removeItem(POPUP_AUTH_IN_PROGRESS_KEY);
        sessionStorage.removeItem(POPUP_LAST_OPENED_AT_KEY);
        window.__dtrAuthPopupWindow = null;
        const redirectPath = sessionStorage.getItem(POST_LOGIN_REDIRECT_KEY) || "/";
        window.location.href = redirectPath;
      }
    }, 500);

    const onAuthSuccessMessage = (event: MessageEvent) => {
      if (event.data?.type !== "DTR_AUTH_SUCCESS") {
        return;
      }

      window.removeEventListener("message", onAuthSuccessMessage);
      window.clearInterval(pollForPopupClose);
      sessionStorage.removeItem(POPUP_AUTH_IN_PROGRESS_KEY);
      sessionStorage.removeItem(POPUP_LAST_OPENED_AT_KEY);
      window.__dtrAuthPopupWindow = null;
      const redirectPath = sessionStorage.getItem(POST_LOGIN_REDIRECT_KEY) || "/";
      window.location.href = redirectPath;
    };

    window.addEventListener("message", onAuthSuccessMessage);
  };

  return (
    <div>
      <div
        style={{
          backgroundImage: `url('/background-gray-med.svg')`,
          backgroundSize: "cover",
          height: "85vh",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: "100%",
            fontSize: "3rem",
            backgroundColor: "rgba(255, 255, 255, 0.8)",
          }}
        >
          <div
            style={{
              textAlign: "center",
              padding: "20px",
              display: "flex",
              flexDirection: "column",
              justifyContent: "center",
              alignItems: "center",
            }}
          >
            <img
              src="/welcome-img.svg"
              alt="Doctor"
              style={{ width: "450px", marginBottom: "20px" }}
            />
            <h1 style={{ color: "#4C585B" }}>Welcome</h1>
            <p style={{ color: "#4C585B" }}>EHealth DTR App</p>
            {window !== window.parent && (
              <p style={{ color: "#4C585B", fontSize: "1rem", marginBottom: "0px" }}>
                Your DTR session is missing. Click Sign In to continue in a popup.
              </p>
            )}
            <Button
              variant="success"
              style={{
                paddingLeft: "50px",
                paddingRight: "50px",
                marginTop: "20px",
                fontSize: "1.5rem",
              }}
              disabled={isSigningIn}
              onClick={openSignin}
            >
              {isSigningIn ? "Signing In..." : "Sign In"}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
