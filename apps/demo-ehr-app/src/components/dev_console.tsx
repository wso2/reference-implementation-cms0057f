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

import React, { useState } from "react";
import {
  Box,
  Radio,
  RadioGroup,
  FormControlLabel,
  FormControl,
} from "@mui/material";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { tomorrowNight } from "react-syntax-highlighter/dist/esm/styles/hljs";
import { useSelector } from "react-redux";
import "../assets/styles/code_theme.css";
import Stepper from "./Stepper";

const DevConsole = () => {
  const [stage, setStage] = useState("horizontal");

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

  return (
    <Box>
      <Box
        fontSize={25}
        fontWeight={400}
        textAlign={"center"}
        color={"white"}
        fontFamily={"monospace"}
        marginBottom={2}
      >
        Developer Console
      </Box>
      {isProcess && <Stepper></Stepper>}

      {hook && (
        <div
          style={{
            height: "3vh",
            width: "80%",
            borderRadius: 50,
            backgroundColor: "#D9D9D9",
            textAlign: "center",
            alignSelf: "center",
            marginTop: 15,
            marginLeft: "10%",
            fontSize: 18,
            fontFamily: "monospace",
          }}
        >
          Hook: <b>{hook}</b>
        </div>
      )}

      {requestUrl && (
        <div
          style={{
            width: "80%",
            borderRadius: 10,
            backgroundColor: "#f5f0f0",
            textAlign: "center",
            alignSelf: "center",
            marginTop: 10,
            marginLeft: "10%",
            padding: "8px",
            paddingTop: "5px",
            paddingBottom: "5px",
            fontSize: 16,
            fontFamily: "monospace",
          }}
        >
          {requestMethod && <b>[{requestMethod}]:</b>} {requestUrl} <br />
        </div>
      )}
      <div style={{ textAlign: "center", width: "100%" }}>
        <FormControl
          component="fieldset"
          style={{
            marginTop: 15,
            textAlign: "center",
            color: "white",
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
              control={<Radio />}
              label="Horizontal"
              style={{ color: "#FFFFFF" }}
            />
            <FormControlLabel
              value="vertical"
              control={<Radio />}
              label="Vertical"
            />
          </RadioGroup>
        </FormControl>
      </div>
      <div
        style={{
          display: stage === "vertical" ? "block" : "flex",
          gap: "10px",
          marginLeft: "20px",
          marginRight: "20px",
          maxWidth: "100%",
        }}
      >
        <div
          style={{
            flex: "1 1 100%",
            maxWidth: stage === "vertical" ? "100%" : "50%",
          }}
        >
          <div
            style={{
              height: "3vh",
              borderRadius: 2,
              backgroundColor: "#D9D9D9",
              textAlign: "center",
              alignSelf: "center",
              marginTop: 20,
              fontSize: 16,
              fontFamily: "monospace",
              fontWeight: 500,
            }}
          >
            Request Body
          </div>

          <div
            style={{
              alignContent: "center",
              overflow: "auto",
              marginBottom: "15px",
            }}
          >
            <SyntaxHighlighter
              language="json"
              style={tomorrowNight}
              showLineNumbers={true}
            >
              {hook != "cds-services"
                ? JSON.stringify(cdsRequest, null, 2)
                : "No Request Body"}
            </SyntaxHighlighter>
          </div>
        </div>

        <div
          style={{
            flex: "1 1 100%",
            maxWidth: stage === "vertical" ? "100%" : "50%",
          }}
        >
          <div
            style={{
              height: "3vh",
              borderRadius: 2,
              backgroundColor: "#D9D9D9",
              textAlign: "center",
              alignSelf: "center",
              marginTop: 20,
              fontSize: 16,
              fontFamily: "monospace",
              fontWeight: 500,
            }}
          >
            Response Body
          </div>

          <div
            style={{
              alignContent: "center",
              overflow: "auto",
              marginBottom: "15px",
            }}
          >
            <SyntaxHighlighter
              language="json"
              style={tomorrowNight}
              showLineNumbers={true}
            >
              {JSON.stringify(response, null, 2)}
            </SyntaxHighlighter>
          </div>
        </div>
      </div>
    </Box>
  );
};

export default DevConsole;
