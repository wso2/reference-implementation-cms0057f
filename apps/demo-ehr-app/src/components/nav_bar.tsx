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
import { useContext, useState } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { useSelector } from "react-redux";
import { PATIENT_DETAILS } from "../constants/data";
import Cookies from "js-cookie";
import { useAuth } from "./AuthProvider";
import { useDispatch } from "react-redux";
import { updateLoggedUser } from "../redux/loggedUserSlice";

export default function NavBar() {
  const dispatch = useDispatch();
  const encodedUserInfo = Cookies.get("userinfo");
  if (encodedUserInfo) {
    const loggedUser = encodedUserInfo
      ? JSON.parse(atob(encodedUserInfo))
      : { username: "", first_name: "", last_name: "" };

    dispatch(
      updateLoggedUser({
        username: loggedUser.username,
        first_name: loggedUser.first_name,
        last_name: loggedUser.last_name,
      })
    );
  }

  const loggedUser = useSelector((state: any) => state.loggedUser);

  const { isAuthenticated } = useAuth();
  const { expanded } = useContext(ExpandedContext);

  const [showDropdown, setShowDropdown] = useState(false);

  const selectedPatientId = useSelector(
    (state: any) => state.patient.selectedPatientId
  );
  const currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === selectedPatientId
  );

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
          <Box display="flex" alignItems="center" style={{ marginLeft: 6 }}>
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
          </Box>
          {currentPatient && (
            <Box display="flex" alignItems="center">
              <Button href="/dashboard" color="inherit">
                Dashboard
              </Button>
              <Button href="/dashboard/appointment-schedule" color="inherit">
                Appointment
              </Button>
              <Button href="/dashboard/drug-order-v2" color="inherit">
                Order Drugs
              </Button>
              <Button href="/dashboard/device-order-v2" color="inherit">
                Order Devices
              </Button>
              <Button href="/dashboard/medical-imaging" color="inherit">
                Order Imaging
              </Button>
            </Box>
          )}
          <Box display="flex" alignItems="center" marginRight={10}>
            {isAuthenticated && loggedUser && (
              <Box display="flex" alignItems="center">
                <Box marginRight={10} color="white" fontSize="16px">
                  {loggedUser.first_name.toUpperCase() +
                    " " +
                    loggedUser.last_name.toUpperCase()}
                </Box>
                <Box position="relative">
                  <Box
                    borderRadius="50%"
                    overflow="hidden"
                    onClick={() => setShowDropdown(!showDropdown)}
                    cursor={"pointer"}
                  >
                    <img
                      src="/profile.png"
                      alt="Demo Logo"
                      height={40}
                      width={40}
                    />
                  </Box>
                  {showDropdown && (
                    <Box
                      position="absolute"
                      right={-10}
                      marginTop={15}
                      bg="grey"
                      boxShadow="md"
                      borderRadius="20"
                      width="90px"
                      zIndex={1}
                      display="flex"
                      justifyContent="center"
                      alignItems="center"
                    >
                      <Button
                        onClick={async () => {
                          window.location.href = `/auth/logout?session_hint=${Cookies.get(
                            "session_hint"
                          )}`;
                        }}
                        color="inherit"
                      >
                        Log Out
                      </Button>
                    </Box>
                  )}
                </Box>
              </Box>
            )}
          </Box>
        </Flex>
      </Box>
    </div>
  );
}
