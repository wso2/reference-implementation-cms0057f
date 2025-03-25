import { Box } from "@mui/material";
import React, { Suspense } from "react";

const MainContent = React.lazy(() =>
  import("./components/layout/MainContent").then((module) => ({
    default: module.MainContent,
  }))
);

const App = () => {
  return (
    // <Box sx={{ display: "flex", flexDirection: "column", height: "100vh" }}>
    //   <Suspense
    //     fallback={
    //       <>
    //         <Box
    //           sx={{
    //             display: "flex",
    //             flexDirection: "column",
    //             justifyContent: "center",
    //             alignItems: "center",
    //             height: "100vh",
    //           }}
    //         >
    //         </Box>
    //       </>
    //     }
    //   >
    //     <MainContent />
    //   </Suspense>
    // </Box>
    <MainContent />
  );
};

export default App;
