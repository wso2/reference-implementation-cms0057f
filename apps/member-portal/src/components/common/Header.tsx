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

import { Box, Typography, Avatar, Button, Stack } from "@mui/material";
import Cookies from "js-cookie";

const Header = ({ userName, avatarUrl, isLoggedIn }: any) => {
  return (
    <Box
      display="flex"
      justifyContent="space-between"
      alignItems="center"
      sx={{
        p: 2,
        pl: 2,
        mt: 2,
        backgroundColor: "#f5f5f5",
        borderBottom: "1px solid #e0e0e0",
        borderRadius: 2,
      }}
    >
      {/* Left Section: Main Text and Description */}
      <Box>
        <Typography variant="h4" component="div">
          UnitedCare Health Member Portal
        </Typography>
        <Typography variant="subtitle1" component="div" color="textSecondary">
          Secure, standardized healthcare data access.
        </Typography>
      </Box>

      {isLoggedIn && (
        <Stack direction="column" spacing={2} alignItems="center">
          <Stack direction="row" spacing={2} alignItems="center">
            <Avatar alt={userName} src={avatarUrl} />
            <Typography variant="body1" component="div">
              {userName}
            </Typography>
            <Button
              variant="outlined"
              color="primary"
              onClick={async () => {
                window.location.href = `/auth/logout?session_hint=${Cookies.get(
                  "session_hint"
                )}`;
              }}
            >
              Logout
            </Button>
          </Stack>
        </Stack>
      )}
    </Box>
  );
};

export default Header;
