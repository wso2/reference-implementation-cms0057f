import React, { useState } from "react";
import Form from "react-bootstrap/Form";
import Card from "react-bootstrap/Card";
import Button from "react-bootstrap/Button";
import Select from "react-select";
import DatePicker from "react-datepicker";
import { Alert, Snackbar } from "@mui/material";

// Import required CSS files
// import "bootstrap/dist/css/bootstrap.min.css";c

const SamplePage = () => {
    const [formData, setFormData] = useState({});
    const [openSnackbar, setOpenSnackbar] = useState(false);
    const [alertMessage, setAlertMessage] = useState<string | null>(null);
    const [alertSeverity, setAlertSeverity] = useState<"error" | "success">(
        "success"
    );

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target;
        setFormData({ ...formData, [name]: value });
    };

    const handleBooleanChange = (selectedOption: any, name: string) => {
        setFormData({ ...formData, [name]: selectedOption?.value === "Yes" });
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setAlertMessage("Sample form submitted successfully!");
        setAlertSeverity("success");
        setOpenSnackbar(true);
    };

    const handleCloseSnackbar = () => {
        setOpenSnackbar(false);
    };

    return (
        <div style={{ marginLeft: 50, marginBottom: 50 }}>
            <div className="page-heading">
                Send a Prior-Authorizing Request for Drugs (Sample)
            </div>
            <Card style={{ marginTop: "30px", padding: "20px" }}>
                <Card.Body>
                    <Card.Title>Patient Details</Card.Title>
                    <div style={{ display: "flex", gap: "20px" }}>
                        <Form.Group
                            controlId="formPatientName"
                            style={{ marginTop: "20px", flex: "1 1 100%" }}
                        >
                            <Form.Label>Patient Name</Form.Label>
                            <Form.Control type="text" value="John Doe" disabled />
                        </Form.Group>
                        <Form.Group
                            controlId="formPatientID"
                            style={{ marginTop: "20px", flex: "1 1 100%" }}
                        >
                            <Form.Label>Patient ID</Form.Label>
                            <Form.Control type="text" value="12345" disabled />
                        </Form.Group>
                    </div>
                </Card.Body>
            </Card>
            <Card style={{ marginTop: "30px", padding: "20px" }}>
                <Card.Body>
                    <Card.Title>Prescribed Medicine</Card.Title>
                    <Form>
                        <Form.Group
                            controlId="formTreatingSickness"
                            style={{ marginTop: "20px" }}
                        >
                            <Form.Label>Treating Sickness</Form.Label>
                            <Form.Control type="text" value="Flu" disabled />
                        </Form.Group>
                        <Form.Group
                            controlId="formMedication"
                            style={{ marginTop: "20px" }}
                        >
                            <Form.Label>Medication</Form.Label>
                            <Form.Control type="text" value="Paracetamol" disabled />
                        </Form.Group>
                        <div style={{ display: "flex", gap: "20px" }}>
                            <Form.Group
                                controlId="formQuantity"
                                style={{ marginTop: "20px", flex: "1 1 100%" }}
                            >
                                <Form.Label>Quantity</Form.Label>
                                <Form.Control type="text" value="10" disabled />
                            </Form.Group>
                            <Form.Group
                                controlId="formFrequency"
                                style={{ marginTop: "20px", flex: "1 1 100%" }}
                            >
                                <Form.Label>Frequency</Form.Label>
                                <Form.Control type="text" value="Twice a day" disabled />
                            </Form.Group>
                            <Form.Group
                                controlId="formDuration"
                                style={{ marginTop: "20px", flex: "1 1 100%" }}
                            >
                                <Form.Label>Duration (days)</Form.Label>
                                <Form.Control type="text" value="5" disabled />
                            </Form.Group>
                            <Form.Group
                                controlId="formStartDate"
                                style={{ marginTop: "20px", flex: "1 1 100%", width: "100%" }}
                            >
                                <Form.Label>Starting Date</Form.Label>
                                <br />
                                <DatePicker
                                    selected={new Date()}
                                    dateFormat="yyyy/MM/dd"
                                    className="form-control"
                                    wrapperClassName="date-picker-full-width"
                                />
                            </Form.Group>
                        </div>
                    </Form>
                </Card.Body>
            </Card>
            <Card style={{ marginTop: "30px", padding: "20px" }}>
                <Card.Body>
                    <Card.Title>Questionnaire</Card.Title>
                    <Form onSubmit={handleSubmit}>
                        <Form.Group controlId="formQuestion1" style={{ marginTop: "20px" }}>
                            <Form.Label>
                                Do you have any allergies? <span style={{ color: "red" }}>*</span>
                            </Form.Label>
                            <Select
                                name="question1"
                                onChange={(selectedOption) =>
                                    handleBooleanChange(selectedOption, "question1")
                                }
                                options={[
                                    { value: "Yes", label: "Yes" },
                                    { value: "No", label: "No" },
                                ]}
                            />
                        </Form.Group>
                        <Form.Group controlId="formQuestion2" style={{ marginTop: "20px" }}>
                            <Form.Label>
                                How many times do you exercise per week?{" "}
                                <span style={{ color: "red" }}>*</span>
                            </Form.Label>
                            <Form.Control
                                type="number"
                                name="question2"
                                onChange={handleInputChange}
                            />
                        </Form.Group>
                        <Button
                            variant="primary"
                            type="submit"
                            style={{ marginTop: "30px", float: "right" }}
                        >
                            Submit Questionnaire Response
                        </Button>
                    </Form>
                </Card.Body>
            </Card>
            <Snackbar
                open={openSnackbar}
                autoHideDuration={6000}
                onClose={handleCloseSnackbar}
                anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            >
                <Alert onClose={handleCloseSnackbar} severity={alertSeverity}>
                    {alertMessage}
                </Alert>
            </Snackbar>
            <style>{`
        .card {
          height: 100%;
          display: flex;
          flex-direction: column;
        }
        .card-body {
          flex: 1;
        }
      `}</style>
        </div>
    );
};

export default SamplePage;
