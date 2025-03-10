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

import { MedicationRequest } from "../components/interfaces/medicationRequest";

export function constructMedicationRequestResource(
  drugName: string,
  dosage: string,
  numberOfTablets: number,
  startDate: string,
  endDate: string,
  frequency: string,
  patientID: string
) {
  const today = new Date();
  const year = today.getFullYear();
  const month = ("0" + (today.getMonth() + 1)).slice(-2);
  const day = ("0" + today.getDate()).slice(-2);

  const todayDate = `${year}-${month}-${day}`;

  let med_frequency = 0;

  if (frequency === "Once a day") {
    med_frequency = 1;
  } else if (frequency === "Twice a day") {
    med_frequency = 2;
  } else if (frequency === "Thrice a day") {
    med_frequency = 3;
  }

  let tabletNote = "";

  if (numberOfTablets === 1) {
    tabletNote = "One tablet at a time";
  } else if (numberOfTablets === 2) {
    tabletNote = "Two tablets at once";
  } else if (numberOfTablets === 3) {
    tabletNote = "Three tablets at once";
  }

  const start = new Date(startDate);
  const end = new Date(endDate);
  const differenceInTime = end.getTime() - start.getTime();
  const differenceInDays = differenceInTime / (1000 * 3600 * 24);

  const MEDICATION_REQUEST_RESOURCE: MedicationRequest = {
    resourceType: "MedicationRequest",
    id: "medrx030198JK",
    text: {
      status: "generated",
      div: '<div xmlns="http://www.w3.org/1999/xhtml"><p><b>Generated Narrative: MedicationRequest</b><a name="example"> </a></p><div style="display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%"><p style="margin-bottom: 0px">Resource MedicationRequest &quot;example&quot; </p></div><p><b>identifier</b>: id:\u00a012345689\u00a0(use:\u00a0OFFICIAL)</p><p><b>status</b>: draft</p><p><b>intent</b>: order</p><p><b>medication</b>: <a name="med0320"> </a></p><blockquote><p/><p><a name="med0320"> </a></p><p><b>code</b>: Azithromycin 250 mg oral tablet <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#1145423002)</span></p></blockquote><p><b>subject</b>: <a href="Patient-example.html">Patient/example</a> &quot; SHAW&quot;</p><p><b>encounter</b>: <a href="Encounter-example.html">Encounter/example</a></p><p><b>authoredOn</b>: 2015-01-15</p><p><b>requester</b>: <a href="Practitioner-example.html">Practitioner/example</a> &quot; CAREFUL&quot;</p><p><b>reasonCode</b>: Traveler\'s Diarrhea (disorder) <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#11840006)</span></p><p><b>insurance</b>: <a href="Coverage-example.html">Coverage/example</a></p><p><b>note</b>: Patient told to take with food</p><blockquote><p><b>dosageInstruction</b></p><p><b>sequence</b>: 1</p><p><b>text</b>: Two tablets at once</p><p><b>additionalInstruction</b>: With or after food <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#311504000)</span></p><p><b>timing</b>: Once per 1 days</p><p><b>route</b>: Oral Route <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#26643006)</span></p><p><b>method</b>: Swallow - dosing instruction imperative (qualifier value) <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#421521009)</span></p><blockquote><p><b>doseAndRate</b></p></blockquote></blockquote><blockquote><p><b>dosageInstruction</b></p><p><b>sequence</b>: 2</p><p><b>text</b>: One tablet daily for 4 days</p><p><b>additionalInstruction</b>: With or after food <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#311504000)</span></p><p><b>timing</b>: 4 per 1 days</p><p><b>route</b>: Oral Route <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#26643006)</span></p><blockquote><p><b>doseAndRate</b></p></blockquote></blockquote><blockquote><p><b>dispenseRequest</b></p><p><b>validityPeriod</b>: 2015-01-15 --&gt; 2016-01-15</p><p><b>numberOfRepeatsAllowed</b>: 1</p><p><b>quantity</b>: 6 TAB<span style="background: LightGoldenRodYellow"> (Details: http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm code TAB = \'Tablet\')</span></p><h3>ExpectedSupplyDurations</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Value</b></td><td><b>Unit</b></td><td><b>System</b></td><td><b>Code</b></td></tr><tr><td style="display: none">*</td><td>5</td><td>days</td><td><a href="http://terminology.hl7.org/5.3.0/CodeSystem-v3-ucum.html">Unified Code for Units of Measure (UCUM)</a></td><td>d</td></tr></table></blockquote><h3>Substitutions</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Allowed[x]</b></td><td><b>Reason</b></td></tr><tr><td style="display: none">*</td><td>true</td><td>formulary policy <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="http://terminology.hl7.org/5.3.0/CodeSystem-v3-ActReason.html">ActReason</a>#FP)</span></td></tr></table><hr/><blockquote><p><b>Generated Narrative: Medication #med0320</b><a name="med0320"> </a></p><p><b>code</b>: Azithromycin 250 mg oral tablet <span style="background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki"> (<a href="https://browser.ihtsdotools.org/">SNOMED CT</a>#1145423002)</span></p></blockquote></div>',
    },
    contained: [
      {
        resourceType: "Medication",
        id: "med0320",
        code: {
          coding: [
            {
              system: "http://snomed.info/sct",
              code: "114542312402",
              display: `${drugName} ${dosage} oral tablet`,
            },
          ],
        },
      },
    ],
    status: "draft",
    intent: "order",
    medicationReference: {
      reference: "#med0320",
    },
    subject: {
      reference: "Patient/" + patientID,
    },
    encounter: {
      reference: "Encounter/example",
    },
    authoredOn: todayDate,
    requester: {
      reference: "Practitioner/1895AD3",
    },
    reasonCode: [
      {
        coding: [
          {
            system: "http://snomed.info/sct",
            code: "11840006",
            display: "Traveler's Diarrhea (disorder)",
          },
        ],
      },
    ],
    note: [
      {
        text: "Patient told to take with food",
      },
    ],
  };

  if (med_frequency !== 0 && numberOfTablets !== 0) {
    MEDICATION_REQUEST_RESOURCE.dosageInstruction = [
      {
        sequence: 1,
        text: tabletNote,
        additionalInstruction: [
          {
            coding: [
              {
                system: "http://snomed.info/sct",
                code: "311504000",
                display: "With or after food",
              },
            ],
          },
        ],
        timing: {
          repeat: {
            frequency: med_frequency,
            period: 1,
            periodUnit: "d",
          },
        },
        route: {
          coding: [
            {
              system: "http://snomed.info/sct",
              code: "26643006",
              display: "Oral Route",
            },
          ],
        },
        method: {
          coding: [
            {
              system: "http://snomed.info/sct",
              code: "421521009",
              display:
                "Swallow - dosing instruction imperative (qualifier value)",
            },
          ],
        },
        doseAndRate: [
          {
            type: {
              coding: [
                {
                  system:
                    "http://terminology.hl7.org/CodeSystem/dose-rate-type",
                  code: "ordered",
                  display: "Ordered",
                },
              ],
            },
            doseQuantity: {
              value: numberOfTablets,
              unit: "TAB",
              system:
                "http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm",
              code: "TAB",
            },
          },
        ],
      },
    ];
  }

  if (startDate !== "" && endDate !== "") {
    MEDICATION_REQUEST_RESOURCE.dispenseRequest = {
      validityPeriod: {
        start: startDate,
        end: endDate,
      },
      numberOfRepeatsAllowed: 1,
      quantity: {
        value: 6,
        unit: "TAB",
        system: "http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm",
        code: "TAB",
      },
      expectedSupplyDuration: {
        value: differenceInDays,
        unit: "days",
        system: "http://unitsofmeasure.org",
        code: "d",
      },
    };
  }

  return MEDICATION_REQUEST_RESOURCE;
}
