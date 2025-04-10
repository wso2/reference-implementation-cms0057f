import NavBar from "@/components/NavBar";
import React, { useEffect, useState } from "react";
import { Route, Routes, useLocation } from "react-router-dom";
import Index from "./Index";
import Operations from "./Operations";
import NotFound from "./NotFound";
import { setupApiInterceptor } from "../utils/apiInterceptor";

const Layout: React.FC = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userName, setUserName] = useState("User");
  const location = useLocation(); // Track the current route

  useEffect(() => {
    // Set up the API interceptor when the app loads
    setupApiInterceptor();

    const checkLoginStatus = () => {
      const authToken = sessionStorage.getItem("fhirAuthToken");
      const connectionData = sessionStorage.getItem("fhirConnection");

      if (authToken && connectionData) {
        setIsLoggedIn(true);

        // Set user name based on practitioner mode
        const connection = JSON.parse(connectionData);
        setUserName(connection.practitionerMode ? "Practitioner" : "Patient");
      } else {
        setIsLoggedIn(false);
        setUserName("User");
      }
    };

    // Check login status on initial load
    checkLoginStatus();

    // Set up an event listener for storage changes
    window.addEventListener("storage", checkLoginStatus);

    return () => {
      window.removeEventListener("storage", checkLoginStatus);
      window.removeEventListener("popstate", checkLoginStatus);
    };
  }, [location]);
  
  return (
    <div>
      <NavBar isLoggedIn={isLoggedIn} userName={userName} />
      <Routes>
        <Route path="/" element={<Index />} />
        <Route path="/api-view" element={<Operations />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </div>
  );
};

export default Layout;
