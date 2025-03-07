import { useLocation } from 'react-router-dom';
import medconnectLogo from '../assets/images/medconnect.png';

interface LocationState {
  doctorName: string;
  patientName: string;
  date: string;
  time: string;
  location: string;
  referenceID: string;
}

function AppointmentReceipt() {
  const location = useLocation();
  const state = location.state as LocationState | undefined;

  if (!state) {
    return <p>Error: No appointment data available.</p>;
  }

  const { doctorName, patientName, date, time, location: appointmentLocation, referenceID } = state;

  return (
    <div className="receipt-page">
      <img src={medconnectLogo} alt="MedConnect Logo" className="receipt-logo" />
      <h2>Appointment Receipt</h2>
      <p><strong>Appointment Reference:</strong> {referenceID}</p>
      <p><strong>Appointment Status:</strong> Confirmed</p>
      <p><strong>Patient Name:</strong> {patientName}</p>
      <p><strong>Doctor Name:</strong> {doctorName}</p>
      <p><strong>Date:</strong> {date}</p>
      <p><strong>Time:</strong> {time}</p>
      <p><strong>Location:</strong> {appointmentLocation}</p>

      {/* Additional Instructions */}
      <div className="receipt-notice">
        <ul>
          <li>Your channeling is complete. Please note the reference No.</li>
          <li>For your benefit, you could obtain a print copy of this page.</li>
          <li>Please be at the hospital 15 minutes before the given time.</li>
          <li>The reference number is essential for you to be able to consult the doctor.</li>
          <li>The appointment time shown is only an approximate time. It may be subject to change depending on the doctor's arrival time and the time spent with patients ahead of you.</li>
          <li>In the event of the doctor canceling the appointment, the patient could secure a refund on the doctor fee and/or hospital fee at the discretion of the hospital. Alternatively, you may be able to reschedule the appointment for the same doctor at the hospital for another time and date.</li>
          <li>MedConnect PLC is not liable for any loss or damages incurred due to a doctor canceling or rescheduling appointments.</li>
        </ul>

        <p>Wishing You Good Health!!</p>
      </div>

    </div>
  );
}

export default AppointmentReceipt;
