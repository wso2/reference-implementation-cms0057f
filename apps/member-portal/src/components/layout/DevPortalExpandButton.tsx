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

import { useContext } from "react";
import { Box, Button } from "@mui/material";
import { ExpandedContext } from "./ExpandedContext";
import { SCREEN_HEIGHT } from "../constants/page";

export const DevPortalExpandButton = () => {
  const { toggleExpanded, expanded } = useContext(ExpandedContext);

  return (
    <Box
      sx={{ display: "flex", alignItems: "center", height: SCREEN_HEIGHT - 80 }}
    >
      <Button
        sx={{
          writingMode: "vertical-rl",
          transform: "rotate(180deg)",
          height: "90%",
          minWidth: "2vw",
          borderRadius: 50,
          color: "white",
          backgroundColor: expanded ? "#4C585B" : "#7E99A3",
          ":hover": {
            backgroundColor: expanded ? "#7E99A3" : "#4C585B",
          },
        }}
        onClick={toggleExpanded}
      >
        Developer Console
      </Button>
    </Box>
  );
};
