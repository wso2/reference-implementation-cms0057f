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

import React, { useMemo, useState } from "react";
import {
  Box,
  Button,
  Radio,
  RadioGroup,
  FormControlLabel,
  FormControl,
} from "@mui/material";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { tomorrowNight } from "react-syntax-highlighter/dist/esm/styles/hljs";
import { oneLight } from "react-syntax-highlighter/dist/esm/styles/prism";
import { useSelector } from "react-redux";
import "../assets/styles/code_theme.css";
import Stepper from "./Stepper";

const DevConsole = () => {
  const [stage, setStage] = useState("horizontal");
  const [theme, setTheme] = useState<"dark" | "light">(() => {
    const stored = localStorage.getItem("devConsoleTheme");
    return stored === "dark" ? "dark" : "light";
  });

  const handleStageChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setStage((event.target as HTMLInputElement).value);
  };

  const hook = useSelector((state: any) => state.currentState.hook);
  const requestState = useSelector((state: any) => state.currentState.request);
  const requestUrl = useSelector((state: any) => state.currentState.requestUrl);
  const requestMethod = useSelector(
    (state: any) => state.currentState.requestMethod
  );
  const response = useSelector((state: any) => state.currentState.response);
  const isProcess = useSelector((state: any) => state.currentState.isProcess);

  const cdsRequest = requestState;
  const requestTitle = useMemo(() => {
    if (!requestMethod && !requestUrl) return "Current request";
    return `${requestMethod ? `[${requestMethod}] ` : ""}${requestUrl || ""}`;
  }, [requestMethod, requestUrl]);

  const syntaxTheme = useMemo(
    () => (theme === "light" ? oneLight : tomorrowNight),
    [theme]
  );

  const codeBlockCustomStyle = useMemo(() => {
    if (theme === "light") {
      return {
        margin: 0,
        padding: "12px 14px",
        fontSize: "13px",
        lineHeight: 1.55,
        fontWeight: 500,
        background: "#ffffff",
        border: "1px solid #cbd5e1",
        borderRadius: 8,
        maxHeight: "100%",
      } as const;
    }
    return {
      margin: 0,
      padding: "12px 14px",
      fontSize: "13px",
      lineHeight: 1.55,
      maxHeight: "100%",
    } as const;
  }, [theme]);

  const panel = useMemo(() => {
    if (theme === "light") {
      return {
        pageText: "#0f172a",
        bannerBg: "#e2e8f0",
        bannerText: "#0f172a",
      };
    }
    return {
      pageText: "#ffffff",
      bannerBg: "#f5f0f0",
      bannerText: "#111827",
    };
  }, [theme]);

  const toggleTheme = () => {
    setTheme((t) => {
      const next = t === "dark" ? "light" : "dark";
      localStorage.setItem("devConsoleTheme", next);
      window.dispatchEvent(new Event("devConsoleThemeChanged"));
      return next;
    });
  };

  return (
    <Box
      color={panel.pageText}
      sx={{
        display: "flex",
        flexDirection: "column",
        height: "100%",
        minHeight: 0,
        boxSizing: "border-box",
        pt: 1.5,
      }}
    >
      <Box
        flexShrink={0}
        fontSize={20}
        fontWeight={600}
        textAlign={"center"}
        color={panel.pageText}
        fontFamily={"monospace"}
        sx={{
          pt: 1.75,
          pb: 2,
          px: 2.5,
          mb: 2.5,
          borderBottom: "1px solid",
          borderColor:
            theme === "light" ? "rgba(15, 23, 42, 0.12)" : "rgba(255, 255, 255, 0.22)",
        }}
      >
        Developer Console
      </Box>
      {isProcess && (
        <Box
          flexShrink={0}
          sx={{
            mt: 0,
            "& .MuiStepper-root": { mb: 1, pt: 0.5, pb: 0.5 },
          }}
        >
          <Stepper panelTheme={theme}></Stepper>
        </Box>
      )}

      {hook && (
        <div
          style={{
            flexShrink: 0,
            minHeight: 32,
            width: "90%",
            borderRadius: 50,
            backgroundColor: theme === "light" ? "#cbd5e1" : "#D9D9D9",
            textAlign: "center",
            alignSelf: "center",
            marginTop: 6,
            marginLeft: "5%",
            fontSize: 14,
            fontFamily: "monospace",
            color: "#111827",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          Hook: <b>{hook}</b>
        </div>
      )}

      {requestUrl && (
        <div
          style={{
            flexShrink: 0,
            width: "90%",
            borderRadius: 10,
            backgroundColor: panel.bannerBg,
            textAlign: "center",
            alignSelf: "center",
            marginTop: 8,
            marginLeft: "5%",
            padding: "6px 10px",
            fontSize: 12,
            fontFamily: "monospace",
            wordBreak: "break-word",
            color: panel.bannerText,
          }}
        >
          <b>{requestTitle}</b>
        </div>
      )}

      <div style={{ textAlign: "center", width: "100%", flexShrink: 0 }}>
        <FormControl
          component="fieldset"
          style={{
            marginTop: 8,
            marginBottom: 0,
            textAlign: "center",
            color: panel.pageText,
          }}
        >
          <RadioGroup
            row
            aria-label="stage"
            name="stage"
            value={stage}
            onChange={handleStageChange}
          >
            <FormControlLabel
              value="horizontal"
              control={<Radio size="small" />}
              label="Horizontal"
              style={{ color: panel.pageText }}
            />
            <FormControlLabel
              value="vertical"
              control={<Radio size="small" />}
              label="Vertical"
              style={{ color: panel.pageText }}
            />
          </RadioGroup>
        </FormControl>
      </div>

      <Box
        flexShrink={0}
        display="flex"
        justifyContent="center"
        alignItems="center"
        gap={1}
        marginTop={0.5}
        marginBottom={0.5}
      >
        <Button
          variant="outlined"
          size="small"
          onClick={toggleTheme}
          sx={{
            borderColor: theme === "light" ? "#475569" : "#cbd5e1",
            color: panel.pageText,
            fontFamily: "monospace",
            fontWeight: 600,
            ":hover": { borderColor: panel.pageText },
          }}
        >
          Theme: {theme === "light" ? "Light" : "Dark"}
        </Button>
      </Box>

      <Box
        sx={{
          flex: 1,
          minHeight: 0,
          display: "flex",
          flexDirection: stage === "vertical" ? "column" : "row",
          gap: 1,
          px: 1.5,
          pb: 1,
          boxSizing: "border-box",
        }}
      >
        <Box
          sx={{
            flex: stage === "vertical" ? "0 0 auto" : 1,
            minHeight: 0,
            minWidth: 0,
            display: "flex",
            flexDirection: "column",
            maxWidth: stage === "vertical" ? "100%" : "50%",
          }}
        >
          <Box
            flexShrink={0}
            sx={{
              height: 28,
              borderRadius: 1,
              backgroundColor: theme === "light" ? "#94a3b8" : "#D9D9D9",
              textAlign: "center",
              fontSize: 12,
              fontFamily: "monospace",
              fontWeight: 800,
              color: "#0f172a",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            Request
          </Box>

          <Box
            className={
              theme === "light" ? "dev-console-json dev-console-json--light" : "dev-console-json"
            }
            sx={{
              flex: 1,
              minHeight: stage === "vertical" ? 200 : 0,
              mt: 0.5,
              overflow: "auto",
            }}
          >
            <SyntaxHighlighter
              language="json"
              style={syntaxTheme}
              showLineNumbers={true}
              customStyle={codeBlockCustomStyle}
              lineNumberStyle={
                theme === "light"
                  ? { minWidth: "2.5em", paddingRight: "1em", color: "#64748b", fontWeight: 600 }
                  : { minWidth: "2.5em", paddingRight: "1em", opacity: 0.75 }
              }
            >
              {hook !== "cds-services"
                ? JSON.stringify(cdsRequest ?? {}, null, 2)
                : "No Request Body"}
            </SyntaxHighlighter>
          </Box>
        </Box>

        <Box
          sx={{
            flex: stage === "vertical" ? "0 0 auto" : 1,
            minHeight: 0,
            minWidth: 0,
            display: "flex",
            flexDirection: "column",
            maxWidth: stage === "vertical" ? "100%" : "50%",
          }}
        >
          <Box
            flexShrink={0}
            sx={{
              height: 28,
              borderRadius: 1,
              backgroundColor: theme === "light" ? "#94a3b8" : "#D9D9D9",
              textAlign: "center",
              fontSize: 12,
              fontFamily: "monospace",
              fontWeight: 800,
              color: "#0f172a",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            Response
          </Box>

          <Box
            className={
              theme === "light" ? "dev-console-json dev-console-json--light" : "dev-console-json"
            }
            sx={{
              flex: 1,
              minHeight: stage === "vertical" ? 200 : 0,
              mt: 0.5,
              overflow: "auto",
            }}
          >
            <SyntaxHighlighter
              language="json"
              style={syntaxTheme}
              showLineNumbers={true}
              customStyle={codeBlockCustomStyle}
              lineNumberStyle={
                theme === "light"
                  ? { minWidth: "2.5em", paddingRight: "1em", color: "#64748b", fontWeight: 600 }
                  : { minWidth: "2.5em", paddingRight: "1em", opacity: 0.75 }
              }
            >
              {JSON.stringify(response ?? {}, null, 2)}
            </SyntaxHighlighter>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default DevConsole;
