import React from 'react';
import { Box, Typography, Avatar, Button, Stack, Link } from '@mui/material';
import { Link as RouterLink } from 'react-router-dom';

const Header = ({ userName, avatarUrl, isLoggedIn }:any) => {
  return (
    <Box
      display="flex"
      justifyContent="space-between"
      alignItems="center"
      sx={{ p: 2, backgroundColor: '#f5f5f5', borderBottom: '1px solid #e0e0e0', padding:5 }}
    >
      {/* Left Section: Main Text and Description */}
      <Box>
        <Typography variant="h4" component="div">
        USPayer Member Portal
        </Typography>
        <Typography variant="subtitle1" component="div" color="textSecondary">
        Secure, standardized healthcare data access.
        </Typography>
      </Box>
       {isLoggedIn && <Stack direction="column" spacing={2} alignItems="center">
      <Stack direction="row" spacing={2} alignItems="center">

      <Avatar alt={userName} src={avatarUrl} />
        <Typography variant="body1" component="div">
          {userName}
        </Typography>
        {/* <Button variant="contained" color="primary" onClick={onLogout}>
          Logout
        </Button> */}
      </Stack>
      <Link variant="body2" component={RouterLink} to="/login">
          Back to Home
        </Link>
      </Stack>}

      {/* Right Section: User Info and Logout Button */}
      {/* <Stack direction="column" spacing={2} alignItems="center">
      <Stack direction="row" spacing={2} alignItems="center">

      <Avatar alt={userName} src={avatarUrl} />
        <Typography variant="body1" component="div">
          {userName}
        </Typography> */}
        {/* <Button variant="contained" color="primary" onClick={onLogout}>
          Logout
        </Button> */}
      {/* </Stack>
      <Link variant="body2" component={RouterLink} to="/login">
          Back to Home
        </Link>
      </Stack> */}
    </Box>
  );
};

export default Header;
