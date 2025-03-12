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

import { Button } from "@mui/material";
import { Box, Flex } from "@chakra-ui/react";
import { useContext } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { useSelector } from "react-redux";
import { PATIENT_DETAILS } from "../constants/data";
import Cookies from "js-cookie";

export default function NavBar() {
  const { expanded } = useContext(ExpandedContext);

  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

  return (
    <div
      style={{
        padding: 14,
        backgroundColor: expanded ? "#4C585B" : "#7E99A3",
        transition: "background-color 0.5s ease",
      }}
    >
      <Box
        bg={expanded ? "#7E99A3" : "#4C585B"}
        height={60}
        borderRadius="40"
        transition="background-color 0.5s ease"
      >
        <Flex
          justifyContent={"space-between"}
          alignItems={"center"}
          height="100%"
        >
          <Button href="/patient/dashboard" color="primary">
            <Box borderRadius="100%" overflow="hidden" marginLeft={5}>
              <img
                src="/demo_logo.png"
                alt="Demo Logo"
                height={40}
                width={40}
              />
            </Box>
            <Box marginLeft={10} color="white" fontSize="16px" fontWeight={600}>
              DEMO EHR
            </Box>
          </Button>
          <Box display="flex" alignItems="center">
            <Button href="/dashboard/appointment-schedule" color="inherit">
              Appointment
            </Button>
            <Button href="/dashboard/drug-order-v2" color="inherit">
              Order Drugs
            </Button>
            {/* <Button href="/dashboard/drug-order-v2/prior-auth?questionnaireId=4" color="inherit">
              Drugs Prior Auth
            </Button>
            <Button href="/dashboard/drug-order-v2/claim-submit" color="inherit">
              Drugs Claim Submit
            </Button> */}
            <Button href="/dashboard/device-order-v2" color="inherit">
              Order Devices
            </Button>
            <Button href="/dashboard/medical-imaging" color="inherit">
              Order Imaging
            </Button>
          </Box>
          <Box>
            <Button
              onClick={async () => {
                window.location.href = `/auth/logout?session_hint=${Cookies.get(
                  "session_hint"
                )}`;
              }}
            >
              <Box marginRight={10} color="white" fontSize="16px">
                Logout
              </Box>
            </Button>
            <Button href="/dashboard/patient">
              <Box marginRight={10} color="white" fontSize="16px">
                {currentPatient.name[0].given[0] +
                  " " +
                  currentPatient.name[0].family}
              </Box>
              <Box borderRadius="50%" overflow="hidden" marginRight={5}>
                <img
                  src="/profile.png"
                  alt="Demo Logo"
                  height={40}
                  width={40}
                />
              </Box>
            </Button>
          </Box>
        </Flex>
      </Box>
    </div>
  );
}
