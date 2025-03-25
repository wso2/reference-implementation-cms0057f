import { CssBaseline, ThemeProvider } from "@mui/material";
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { theme } from "./configs/ThemeConfig";
import "./index.css";
import { AuthProvider } from "./components/common/AuthProvider";
import { Provider } from "react-redux";
import { store } from "./components/redux/store";
import { ExpandedContextProvider } from "./components/layout/ExpandedContext";

const root = ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
);

root.render(
  <React.StrictMode>
    <Provider store={store}>
      <ExpandedContextProvider>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <BrowserRouter>
            <AuthProvider>
              <App />
            </AuthProvider>
          </BrowserRouter>
        </ThemeProvider>
      </ExpandedContextProvider>
    </Provider>
  </React.StrictMode>
);
