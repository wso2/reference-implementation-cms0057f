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

import { SelectChangeEvent } from "@mui/material/Select";
import Box from "@mui/material/Box";
import InputLabel from "@mui/material/InputLabel";
import MenuItem from "@mui/material/MenuItem";
import FormControl from "@mui/material/FormControl";
import Select from "@mui/material/Select";

interface DropdownProps {
  dropdown_options: string[];
  selectedValue: string;
  handleChange: (event: SelectChangeEvent) => void;
  handleOnBlur?: () => void;
  form_selector_width: number;
  dropdown_label: string;
  isDisabled?: boolean;
  borderColor?: string;
}

export const DropDownBox: React.FC<DropdownProps> = ({
  dropdown_options,
  selectedValue,
  handleChange,
  handleOnBlur,
  form_selector_width,
  dropdown_label,
  isDisabled = false,
  borderColor,
}) => (
  <Box sx={{ display: "flex", alignItems: "flex-end" }}>
    <FormControl
      sx={{ m: 1, minWidth: form_selector_width }}
      disabled={isDisabled}
    >
      <InputLabel id={`${dropdown_label}-label`}>{dropdown_label}</InputLabel>
      <Select
        labelId={`${dropdown_label}-label`}
        id={`${dropdown_label}-helper`}
        value={selectedValue}
        label={dropdown_label}
        onChange={handleChange}
        onBlur={handleOnBlur}
        sx={{
          "& .MuiOutlinedInput-notchedOutline": {
            borderColor: { borderColor },
          },
        }}
      >
        <MenuItem value="">
          <em>None</em>
        </MenuItem>
        {dropdown_options.map((dropdown_option) => (
          <MenuItem
            value={dropdown_option}
            key={dropdown_option}
            sx={{ fontSize: "0.8rem" }}
          >
            {dropdown_option}
          </MenuItem>
        ))}
      </Select>
    </FormControl>
  </Box>
);
