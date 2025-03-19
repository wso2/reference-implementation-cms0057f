import { Box } from "@mui/material";
import { useLocation } from "react-router-dom";
import LoginPage from "./LoginPage";
import { LandingPage } from "./LandingPage";

declare global {
  interface Window {
    Config: any;
  }
}

export const MainContent = () => {
    const location = useLocation();
  
    if (location.pathname === "/login" || location.pathname === "/") {
      return <LoginPage />;
    }
    if (location.pathname === "/dashboard") {
      return <LandingPage />;
    }
  
    const Config = window.Config;
    // const redirectBaseUrl = Config.APP_AUTH_REDIRECT_BASE_URL;
    // const config = {
    //   signInRedirectURL: redirectBaseUrl + location.pathname,
    //   signOutRedirectURL: redirectBaseUrl + location.pathname,
    //   clientID: Config.APP_AUTH_CLIENT_ID,
    //   baseUrl: Config.APP_AUTH_BASE_URL,
    //   scope: ["openid", "profile"],
    //   resourceServerURLs: [Config.BFF_BASE_URL],
    //   disableTrySignInSilently: false,
    // };
  
    return (
    //   <AuthProvider config={config}>
        <Box>
            <h1>This is the Header</h1>
          <Box id="main-container">
            <h4>This is the main content</h4>
          </Box>
        </Box>
    //   </AuthProvider>
    );
  };