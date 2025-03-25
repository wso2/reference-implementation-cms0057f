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

import { Button, Typography, Box, Container } from "@mui/material";

const LoginPage = () => {
  return (
    <Container
      sx={{
        // backgroundImage: "url('/background-gray-med.svg')",
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
      }}
    >
      <Box display="flex" height="100vh">
        <Box
          flex={2}
          display="flex"
          justifyContent="center"
          alignItems="center"
          p={4}
          sx={{ backgroundColor: "#fff" }}
        >
          <Box
            component="img"
            src="/welcome.png"
            alt="Welcome"
            sx={{
              maxWidth: "100%",
              height: "auto",
              objectFit: "contain",
            }}
          />
        </Box>
        <Box
          flex={2}
          display="flex"
          justifyContent="center"
          alignItems="center"
          p={10}
          sx={{ backgroundColor: "background.paper" }}
        >
          <Box display={"row"}>
            <Typography variant="h2" align="center" padding={4} gutterBottom>
              USPayer Member Portal
            </Typography>
            <Typography variant="h6" align="center">
              This website serves as an interactive platform showcasing
              real-world use cases of the DaVinci Payer Data Exchange
              implementation guide, a crucial initiative aimed at streamlining
              healthcare data sharing between payers, providers, and other
              stakeholders. With a focus on interoperability, this site
              demonstrates how DaVinci standards enable seamless, secure, and
              efficient exchange of clinical and administrative data.
            </Typography>
            <Box
              display="flex"
              justifyContent="center"
              alignItems="center"
              mt={6}
              mb={2}
            >
              <Button
                type="submit"
                variant="contained"
                sx={{ px: 4, width: "200px" }}
                onClick={() => {
                  window.location.href = "/auth/login";
                }}
              >
                Login
              </Button>
            </Box>
          </Box>
        </Box>
      </Box>
    </Container>
  );
};

export default LoginPage;
