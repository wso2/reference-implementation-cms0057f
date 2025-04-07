// Copyright (c) 2024 - 2025, WSO2 LLC. (http://www.wso2.com).
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

import React, { useState, useEffect, useContext } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import "../assets/styles/appointment.css";
import MessageBox from "../components/message_box";
import appointmentImage from "../assets/images/appointment-booking.png";
import { ExpandedContext } from "../utils/expanded_context";
import { useDispatch } from "react-redux";
import { resetCdsResponse, updateCdsResponse } from "../redux/cdsResponseSlice";
import { resetCdsRequest, updateRequest } from "../redux/cdsRequestSlice";
import { useAuth } from "../components/AuthProvider";
import { HTTP_METHODS } from "../constants/enum";

// Define interfaces for Doctor, Slot, and Location objects
interface Doctor {
  name: string;
  firstName?: string;
  lastName?: string;
  id?: string;
}

interface Slot {
  start: string;
  reference: string;
  locationReference: string;
}

interface Location {
  [key: string]: string;
}

function App() {
  const { isAuthenticated } = useAuth();
  // State variables for user input and app state
  const [firstName, setFirstName] = useState<string>("");
  const [lastName, setLastName] = useState<string>("");
  const [doctorNames, setDoctorNames] = useState<Doctor[]>([]);
  const [selectedDoctor, setSelectedDoctor] = useState<Doctor | null>(null);
  const [appointmentDate, setAppointmentDate] = useState<string>("");
  const [availableSlots, setAvailableSlots] = useState<Slot[]>([]);
  const [locations, setLocations] = useState<Location>({});
  const [selectedSlot, setSelectedSlot] = useState<Slot | null>(null);
  const [appointmentCreated, setAppointmentCreated] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false); // Spinner state for doctor search
  const [loadingSlots, setLoadingSlots] = useState<boolean>(false); // Spinner state for slots
  const [creatingAppointment, setCreatingAppointment] =
    useState<boolean>(false);
  const navigate = useNavigate();
  const { expanded } = useContext(ExpandedContext);
  const dispatch = useDispatch();

  // Message box state
  const [message, setMessage] = useState<string>("");
  const [messageType, setMessageType] = useState<
    "success" | "error" | "warning"
  >("success");
  const [showMessageBox, setShowMessageBox] = useState<boolean>(false);

  // Function to show a message box for two seconds
  const showMessage = (msg: string, type: "success" | "error" | "warning") => {
    setMessage(msg);
    setMessageType(type);
    setShowMessageBox(true);
    setTimeout(() => setShowMessageBox(false), 2000); // Auto-close after 2 seconds
  };

  // Fetches list of doctors based on the entered first and last name
  const handleSearch = async () => {
    if (!firstName || !lastName) {
      showMessage("Please enter both first and last name.", "warning");
      return;
    }

    // Reset state before a new search
    setSelectedDoctor(null);
    setAvailableSlots([]);
    setSelectedSlot(null);
    setAppointmentDate("");
    setAppointmentCreated(false); // Clear any appointment state

    setLoading(true); // Show spinner while loading doctors
    const Config = window.Config;
    const url = `${Config.baseUrl}${Config.practitioner}?family=${lastName}&given=${firstName}`;
    dispatch(resetCdsRequest());
    dispatch(updateRequest({ Method: HTTP_METHODS.GET, URL: url }));
    dispatch(resetCdsResponse());
    try {
      const res = await fetch(url);
      const data = await res.json();
      dispatch(updateCdsResponse({ cards: data }));

      const names = data.entry.map((entry: any) => ({
        name: entry.resource.name[0].text,
        id: entry.resource.id,
      }));

      setDoctorNames(names);
      setLoading(false); // // Hide loading indicator
    } catch (error) {
      console.error("Error fetching doctor data:", error);
      showMessage("Error fetching doctor data.", "error");
      setLoading(false); // Hide spinner if there's an error
    }
  };

  // Sets the selected doctor when clicked
  const handleDoctorClick = (doctor: Doctor) => {
    setSelectedDoctor(doctor);
    setAvailableSlots([]);
    setSelectedSlot(null); // Reset selected slot when doctor changes
  };

  const handleDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setAppointmentDate(e.target.value);
  };

  // Fetches available slots for the selected doctor and date
  const handleAppointment = async () => {
    if (selectedDoctor && appointmentDate) {
      setAvailableSlots([]);
      setSelectedSlot(null);
      setAppointmentCreated(false); // Clear any previous appointment receipt

      setLoadingSlots(true); // Show spinner while loading slots
      const startDate = appointmentDate;
      const endDate = appointmentDate;
      const practitionerId = selectedDoctor.id;
      const Config = window.Config;

      const url = `${Config.baseUrl}${Config.slot}?startDate=${startDate}&endDate=${endDate}&practitioner=${practitionerId}`;
      dispatch(resetCdsRequest());
      dispatch(updateRequest({ Method: HTTP_METHODS.GET, URL: url }));
      dispatch(resetCdsResponse());

      try {
        const res = await fetch(url);
        const data = await res.json();
        dispatch(updateCdsResponse({ cards: data }));

        const slots = data.entry.map((entry: any) => ({
          start: entry.resource.start,
          reference: entry.resource.id,
          locationReference:
            entry.resource.extension[0].valueReference.reference
              .split("/")
              .pop(),
        }));

        setAvailableSlots(slots);
        fetchLocationNames(slots);
        setLoadingSlots(false);
      } catch (error) {
        console.error("Error fetching slot data:", error);
        showMessage("Error fetching slot data.", "error");
        setLoadingSlots(false);
      }
    } else {
      showMessage("Please select a doctor and an appointment date.", "warning");
    }
  };

  // Fetches location names for each slot's location reference
  const fetchLocationNames = async (slots: Slot[]) => {
    const newLocations: Location = { ...locations };

    for (const slot of slots) {
      if (!newLocations[slot.locationReference]) {
        try {
          const Config = window.Config;
          const locationUrl = `${Config.baseUrl}${Config.location}/${slot.locationReference}`;
          const res = await fetch(locationUrl);
          const data = await res.json();
          newLocations[slot.locationReference] = data.name;
        } catch (error) {
          console.error(
            `Error fetching location for reference ${slot.locationReference}:`,
            error
          );
          showMessage(
            `Error fetching location for reference ${slot.locationReference}`,
            "error"
          );
          newLocations[slot.locationReference] = "Unknown location";
        }
      }
    }

    setLocations(newLocations);
  };

  // Sets the selected slot when clicked
  const handleSlotClick = (slot: Slot) => {
    setSelectedSlot(slot);
  };

  // useEffect to handle navigation to appointment-receipt page after appointment is created successfully
  useEffect(() => {
    if (appointmentCreated && selectedDoctor && selectedSlot) {
      setMessage("Appointment successfully created!");
      setMessageType("success");
      setShowMessageBox(true);
      // dispatch(updateCdsHook("AS"));

      // Navigate to receipt page after a delay
      const timer = setTimeout(() => {
        navigate("/dashboard/appointment-receipt", {
          state: {
            doctorName: selectedDoctor.name,
            patientName: "Emily Davis",
            date: new Date(selectedSlot.start).toLocaleDateString(),
            time: new Date(selectedSlot.start).toLocaleTimeString(),
            location:
              locations[selectedSlot.locationReference] || "Unknown location",
            referenceID: selectedSlot.reference,
          },
        });
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [appointmentCreated, selectedDoctor, selectedSlot, navigate, locations]);

  // Handles creating the appointment with selected slot
  const createAppointment = async () => {
    if (!selectedSlot) {
      showMessage(
        "Please select a slot before creating an appointment.",
        "warning"
      );
      return;
    }

    setCreatingAppointment(true); // Start the loading state

    const appointmentData = {
      resourceType: "Appointment",
      status: "booked",
      slot: [
        {
          reference: `Slot/${selectedSlot.reference}`,
        },
      ],
      start: selectedSlot.start,
      end: new Date(
        new Date(selectedSlot.start).getTime() + 30 * 60000
      ).toISOString(),
      participant: [
        {
          actor: {
            reference: "Patient/12724066", // Hardcoded for now
          },
          status: "accepted",
        },
      ],
    };

    try {
      const Config = window.Config;
      const appointmentUrl = `${Config.baseUrl}${Config.appointment}`;
      dispatch(resetCdsRequest());
      dispatch(
        updateRequest({
          Method: HTTP_METHODS.POST,
          URL: appointmentUrl,
          "Content-Type": "application/fhir+json",
          payload: appointmentData,
        })
      );

      const res = await fetch(appointmentUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/fhir+json",
        },
        body: JSON.stringify(appointmentData),
      });

      if (res.ok) {
        dispatch(updateCdsResponse({ cards: res.body }));
        showMessage("Appointment successfully created!", "success");
        setAppointmentCreated(true); // Set state to show receipt after successful creation
      } else {
        showMessage("Failed to create appointment.", "error");
      }
    } catch (error) {
      console.error("Error creating appointment:", error);
      showMessage("Error creating appointment.", "error");
    } finally {
      setCreatingAppointment(false); // End the loading state
    }
  };

  // Filters unique slots by start time and location to avoid duplicates
  const getUniqueSlots = () => {
    const uniqueSlots: Slot[] = [];
    const seenSlots = new Set<string>();

    for (const slot of availableSlots) {
      const location = locations[slot.locationReference] || "Loading...";
      const slotKey = `${slot.start}-${location}`;

      if (!seenSlots.has(slotKey)) {
        uniqueSlots.push(slot);
        seenSlots.add(slotKey); // Track unique slots based on start time and location
      }
    }

    return uniqueSlots;
  };

  /*
The return() function defines the structure and user interface for the appointment booking feature. It includes the following. 
1. **Doctor Search Section**: 
   - Displays input fields for entering the doctor's first and last name and a "Search Doctor" button.
   - The button is disabled if the component is in a loading state (e.g., fetching doctor data).
   - On clicking "Search Doctor," it triggers a function to fetch and display matching doctors.

2. **Doctor Search Results**:
   - Displays a list of doctors returned from the search, allowing the user to select a doctor.
   - The selected doctor’s box is visually highlighted.

3. **Appointment Date Selection**:
   - This section becomes visible once a doctor is selected.
   - Provides a date input to select the desired appointment date.
   - Includes a button labeled "Check Availability" that fetches available time slots for the selected doctor and date.

4. **Available Slots**:
   - Displays a list of available time slots after fetching slot data.
   - Each slot shows the start time and location.
   - The user can select a slot, which visually highlights the chosen slot.
   - The "Create Appointment" button becomes enabled once a slot is selected and triggers the appointment creation process.
   - When creating an appointment, this section is temporarily disabled and shows a spinner to indicate progress.

5. **Message Box**:
   - A message box appears to notify the user of various states (e.g., success, error, or warning messages) based on their actions.
   - It auto-hides after a short delay or can be manually closed.

6. **Conditional Elements and Loading Spinners**:
   - Spinners appear during asynchronous operations, such as loading doctors, fetching available slots, or creating the appointment, to provide visual feedback on the loading status.
   - Conditional rendering ensures that elements (like date selection and available slots) appear only when relevant actions are completed or states are set (e.g., a doctor is selected, slots are available).

The entire layout is styled using CSS classes to enhance readability, usability, and responsiveness, providing a smooth user experience for booking appointments.
*/

  return isAuthenticated ? (
    <div className="appointment-ui">
      <div className="container">
        <div className="book-appointment-heading">Book an Appointment</div>

        <div className="form-and-image-container">
          <div className="input-container">
            <input
              type="text"
              placeholder="First Name"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
            />
            <input
              type="text"
              placeholder="Last Name"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
            />
            <button
              onClick={handleSearch}
              disabled={loading || creatingAppointment}
            >
              {loading ? "Searching..." : "Search Doctor"}
            </button>
          </div>
        </div>

        {/* Display spinner while loading doctors */}
        {loading && <div className="spinner">Loading doctors...</div>}

        {doctorNames.length > 0 && !loading && (
          <div className="results">
            <div className="other-headings">Doctor Search Results</div>
            <div className="doctor-list">
              {doctorNames.map((doctor, index) => (
                <div
                  key={index}
                  className={`doctor-box ${
                    selectedDoctor && selectedDoctor.id === doctor.id
                      ? "selected"
                      : ""
                  }`}
                  onClick={() => handleDoctorClick(doctor)}
                >
                  {doctor.name}
                </div>
              ))}
            </div>
          </div>
        )}

        {!expanded && (
          <div className="image-container">
            <img
              src={appointmentImage}
              alt="Appointment Image"
              className="right-image"
            />
          </div>
        )}

        {/* Show calendar and slots only if a doctor is selected */}
        {selectedDoctor && (
          <div className="calendar-container">
            <h2>Select an Appointment Date:</h2>
            <input
              type="date"
              value={appointmentDate}
              onChange={handleDateChange}
            />
            <button
              onClick={handleAppointment}
              disabled={loadingSlots || creatingAppointment}
            >
              {loadingSlots ? "Checking Availability..." : "Check Availability"}
            </button>
          </div>
        )}

        {/* Display spinner while loading slots */}
        {loadingSlots && <div className="spinner">Loading slots...</div>}

        {/* Show available slots after fetching them */}
        {availableSlots.length > 0 && !loadingSlots && (
          <div className="available-slots">
            <h3>Available Slots:</h3>
            <div className="slot-list">
              {getUniqueSlots().map((slot, index) => (
                <div
                  key={index}
                  className={`slot-box ${
                    selectedSlot && selectedSlot.reference === slot.reference
                      ? "selected-slot"
                      : ""
                  }`}
                  onClick={() => !creatingAppointment && handleSlotClick(slot)} // Prevent click if creatingAppointment is true
                  style={{
                    pointerEvents: creatingAppointment ? "none" : "auto", // Disable clicks
                    opacity: creatingAppointment ? 0.5 : 1, // Change appearance to indicate disabled state
                  }}
                >
                  <p>
                    <strong>Start Time:</strong>{" "}
                    {new Date(slot.start).toLocaleString()}
                  </p>
                  <p>
                    <strong>Location:</strong>{" "}
                    {locations[slot.locationReference] || "Loading..."}
                  </p>
                </div>
              ))}
            </div>
            {selectedSlot && (
              <button
                className="create-appointment"
                onClick={createAppointment}
                disabled={creatingAppointment}
              >
                {creatingAppointment
                  ? "Creating Appointment..."
                  : "Create Appointment"}
              </button>
            )}

            {/* Display spinner while creating the appointment */}
            {creatingAppointment && (
              <div className="spinner">
                The appointment is being created. Please wait!
              </div>
            )}
          </div>
        )}

        {/* Message box */}
        {showMessageBox && (
          <MessageBox
            message={message}
            type={messageType}
            onClose={() => setShowMessageBox(false)}
          />
        )}
      </div>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}

export default App;
