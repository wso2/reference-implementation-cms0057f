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

import DrugPiorAuth from "../components/DrugPriorAuth";
import NavBar from "../components/NavBar";

export default function DrugPiorAuthPage() {
  return (
    <div style={{ width: "100vw", height: "100vh", backgroundColor: "#f0f0f0" }}>
      <NavBar />
      <div
        style={{
          width: "80vw",
          margin: "auto",
          marginTop: "30px",
          border: "1px solid #ccc",
          borderRadius: "8px",
          overflow: "hidden",
          boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)",
        }}
      >
        <div
          style={{
            width: "100%",
            height: "85vh",
            overflow: "auto",
            backgroundColor: "#f9f9f9",
          }}
        >
          <DrugPiorAuth />
        </div>
      </div>
    </div>
  );
}
