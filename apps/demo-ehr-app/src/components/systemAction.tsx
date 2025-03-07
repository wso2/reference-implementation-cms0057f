// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

import { SystemActionExtension } from "./interfaces/coverage";
import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";
import { PRIMARY_COLOR } from "../constants/color";

export const SystemActionComponent = (extension: SystemActionExtension) => {
  if (extension === undefined) {
    return null;
  }
  return (
    <Card variant="outlined" sx={{ width: 500, bgcolor: PRIMARY_COLOR }}>
      {extension.extension.map((ext, index) => (
        <CardContent key={index}>
          <div
            style={{
              display: "flex",
              flexDirection: "row",
              justifyContent: "space-between",
            }}
          >
            <div>{ext.url}</div>
            <div>
              {ext.valueReference && `${ext.valueReference.reference}`}
              {ext.valueCode && `${ext.valueCode}`}
              {ext.valueCoding && `${ext.valueCoding.code}`}
              {ext.valueCodeableConcept && `${ext.valueCodeableConcept.text}`}
            </div>
          </div>
        </CardContent>
      ))}
    </Card>
  );
};
