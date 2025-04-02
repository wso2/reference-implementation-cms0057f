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

import React from "react";

const FetchingParamPage = () => {
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <h1 style={styles.header}>Trying to Fetch Required Parameters...</h1>
      <p style={styles.message}>
        Make sure to provide the required query parameters: <strong>coverageId</strong>, <strong>medicationRequestId</strong>, and <strong>patientId</strong>.
      </p>
    </div>
  );
};

const styles: { [key: string]: React.CSSProperties } = {
  header: {
    fontSize: "2rem",
    marginBottom: "1rem",
  },
  message: {
    fontSize: "1.2rem",
    textAlign: "center",
  },
};

export default FetchingParamPage;
