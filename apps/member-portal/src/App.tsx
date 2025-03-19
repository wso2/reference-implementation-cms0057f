import {
  Box
} from "@mui/material";
import React, { Suspense } from "react";

const MainContent = React.lazy(() =>
  import("./components/layout/MainContent").then((module) => ({
    default: module.MainContent,
  }))
);

const App = () => {
  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100vh" }}>
      <Suspense
        fallback={
          <>
            <Box
              sx={{
                display: "flex",
                flexDirection: "column",
                justifyContent: "center",
                alignItems: "center",
                height: "100vh",
              }}
            >
              {/* <PreLoader setActive={true} size={50} /> */}
            </Box>
          </>
        }
      >
        <MainContent />
      </Suspense>
    </Box>
  );
};

export default App;