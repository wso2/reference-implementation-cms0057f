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

import * as React from "react";
import ToggleButton from "@mui/material/ToggleButton";
import ToggleButtonGroup from "@mui/material/ToggleButtonGroup";

interface ToggleGrpButtonProps {
  dosages: string[];
  selectedDosage: string;
  handleDosageChange: (
    event: React.MouseEvent<HTMLElement>,
    value: string
  ) => void;
}

const ToggleGrpButton: React.FC<ToggleGrpButtonProps> = ({
  dosages,
  selectedDosage,
  handleDosageChange,
}) => {
  return (
    <ToggleButtonGroup
      value={selectedDosage}
      exclusive
      onChange={handleDosageChange}
    >
      {dosages.map((dosage) => (
        <ToggleButton
          key={dosage}
          value={dosage}
          sx={{ textTransform: "none", height: 20 }}
        >
          {dosage}
        </ToggleButton>
      ))}
    </ToggleButtonGroup>
  );
};

export default ToggleGrpButton;
