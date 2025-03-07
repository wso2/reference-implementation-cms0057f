// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

import {
  APPOINTMENT_TYPE,
  PATIENT_DETAILS,
  SPECIALITY,
  PRACTITIONERS,
} from "../constants/data";
import { AppointmentResource } from "../components/interfaces/appointment";

export function constructAppointmentResource(
  practitioner: string,
  speciality: string,
  date: string,
  hospital: string,
  slots: string,
  treatingDisease: string,
  appointmentType: string,
  description: string,
  patientId: string
) {
  let [startTime, endTime] = slots.split(" - ");
  startTime = `${date}T${startTime}Z`;
  endTime = `${date}T${endTime}Z`;

  const today = new Date();
  const year = today.getFullYear();
  const month = ("0" + (today.getMonth() + 1)).slice(-2); // Months are 0 based, so +1 and pad with 0
  const day = ("0" + today.getDate()).slice(-2);

  const todayDate = `${year}-${month}-${day}`;

  const selectedAppointmentType = APPOINTMENT_TYPE.find(
    (appointment) => appointment.display === appointmentType
  );

  const selectedSpeciality = SPECIALITY.find(
    (curSpeciality) => curSpeciality.Display === speciality
  );

  const selectedPractitioner = PRACTITIONERS.find(
    (curPractitioner) => curPractitioner.Name === practitioner
  );

  const selectedHospitalId = "12343";

  let currentPatient = PATIENT_DETAILS.find(
    (patient) => patient.id === patientId
  );
  if (!currentPatient) {
    currentPatient = PATIENT_DETAILS[0];
  }

  const APPOINTMENT_RESOURCE: AppointmentResource = {
    resourceType: "Appointment",
    id: "example",
    text: {
      status: "generated",
      div: '<div xmlns="http://www.w3.org/1999/xhtml"><p><b>Generated Narrative: Appointment</b><a name="example"> </a></p><div style="display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%"><p style="margin-bottom: 0px">Resource Appointment &quot;example&quot; </p></div><p><b>status</b>: proposed</p><p><b>serviceCategory</b>: General Practice <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-service-category.html">Service category</a>#17)</span></p><p><b>serviceType</b>: General Practice <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-service-type.html">Service type</a>#124)</span></p><p><b>specialty</b>: General practice (specialty) <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#394814009)</span></p><p><b>appointmentType</b>: A follow up visit from a previous appointment <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-v2-0276.html">appointmentReason</a>#FOLLOWUP)</span></p><p><b>reasonReference</b>: <a href="http://example.org/fhir/Condition/example">http://example.org/fhir/Condition/example: Heart problem</a></p><p><b>priority</b>: 5</p><p><b>description</b>: Discussion on the results of your recent MRI</p><p><b>start</b>: Dec 10, 2013, 9:00:00 AM</p><p><b>end</b>: Dec 10, 2013, 11:00:00 AM</p><p><b>created</b>: 2013-10-10</p><p><b>comment</b>: Further expand on the results of the MRI and determine the next actions that may be appropriate.</p><p><b>basedOn</b>: <a href="ServiceRequest-example.html">ServiceRequest/example</a></p><blockquote><p><b>participant</b></p><p><b>actor</b>: <a href="Patient-example.html">Patient/example: Amy Baxter</a> &quot; SHAW&quot;</p><p><b>required</b>: required</p><p><b>status</b>: accepted</p></blockquote><blockquote><p><b>participant</b></p><p><b>type</b>: attender <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-v3-ParticipationType.html">ParticipationType</a>#ATND)</span></p><p><b>actor</b>: <a href="Practitioner-example.html">Practitioner/example: Dr Adam Careful</a> &quot; CAREFUL&quot;</p><p><b>required</b>: required</p><p><b>status</b>: accepted</p></blockquote><blockquote><p><b>participant</b></p><p><b>actor</b>: <a href="Location-example.html">Location/example: South Wing, second floor</a> &quot;South Wing, second floor&quot;</p><p><b>required</b>: required</p><p><b>status</b>: accepted</p></blockquote><p><b>requestedPeriod</b>: 2020-11-01 --&gt; 2020-12-15</p></div>"},r: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#394814009)</span></p><p><b>appointmentType</b>: A follow up visit from a previous appointment <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-v2-0276.html">appointmentReason</a>#FOLLOWUP)</span></p><p><b>reasonReference</b>: <a href="http://example.org/fhir/Condition/example">http://example.org/fhir/Condition/example: Heart problem</a></p><p><b>priority</b>: 5</p><p><b>description</b>: Discussion on the results of your recent MRI</p><p><b>start</b>: Dec 10, 2013, 9:00:00 AM</p><p><b>end</b>: Dec 10, 2013, 11:00:00 AM</p><p><b>created</b>: 2013-10-10</p><p><b>comment</b>: Further expand on the results of the MRI and determine the next actions that may be appropriate.</p><p><b>basedOn</b>: <a href="ServiceRequest-example.html">ServiceRequest/example</a></p><blockquote><p><b>participant</b></p><p><b>actor</b>: <a href="Patient-example.html">Patient/example: Amy Baxter</a> &quot; SHAW&quot;</p><p><b>required</b>: required</p><p><b>status</b>: accepted</p></blockquote><blockquote><p><b>participant</b></p><p><b>type</b>: attender <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-v3-ParticipationType.html">ParticipationType</a>#ATND)</span></p><p><b>actor</b>: <a href="Practitioner-example.html">Practitioner/example: Dr Adam Careful</a> &quot; CAREFUL&quot;</p><p><b>required</b>: required</p><p><b>status</b>: accepted</p></blockquote><blockquote><p><b>participant</b></p><p><b>actor</b>: <a href="Location-example.html">Location/example: South Wing, second floor</a> &quot;South Wing, second floor&quot;</p><p><b>required</b>: required</p><p><b>status</b>: accepted</p></blockquote><p><b>requestedPeriod</b>: 2020-11-01 --&gt; 2020-12-15</p></div>',
    },
    status: "proposed",
    serviceCategory: [
      {
        coding: [
          {
            system: "http://terminology.hl7.org/CodeSystem/service-category",
            code: "17",
            display: "General Practice",
          },
        ],
      },
    ],
    serviceType: [
      {
        coding: [
          {
            system: "http://terminology.hl7.org/CodeSystem/service-type",
            code: "124",
            display: "General Practice",
          },
        ],
      },
    ],
    priority: 5,
    created: todayDate,
    basedOn: [
      {
        reference: "ServiceRequest/example",
      },
    ],
    participant: [
      {
        actor: {
          reference: "Patient/" + patientId,
          display:
            currentPatient.name[0].given[0] +
            " " +
            currentPatient.name[0].family,
        },
        required: "required",
        status: "accepted",
      },
    ],
  };

  if (practitioner !== "" || practitioner !== undefined) {
    APPOINTMENT_RESOURCE.participant?.push({
      type: [
        {
          coding: [
            {
              system:
                "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
              code: "ATND",
            },
          ],
        },
      ],
      actor: {
        reference: "Practitioner/" + selectedPractitioner?.ID,
        display: practitioner,
      },
      required: "required",
      status: "tentative",
    });
  }

  if (hospital !== "" || hospital !== undefined) {
    APPOINTMENT_RESOURCE.participant?.push({
      actor: {
        reference: "Location/" + selectedHospitalId,
        display: hospital,
      },
      required: "required",
      status: "accepted",
    });
  }

  if (selectedSpeciality !== undefined || selectedSpeciality !== "") {
    APPOINTMENT_RESOURCE.specialty = [
      {
        coding: [
          {
            system: "http://snomed.info/sct",
            code: selectedSpeciality?.Code,
            display: speciality,
          },
        ],
      },
    ];
  }

  if (date !== "" || date !== undefined) {
    APPOINTMENT_RESOURCE.requestedPeriod = [
      {
        start: todayDate,
        end: date,
      },
    ];
  }

  if (description !== "" || description !== undefined) {
    APPOINTMENT_RESOURCE.description = description;
  }

  if (slots !== "" || slots !== undefined) {
    APPOINTMENT_RESOURCE.start = startTime;
    APPOINTMENT_RESOURCE.end = endTime;
  }

  if (selectedAppointmentType !== undefined) {
    APPOINTMENT_RESOURCE.appointmentType = {
      coding: [
        {
          system: selectedAppointmentType.system,
          code: selectedAppointmentType.code,
          display: selectedAppointmentType.display,
        },
      ],
    };
  }

  if (treatingDisease !== "" || treatingDisease !== undefined) {
    APPOINTMENT_RESOURCE.reasonReference = [
      {
        reference: "http://example.org/fhir/Condition/example",
        display: treatingDisease,
      },
    ];
  }

  return APPOINTMENT_RESOURCE;
}
