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

import React, { useEffect, useMemo, useRef, useState } from "react";
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

type RequestLogEntry = {
  method?: string;
  url?: string;
  request?: unknown;
  response?: unknown;
};

const formatLogLabel = (log: RequestLogEntry, index: number) => {
  const url = log.url || "";
  const path = url.replace(/^https?:\/\/[^/]+/, "") || url;
  const method = log.method ? `[${log.method}] ` : "";
  return `#${index + 1} ${method}${path}`;
};

const DevConsole = () => {
  const [stage, setStage] = useState("horizontal");
  const [selectedLogIndex, setSelectedLogIndex] = useState(0);
  const [theme, setTheme] = useState<"dark" | "light">(() => {
    const stored = localStorage.getItem("devConsoleTheme");
    return stored === "dark" ? "dark" : "light";
  });
  const logListEndRef = useRef<HTMLDivElement>(null);

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
  const requestLogs: RequestLogEntry[] = useSelector(
    (state: any) => state.currentState.requestLogs
  );
  const stackedRequestLogs = useSelector(
    (state: any) => state.currentState.stackedRequestLogs
  );

  const showStackedLogs = stackedRequestLogs && requestLogs.length > 0;
  const activeLog = showStackedLogs
    ? requestLogs[Math.min(selectedLogIndex, requestLogs.length - 1)]
    : null;

  useEffect(() => {
    if (showStackedLogs) {
      setSelectedLogIndex(requestLogs.length - 1);
    }
  }, [requestLogs.length, showStackedLogs]);

  useEffect(() => {
    if (showStackedLogs) {
      logListEndRef.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }, [requestLogs.length, showStackedLogs]);

  const cdsRequest = showStackedLogs ? (activeLog?.request ?? {}) : requestState;
  const activeResponse = showStackedLogs ? (activeLog?.response ?? {}) : response;
  const activeMethod = showStackedLogs ? activeLog?.method : requestMethod;
  const activeUrl = showStackedLogs ? activeLog?.url : requestUrl;

  const requestTitle = useMemo(() => {
    if (!activeMethod && !activeUrl) return "Current request";
    return `${activeMethod ? `[${activeMethod}] ` : ""}${activeUrl || ""}`;
  }, [activeMethod, activeUrl]);

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
      } as const;
    }
    return {
      margin: 0,
      padding: "12px 14px",
      fontSize: "13px",
      lineHeight: 1.55,
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
        flex: 1,
        height: "100%",
        minHeight: 0,
        overflow: "hidden",
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

      {showStackedLogs && (
        <Box
          flexShrink={0}
          sx={{
            mx: 1.5,
            mt: 1,
            mb: 0.5,
            borderRadius: 1,
            border: "1px solid",
            borderColor:
              theme === "light" ? "rgba(15, 23, 42, 0.12)" : "rgba(255, 255, 255, 0.22)",
            backgroundColor: theme === "light" ? "#ffffff" : "rgba(0, 0, 0, 0.15)",
            overflow: "hidden",
          }}
        >
          <Box
            sx={{
              px: 1.5,
              py: 0.75,
              fontSize: 11,
              fontFamily: "monospace",
              fontWeight: 700,
              color: panel.pageText,
              borderBottom: "1px solid",
              borderColor:
                theme === "light" ? "rgba(15, 23, 42, 0.08)" : "rgba(255, 255, 255, 0.12)",
            }}
          >
            Network Calls ({requestLogs.length})
          </Box>
          <Box
            sx={{
              maxHeight: 140,
              overflowY: "auto",
              px: 0.5,
              py: 0.5,
            }}
          >
            {requestLogs.map((log, index) => {
              const isSelected = index === selectedLogIndex;
              return (
                <Box
                  key={index}
                  onClick={() => setSelectedLogIndex(index)}
                  sx={{
                    px: 1,
                    py: 0.6,
                    mb: 0.25,
                    borderRadius: 0.75,
                    cursor: "pointer",
                    fontSize: 10.5,
                    fontFamily: "monospace",
                    lineHeight: 1.35,
                    wordBreak: "break-all",
                    color: panel.pageText,
                    backgroundColor: isSelected
                      ? theme === "light"
                        ? "#dbeafe"
                        : "rgba(59, 130, 246, 0.35)"
                      : "transparent",
                    border: isSelected ? "1px solid" : "1px solid transparent",
                    borderColor: isSelected
                      ? theme === "light"
                        ? "#93c5fd"
                        : "rgba(147, 197, 253, 0.5)"
                      : "transparent",
                    ":hover": {
                      backgroundColor: isSelected
                        ? undefined
                        : theme === "light"
                          ? "#f1f5f9"
                          : "rgba(255, 255, 255, 0.08)",
                    },
                  }}
                >
                  {formatLogLabel(log, index)}
                </Box>
              );
            })}
            <div ref={logListEndRef} />
          </Box>
        </Box>
      )}

      {!showStackedLogs && requestUrl && (
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

      {showStackedLogs && activeUrl && (
        <div
          style={{
            flexShrink: 0,
            width: "90%",
            borderRadius: 10,
            backgroundColor: panel.bannerBg,
            textAlign: "center",
            alignSelf: "center",
            marginTop: 6,
            marginLeft: "5%",
            padding: "6px 10px",
            fontSize: 11,
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
          overflow: "hidden",
          display: "flex",
          flexDirection: stage === "vertical" ? "column" : "row",
          gap: stage === "vertical" ? 0.25 : 1,
          px: 1.5,
          pb: 1,
          boxSizing: "border-box",
        }}
      >
        <Box
          sx={{
            flex: stage === "vertical" ? 1 : "0 1 38%",
            minHeight: 0,
            minWidth: 0,
            display: "flex",
            flexDirection: "column",
            maxWidth: stage === "vertical" ? "100%" : "38%",
            overflow: "hidden",
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
              minHeight: 0,
              mt: 0.5,
              overflow: "auto",
              WebkitOverflowScrolling: "touch",
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
            flex: stage === "vertical" ? 1 : "1 1 62%",
            minHeight: 0,
            minWidth: 0,
            display: "flex",
            flexDirection: "column",
            maxWidth: stage === "vertical" ? "100%" : "62%",
            overflow: "hidden",
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
              minHeight: 0,
              mt: 0.5,
              overflow: "auto",
              WebkitOverflowScrolling: "touch",
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
              {JSON.stringify(activeResponse ?? {}, null, 2)}
            </SyntaxHighlighter>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default DevConsole;
