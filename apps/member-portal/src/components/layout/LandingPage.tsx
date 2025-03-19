import {
  Container,
  Typography,
  Button,
  Box,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Chip,
  Switch,
  TextField,
  LinearProgress,
} from "@mui/material";
import { useEffect, useState } from "react";
import CollapsibleTable from "../common/Table";
import Header from "../common/Header";
import { useLocation, useNavigate } from "react-router-dom";
import CloseIcon from "@mui/icons-material/Close";
import apiClient from "../../services/apiClient";
import { BFF_BASE_URL } from "../../configs/Constants";

interface RowData {
  name: string;
  active: number;
  old: number;
  total: number;
  columns: string[];
  data: Record<string, string>[];
}

// Create data helper function with TypeScript types
function createData(
  name: string,
  active: number,
  old: number,
  total: number,
  columns: string[],
  data: Record<string, string>[]
): RowData {
  return { name, active, old, total, columns, data };
}

function createTableData(responseData: RowData): RowData[] {
  const rowdata: RowData[] = [];
  rowdata.push(responseData);
  return rowdata;
}

export const LandingPage = () => {
  const [name, setName] = useState("");
  const [lastPayer, setLastPayer] = useState("");
  const [exportLabel, setExportLabel] = useState("Export");
  const [status, setStatus] = useState("Member Not Resolved.");
  const [avatarUrl, setAvatarUrl] = useState(
    "https://i.pravatar.cc/100?img=58"
  );
  const navigate = useNavigate(); // Initialize navigate hook
  const location = useLocation();
  const memberId = location.state?.memberId || "nil";
  const userName = location.state?.userName || "nil";
  const [error, setError] = useState("");
  const [payerList, setPayerList] = useState([
    { payerId: "p-1", name: "A Care Insurance" },
    { payerId: "p-2", name: "B Med Insurance" },
    { payerId: "p-3", name: "C Doc Insurance" },
  ]);
  const [checked, setChecked] = useState(false);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [oldMemberId, setOldMemberId] = useState("");
  const [columns, setColumns] = useState([]);
  const [exportStatus, setExportStatus] = useState("0");
  const [tableData, setTableData] = useState([
    createData(
      "Encounter",
      0,
      0,
      0,
      ["Code", "Status", "Provider", "Participant"],
      [
        {
          Code: "AB",
          Status: "finished",
          Provider: "",
          Participant: "",
        }
      ]
    ),
    // createData(
    //   "Providers",
    //   10,
    //   2,
    //   12,
    //   ["Practitioner", "Provider", "Type", "Status"],
    //   [
    //     {
    //       Practitioner: "Amal Jayalath",
    //       Provider: "11091700",
    //       Type: "Resource",
    //       status: "pending",
    //     },
    //     {
    //       Practitioner: "Amal Jayalath",
    //       Provider: "11091700",
    //       Type: "Resource",
    //       status: "pending",
    //     },
    //   ]
    // ),
  ]);

  // State to manage selected options
  const [selectedOptions, setSelectedOptions] = useState([]);

  // useEffect to make API call on component mount (page load)
  useEffect(() => {
    fetchData(); // Fetch data when the page loads
  }, []);

  useEffect(() => {
    reloadTableData(); // This will only run after `checked` state has been updated
  }, [checked]);

  // useEffect(() => {
  //   setExportLabel("Exporting... "+exportStatus+"% Completed.");  // This will only run after `checked` state has been updated
  // }, [exportStatus]);
  // Handle selection of options
  const handleSelectChange = (event: { target: { value: any } }) => {
    const { value } = event.target;
    handlePayerSelection(value);
    setSelectedOptions(value); // Update selected options
  };

  // Handle removal of a tag (chip)
  const handleRemoveTag = (optionToRemove: any) => {
    setSelectedOptions(
      selectedOptions.filter((option) => option !== optionToRemove)
    );
  };

  // Function to poll the /status endpoint
  const pollStatus = (pollingInterval = 3000) => {
    const statusUrl = "/member/" + memberId + "/export/status";

    const intervalId = setInterval(async () => {
      try {
        const statusResponse = await apiClient(BFF_BASE_URL).get(statusUrl);
        const statusData = statusResponse.data;

        console.log("Polling status:", statusData);

        // Update export progress
        // Assuming the progress is returned
        if (statusData.progress != "Ex") {
          setExportStatus(statusData.progress);
          setExportLabel(
            "Exporting... " + statusData.progress + "% Completed."
          );
          setStatus("Exporting... ");
        }

        if (statusData.status === "Completed") {
          console.log("Export completed");
          clearInterval(intervalId); // Stop polling when export is completed
          setExportLabel("Export completed!");
          setStatus("Export Completed.");
        } else if (statusData.status === "Failed") {
          console.error("Export failed");
          clearInterval(intervalId); // Stop polling if export failed
          setError("Export failed. Please try again.");
          setStatus("Export Failed.");
        }
      } catch (error) {
        console.error("Error polling status:", error);
        clearInterval(intervalId); // Stop polling on error
        setError("Error checking export status.");
        setStatus("Export Failed.");
      }
    }, pollingInterval); // Poll every 3 seconds (3000ms)
  };

  const handleSubmit = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setExportLabel("Exporting...");
    setStatus("Exporting...");

    setExporting(true);
    console.log("Submitted name:", selectedOptions);
    const fhirResourceUrl = "/member/" + memberId + "/export";
    try {
      apiClient(BFF_BASE_URL)
        .get(fhirResourceUrl)
        .then((response) => {
          console.log(response);
          if (response.status === 200) {
            pollStatus(); // Start polling the /status endpoint after export starts
            console.log("Export trigger successful:");
            console.log(response.data);
            setError("");
          } else {
            setError("Export failed. Please retry");
          }
        })
        .catch((error) => {
          console.error("Error:", error);
          setError("Export failed. Please retry");
        })
        .finally(() => {
          setLoading(false); // Turn off loading after API call completes
        });
    } catch (error) {
      console.error("Error:", error);
      setError("Error fetching data");
    }
  };

  const handleSwitchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setChecked(event.target.checked);
  };

  const handlePayerSelection = (value: string) => {
    console.log("Selected Payer", value);
    const matchUrl = "/member/" + memberId + "/matchPatient";
    try {
      apiClient(BFF_BASE_URL)
        .get(matchUrl, {
          // params: {
          //   payer: "value",
          // },
        })
        .then((response) => {
          console.log(response);
          if (response.status === 200) {
            console.log("Member match trigger successful:");
            console.log(response.data);
            setOldMemberId(response.data.oldMemberId);
            setError("");
            setStatus("Ready");
          } else {
            setError("Match failed. Please retry");
          }
        })
        .catch((error) => {
          console.error("Error:", error);
          setError("Match failed. Please retry");
          setStatus("Member Not Resoved.");
        })
        .finally(() => {
          setLoading(false); // Turn off loading after API call completes
        });
    } catch (error) {
      console.error("Error:", error);
      setError("Error fetching data");
    }
  };

  const handleRefresh = (data: any) => {};

  // Function to fetch data from API
  const fetchData = async () => {
    setLoading(true); // Set loading state while fetching data
    console.log("Fetching data..." + checked);
    const fhirResourceUrl = "/member/" + memberId + "/other";
    try {
      apiClient(BFF_BASE_URL)
        .get(fhirResourceUrl, {
          params: {
            resourceType: "Encounter",
            isExported: checked,
          },
        })
        .then((response) => {
          console.log(response);
          if (response.status === 200) {
            console.log("Encounters fetched successful:");
            console.log(response.data);
            setError("");
            const data = response.data;
            setColumns(data.columns); // Set dynamic columns
            setTableData(createTableData(data)); // Set dynamic rows
            // setTableData((prevData) => ({
            //   ...prevData,
            //   ...createTableData(data),  // Merge new key-value pairs into existing state
            // }));

          } else {
            setError("Login failed. Please check your credentials)");
          }
        })
        .catch((error) => {
          console.error("Error:", error);
          setError("Login failed. Please check your credentials");
        })
        .finally(() => {
          setLoading(false); // Turn off loading after API call completes
        });
    } catch (error) {
      console.error("Error:", error);
      setError("Error fetching data");
    }
    // try {
    //   apiClient(BFF_BASE_URL)
    //     .get(fhirResourceUrl, {
    //       params: {
    //         resourceType: "DiagnosticReport",
    //         isExported: checked,
    //       },
    //     })
    //     .then((response) => {
    //       console.log(response);
    //       if (response.status === 200) {
    //         console.log("DiagnosticReport fetched successful:");
    //         console.log(response.data);
    //         setError("");
    //         const data = response.data;
    //         setColumns(data.columns); // Set dynamic columns
    //         // setTableData(createTableData(data)); // Set dynamic rows
    //         setTableData((prevData) => ({
    //           ...prevData,
    //           ...createTableData(data),  // Merge new key-value pairs into existing state
    //         }));
            
    //       } else {
    //         setError("Login failed. Please check your credentials)");
    //       }
    //     })
    //     .catch((error) => {
    //       console.error("Error:", error);
    //       setError("Login failed. Please check your credentials");
    //     })
    //     .finally(() => {
    //       setLoading(false); // Turn off loading after API call completes
    //     });
    // } catch (error) {
    //   console.error("Error:", error);
    //   setError("Error fetching data");
    // }
  };

  const reloadTableData = () => {
    fetchData();
  };

  return (
    <Container maxWidth="lg">
      <Header userName={userName} avatarUrl={avatarUrl} isLoggedIn={true} />
      {/* Top Section: Label and Form */}
      <Box
        display="flex"
        justifyContent="space-between"
        alignItems="center"
        sx={{ mt: 2, padding: 6 }}
      >
        {/* Label in top-left */}
        <Box
          sx={{
            mt: 4,
            display: "row",
            alignItems: "left",
            width: "80vh",
            padding: 2,
          }}
        >
          <Typography variant="h4">Hello, {userName}</Typography>
          <Typography variant="h6">
            Welcome to the USPayer Data Exchange Portal. If you haven't yet
            synced your data with your previous, please select your previous
            payer(s) and click 'Export' to securely transfer your data to
            USPayer. The transfer will run in the background, and you will be
            notified once the process is complete.
          </Typography>
          <Box sx={{ mt: 4, outline: 1, mr: 1, padding: 1 }}>
            <Typography variant="h5">Status: {status}</Typography>
            <Box sx={{ display: "flex", alignItems: "center" }}>
              <Box sx={{ width: "100%", mt: 2, mr: 1, padding: 2 }}>
                <LinearProgress variant="determinate" value={+exportStatus} />
              </Box>
              <Box sx={{ minWidth: 35 }}>
                <Typography
                  variant="body2"
                  sx={{ color: "text.secondary" }}
                >{`${Math.round(+exportStatus)}%`}</Typography>
              </Box>
            </Box>
          </Box>
        </Box>

        {/* Form in top-right */}
        <Box
          component="form"
          onSubmit={handleSubmit}
          sx={{ p: 2, border: "1px dashed grey", padding: 2 }}
          width={400}
        >
          {/* <TextField
          label="Name"
          variant="outlined"
          size="small"
          value={name}
          onChange={(e) => setName(e.target.value)}
          sx={{ marginRight: 2 }}
        />
        <Button type="submit" variant="contained">
          Submit
        </Button> */}
          <FormControl fullWidth variant="outlined" sx={{ mb: 2 }}>
            <InputLabel id="select-payer-label">Select Payer to Resolve Member ID</InputLabel>
            <Select
              labelId="select-payer-label"
              id="select-payer"
              multiple
              value={selectedOptions}
              onChange={handleSelectChange}
              label="Select Payer/s to Resolve Member"
            >
              {payerList.map((payer, index) => (
                <MenuItem key={index} value={payer.payerId}>
                  {payer.name}
                </MenuItem>
              ))}
            </Select>
            {/* Display selected options as tags (chips) */}
            <Box sx={{ display: "flex", flexWrap: "wrap", mt: 2 }}>
              {selectedOptions.map((option) => (
                <Box>
                  <Chip
                    key={option}
                    label={
                      payerList.find((payer) => payer.payerId === option)?.name
                    }
                    sx={{ margin: "3px" }}
                    onDelete={() => handleRemoveTag(option)} // Close icon removes the tag
                    deleteIcon={<CloseIcon />}
                  />
                  <TextField
                    label="Member ID"
                    type="text"
                    fullWidth
                    variant="outlined"
                    margin="normal"
                    value={oldMemberId}
                    onChange={(event: { target: { value: any } }) =>
                      setOldMemberId(event.target.value)
                    }
                  />
                </Box>
              ))}
            </Box>
            {/* Submit button */}
            <Button
              variant="contained"
              color="primary"
              onClick={handleSubmit}
              disabled={exporting || error != "" || oldMemberId === ""}
            >
              {exportLabel}
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
      </Box>

      {/* Collapsible Table in Bottom Section */}
      <Box sx={{ mt: 4, display: "flex", alignItems: "center" }}>
        <Switch
          checked={checked}
          onChange={handleSwitchChange}
          inputProps={{ "aria-label": "controlled" }}
        />
        <Typography variant="h6">Show Previous Data</Typography>
      </Box>
      <Box sx={{ mt: 4 }}>
        <CollapsibleTable rows={tableData} />
      </Box>
    </Container>
  );
};
