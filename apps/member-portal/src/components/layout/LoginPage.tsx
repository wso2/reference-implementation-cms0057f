// src/pages/LoginPage.js
import { useState } from "react";
import {
  Button,
  Typography,
  Box,
  Container,
  Paper,
  FormControl,
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import apiClient from "../../services/apiClient";
import { BFF_BASE_URL } from "../../configs/Constants";
import React from "react";

const LoginPage = () => {
  const [memberId, setMemberId] = useState("");
  const [userName, setUserName] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate(); // Initialize navigate hook
  const [userList, setUserList] = useState([
    { userId: "1", name: "Cortez Prohaska" },
    { userId: "2", name: "Veola Rutherford" },
    { userId: "3", name: "Eliana Jacobi" },
  ]);

  const handleLogin = (e: { preventDefault: () => void }) => {
    e.preventDefault();

    if (!memberId || !password) {
      setError("Please enter both ID and password");
      return;
    }

    // Simulate an API call that returns a 200 status
    apiClient(BFF_BASE_URL)
      .post("/member/login", {
        memberId: memberId,
        password: password,
        name: "",
      })
      .then((response) => {
        console.log(response);
        if (response.status === 201) {
          console.log("Login successful:", { memberId: memberId, password });
          setError("");
          // Redirect to /home upon successful login
          navigate("/dashboard", { state: { userName, memberId } });
        } else {
          setError("Login failed. Please check your credentials)");
        }
      })
      .catch((error) => {
        console.error("Error:", error);
        setError("Login failed. Please check your credentials");
      });
  };

  return (
    <Container maxWidth="lg">
      <Box display="flex" height="100vh">
        {/* Left 2/3 section - Text Area */}
        <Box
          flex={2}
          display="flex"
          justifyContent="center"
          alignItems="center"
          p={4}
          sx={{ backgroundColor: "background.paper" }} // Background color for visual separation
        >
          <Box display={"row"}>
            <Typography variant="h2" align="center" padding={4}>
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
          </Box>
        </Box>

        {/* Right 1/3 section - Login Form */}
        <Box
          flex={1}
          display="flex"
          justifyContent="center"
          alignItems="center"
          p={4}
          sx={{ backgroundColor: "#fff" }}
        >
          <Paper
            elevation={3}
            sx={{ p: 4, width: "100%", maxWidth: "400px", borderRadius: "8px" }}
          >
            <Typography variant="h5" align="center" mb={3}>
              Login
            </Typography>

            <Box component="form" onSubmit={handleLogin}>
              <FormControl fullWidth>
                {/* <InputLabel id="select-member-id-label">Select A Member</InputLabel>
                <Select
                  labelId="select-member-id-label"
                  id="select-member-id"
                  value={memberId}
                  label="Select a Member"
                  onChange={(e) => {
                    setMemberId(e.target.value);
                    setUserName(
                      userList.find((user) => user.userId === e.target.value)
                        ?.name || ""
                    );
                  }}
                >
                  {userList.map((user, index) => (
                      <MenuItem value={user.userId} key={index}>{user.name}</MenuItem>
                  ))}
                </Select>
                <TextField
                  label="Password"
                  type="password"
                  fullWidth
                  variant="outlined"
                  margin="normal"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />

                {error && (
                  <Typography
                    color="error"
                    variant="body2"
                    align="center"
                    mt={2}
                  >
                    {error}
                  </Typography>
                )} */}

                <Button
                  type="submit"
                  variant="contained"
                  fullWidth
                  sx={{ mt: 3, mb: 2 }}
                  onClick={() => {
                    window.location.href = "/auth/login";
                  }}
                >
                  Login
                </Button>

                {/* Hyperlinked text */}
                {/* <Typography align="center">
                <Link to="#">Forgot password?</Link>
              </Typography>

              <Typography align="center" mt={2}>
                Don't have an account?{" "}
                <Link to="#" style={{ textDecoration: "underline" }}>
                  Sign up
                </Link>
              </Typography> */}
              </FormControl>
            </Box>
          </Paper>
        </Box>
      </Box>
    </Container>
  );
};

export default LoginPage;
