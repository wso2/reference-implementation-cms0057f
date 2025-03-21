import { createTheme, responsiveFontSizes } from "@mui/material/styles";
export let theme = createTheme({
  typography: {
    fontFamily: "Plus Jakarta Sans",
    h1: {
      fontWeight: 700,
      fontSize: "2.8rem",
    },
    h2: {
      fontWeight: 700,
      fontSize: "2rem",
    },
    h3: {
      fontWeight: 700,
      fontSize: "1.8rem",
    },
    h4: {
      fontWeight: 600,
      fontSize: "1.5rem",
    },
    h5: {
      fontWeight: 500,
      fontSize: "1.2rem",
    },
    h6: {
      fontWeight: 500,
      fontSize: "1.0rem",
    },
    button: {
      textTransform: "none",
    },
  },
  palette: {
    primary: {
      main: "#000000", //Black
      contrastText: "#fff",
    },
    secondary: {
      main: "#00A79D", //Asgardeo Green
      light: "#f7f8fb", // Light grey + purple
    },
    text: {
      primary: "#000000", //Dark blue
      secondary: "#494848", //Light Grey
    },
    background: {
      paper: "#f5f5f5", // Grey, tken from the ballerina.io website
      default: "#ffffff", // White
    },
    info: {
      main: "#00A79D", //Asgardeo Green,
      light: "#f7f8fb", // Asgardeo Green + light shade
    },
    success: {
      main: "#9e9e9e", //Gray 600
      light: "#d6ffd6", //Light green
    },
    warning:{
      main: "#fdcec6", //Red
      light: "#ffd6d6", //Light red
    },
  },
});
theme = responsiveFontSizes(theme);