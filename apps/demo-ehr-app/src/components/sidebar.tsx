// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
import { useState } from "react";
import { Box, Flex, Tooltip } from "@chakra-ui/react";
import { FaHome, FaUserInjured, FaSyncAlt, FaClipboardList, FaBars } from "react-icons/fa";
import { useNavigate, useLocation } from "react-router-dom";

export default function Sidebar() {
    const [isOpen, setIsOpen] = useState(false);
    const navigate = useNavigate();
    const location = useLocation();

    const menuItems = [
        { name: "Dashboard", path: "/", icon: <FaHome size={20} /> },
        { name: "Patient Treatment", path: "/patient-encounter", icon: <FaUserInjured size={20} /> },
        { name: "Data Sync", path: "/provider-data-access", icon: <FaSyncAlt size={20} /> },
        { name: "Prior Auths", path: "/dashboard/prior-auth-list", icon: <FaClipboardList size={20} /> },
    ];

    const handleNavigation = (path: string) => {
        navigate(path);
    };

    return (
        <Box
            width={isOpen ? "250px" : "80px"}
            height="100%"
            bg="#2c3e50"
            color="white"
            transition="width 0.3s ease"
            display="flex"
            flexDirection="column"
            paddingY="20px"
            boxShadow="2px 0 5px rgba(0,0,0,0.1)"
        >
            <Flex
                justifyContent={isOpen ? "flex-end" : "center"}
                alignItems="center"
                paddingX="20px"
                marginBottom="30px"
            >
                <Box cursor="pointer" onClick={() => setIsOpen(!isOpen)}>
                    <FaBars size={24} color="#ecf0f1" />
                </Box>
            </Flex>

            <Flex flexDirection="column" gap="15px">
                {menuItems.map((item) => {
                    const isActive = location.pathname === item.path || (item.path !== "/" && location.pathname.startsWith(item.path));

                    return (
                        <Tooltip label={!isOpen ? item.name : ""} placement="right" key={item.name} hasArrow>
                            <Flex
                                alignItems="center"
                                padding="15px 20px"
                                cursor="pointer"
                                bg={isActive ? "#34495e" : "transparent"}
                                _hover={{ bg: "#34495e" }}
                                transition="background-color 0.2s"
                                borderLeft={isActive ? "4px solid #3498db" : "4px solid transparent"}
                                onClick={() => handleNavigation(item.path)}
                            >
                                <Box minWidth="40px" display="flex" justifyContent={isOpen ? "flex-start" : "center"}>
                                    {item.icon}
                                </Box>

                                {isOpen && (
                                    <Box fontWeight="500" fontSize="16px" whiteSpace="nowrap" overflow="hidden">
                                        {item.name}
                                    </Box>
                                )}
                            </Flex>
                        </Tooltip>
                    );
                })}
            </Flex>
        </Box>
    );
}
