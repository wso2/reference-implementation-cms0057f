// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/time;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.parser;

isolated ExplanationOfBenefit[] eobs = [];
isolated int createEOBNextId = 14453;

public isolated function createEob(json payload) returns r4:FHIRError|ExplanationOfBenefit {
    ExplanationOfBenefit|error eob = parser:parse(payload).ensureType();
    if eob is error {
        return r4:createFHIRError(eob.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createEOBNextId += 1;
            eob.id = (createEOBNextId).toBalString();
        }
        lock {
            eobs.push(eob.clone());
        }
        return eob;
    }
}

public isolated function getByIdEob(string id) returns r4:FHIRError|ExplanationOfBenefit {
    lock {
        foreach var item in eobs {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an EOB resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function searchEob(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? patient = ();
        string? identifier = ();
        string? created = ();
        string? profile = ();
        string? lastUpdated = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "_profile" => {
                    profile = searchParameters.get('key)[0];
                }
                "_lastUpdated" => {
                    lastUpdated = searchParameters.get('key)[0];
                }
                "patient" => {
                    patient = searchParameters.get('key)[0];
                }
                "identifier" => {
                    identifier = searchParameters.get('key)[0];
                }
                "created" => {
                    created = searchParameters.get('key)[0];
                }
                "_count" => {
                    // pagination is not used in this service
                    continue;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }

        if id is string {
            ExplanationOfBenefit byId = check getByIdEob(id);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];

            bundle.total = 1;
            return bundle;
        }

        ExplanationOfBenefit[] results;
        lock {
            results = eobs.clone();
        }

        if profile is string {
            results = getByProfileEob(profile, results);
        }

        if lastUpdated is string {
            results = check getByLastUpdatedDateEob(lastUpdated, results);
        }

        if patient is string {
            results = getByPatientEob(patient, results);
        }

        if identifier is string {
            results = getByIdentifierEob(identifier, results);
        }

        if created is string {
            results = check getByCreatedDateEob(created, results);
        }

        // reorder the results as decending order by Created date
        results = orderByCreatedDateEob(results);

        r4:BundleEntry[] bundleEntries = [];

        foreach ExplanationOfBenefit item in results {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        bundle.entry = bundleEntries;
        bundle.total = results.length();
    }

    return bundle;
}

isolated function getByProfileEob(string profile, ExplanationOfBenefit[] targetArr) returns ExplanationOfBenefit[] {
    ExplanationOfBenefit[] filteredEobs = [];
    foreach ExplanationOfBenefit eob in targetArr {
        r4:canonical[]? profiles = eob.meta.profile;
        if profiles is () {
            continue; // Skip if there are no profiles
        }
        foreach r4:canonical item in profiles {
            if item == profile {
                filteredEobs.push(eob);
                break; // Break the inner loop if a match is found
            }
        }
    }
    return filteredEobs;
}

isolated function getByLastUpdatedDateEob(string lastUpdated, ExplanationOfBenefit[] targetArr) returns ExplanationOfBenefit[]|r4:FHIRError {
    return getByDateEob(lastUpdated, targetArr, "lastUpdated");
}

isolated function getByPatientEob(string patient, ExplanationOfBenefit[] targetArr) returns ExplanationOfBenefit[] {
    ExplanationOfBenefit[] filteredEobs = [];
    foreach ExplanationOfBenefit eob in targetArr {
        if eob.patient.reference == string `Patient/${patient}` { 
            filteredEobs.push(eob);
        }
    }
    return filteredEobs;
}

isolated function getByIdentifierEob(string identifier, ExplanationOfBenefit[] targetArr) returns ExplanationOfBenefit[] {
    ExplanationOfBenefit[] filteredEobs = [];
    foreach ExplanationOfBenefit eob in targetArr {
        r4:Identifier[] identifiers = eob.identifier;
        foreach r4:Identifier item in identifiers {
            if item.system == identifier {
                filteredEobs.push(eob);
                break; // Break the inner loop if a match is found
            }
        }
    }
    return filteredEobs;
}

isolated function orderByCreatedDateEob(ExplanationOfBenefit[] targetArr) returns ExplanationOfBenefit[] {
    return from ExplanationOfBenefit item in targetArr
        order by item.created descending
        select item;
}

isolated function getByCreatedDateEob(string created, ExplanationOfBenefit[] targetArr) returns ExplanationOfBenefit[]|r4:FHIRError {
    return getByDateEob(created, targetArr, "created");
}

isolated function getByDateEob(string search_date_value, ExplanationOfBenefit[] targetArr, string search_date) returns ExplanationOfBenefit[]|r4:FHIRError {
    string operator = search_date_value.substring(0, 2);
    r4:dateTime datetimeR4 = search_date_value.substring(2);

    // convert r4:dateTime to time:Utc
    time:Utc|time:Error dateTimeUtc = time:utcFromString(datetimeR4.includes("T") ? datetimeR4 : datetimeR4 + "T00:00:00.000Z");
    if dateTimeUtc is time:Error {
        return r4:createFHIRError(string `Invalid date format: ${search_date_value}, ${dateTimeUtc.message()}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    time:Utc lowerBound = time:utcAddSeconds(dateTimeUtc, 86400);
    time:Utc upperBound = time:utcAddSeconds(dateTimeUtc, -86400);

    ExplanationOfBenefit[] filteredEobs = [];
    foreach ExplanationOfBenefit eob in targetArr {
        time:Utc|time:Error eobDateTimeUtc;

        if search_date is "created" {
            r4:dateTime eobDateTimeR4 = eob.created;
            eobDateTimeUtc = time:utcFromString(eobDateTimeR4.includes("T") ? eobDateTimeR4 : eobDateTimeR4 + "T00:00:00.000Z");
        } else if search_date is "lastUpdated" {
            if eob.meta.lastUpdated is () {
                continue; // Skip if there are no meta fields
            }
            eobDateTimeUtc = time:utcFromString(eob.meta.lastUpdated ?: "");
        } else {
            return r4:createFHIRError(string `Invalid date field: ${search_date}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        if eobDateTimeUtc is time:Error {
            continue; // Skip invalid date formats
        }
        match operator {
            "eq" => {
                if eobDateTimeUtc == dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "ne" => {
                if eobDateTimeUtc != dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "lt" => {
                if eobDateTimeUtc < dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "gt" => {
                if eobDateTimeUtc > dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "ge" => {
                if eobDateTimeUtc >= dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "le" => {
                if eobDateTimeUtc <= dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "sa" => {
                if eobDateTimeUtc > dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "eb" => {
                if eobDateTimeUtc < dateTimeUtc {
                    filteredEobs.push(eob.clone());
                }
            }
            "ap" => {
                // Approximation: Check if the eob date is within 1 day of the given date
                if eobDateTimeUtc >= lowerBound && eobDateTimeUtc <= upperBound {
                    filteredEobs.push(eob.clone());
                }
            }
            _ => {
                return r4:createFHIRError(string `Invalid operator: ${operator}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }
    return filteredEobs;
}

function loadEobData() returns error? {
    lock {
        json eocJson = {
            "resourceType": "ExplanationOfBenefit",
            "id": "14453",
            "meta": {
                "lastUpdated": "2024-12-12T09:14:11+00:00",
                "profile": ["http://hl7.org/fhir/us/carin-bb/StructureDefinition/C4BB-ExplanationOfBenefit-Outpatient-Institutional"]
            },
            "language": "en-US",
            "text": {
                "status": "generated",
                "div": string `<div xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US"><p class="res-header-id"><b>Generated Narrative: ExplanationOfBenefit EOBOutpatient1</b></p><a name="EOBOutpatient1"> </a><a name="hcEOBOutpatient1"> </a><a name="EOBOutpatient1-en-US"> </a><div style="display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%"><p style="margin-bottom: 0px">Last updated: 2024-12-12 09:14:11+0000; Language: en-US</p><p style="margin-bottom: 0px">Profile: <a href="StructureDefinition-C4BB-ExplanationOfBenefit-Outpatient-Institutional.html">C4BB ExplanationOfBenefit Outpatient Institutionalversion: null2.1.0)</a></p></div><p><b>identifier</b>: Unique Claim ID/AW123412341234123412341234123412</p><p><b>status</b>: Active</p><p><b>type</b>: <span title="Codes:{http://terminology.hl7.org/CodeSystem/claim-type institutional}">Institutional</span></p><p><b>subType</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBInstitutionalClaimSubType outpatient}">Outpatient</span></p><p><b>use</b>: Claim</p><p><b>patient</b>: <a href="Patient-Patient2.html">Member 01 Test  Male, DoB: 1943-01-01 ( An identifier for the insured of an insurance policy (this insured always has a subscriber), usually assigned by the insurance carrier.:\u00a088800933501)</a></p><p><b>billablePeriod</b>: 2024-01-01 --&gt; 2024-10-31</p><p><b>created</b>: 2024-11-02 00:00:00+0000</p><p><b>insurer</b>: <a href="Organization-Payer1.html">Organization Payer 1</a></p><p><b>provider</b>: <a href="Organization-ProviderOrganization1.html">Orange Medical Group</a></p><p><b>outcome</b>: Partial Processing</p><h3>CareTeams</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Sequence</b></td><td><b>Provider</b></td><td><b>Role</b></td><td><b>Qualification</b></td></tr><tr><td style="display: none">*</td><td>1</td><td><a href="Organization-ProviderOrganization1.html">Organization Orange Medical Group</a></td><td><span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBClaimCareTeamRole rendering}">Rendering provider</span></td><td><span title="Codes:{http://nucc.org/provider-taxonomy 364SX0200X}">Oncology Clinical Nurse Specialist</span></td></tr></table><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 2</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType clmrecvddate}">Claim Received Date</span></p><p><b>timing</b>: 2024-11-30</p></blockquote><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 3</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType typeofbill}">Type of Bill</span></p><p><b>code</b>: <span title="Codes:{https://www.nubc.org/CodeSystem/TypeOfBill Dummy}">Dummy</span></p></blockquote><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 4</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType pointoforigin}">Point Of Origin</span></p><p><b>code</b>: <span title="Codes:{https://www.nubc.org/CodeSystem/PointOfOrigin Dummy}">Dummy</span></p></blockquote><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 5</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType admtype}">Admission Type</span></p><p><b>code</b>: <span title="Codes:{https://www.nubc.org/CodeSystem/PriorityTypeOfAdmitOrVisit Dummy}">Dummy</span></p></blockquote><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 6</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType discharge-status}">Discharge Status</span></p><p><b>code</b>: <span title="Codes:{https://www.nubc.org/CodeSystem/PatDischargeStatus Dummy}">Dummy</span></p></blockquote><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 7</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType medicalrecordnumber}">Medical Record Number</span></p><p><b>value</b>: 1234-234-1243-12345678901m</p></blockquote><blockquote><p><b>supportingInfo</b></p><p><b>sequence</b>: 8</p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType patientaccountnumber}">Patient Account Number</span></p><p><b>value</b>: 1234-234-1243-12345678901a</p></blockquote><h3>Diagnoses</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Sequence</b></td><td><b>Diagnosis[x]</b></td><td><b>Type</b></td></tr><tr><td style="display: none">*</td><td>1</td><td><span title="Codes:{http://hl7.org/fhir/sid/icd-10-cm S06.0X1A}">Concussion w LOC of 30 minutes or less, init</span></td><td><span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBClaimDiagnosisType patientreasonforvisit}">Patient Reason for Visit</span></td></tr></table><h3>Insurances</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Focal</b></td><td><b>Coverage</b></td></tr><tr><td style="display: none">*</td><td>true</td><td><a href="Coverage-Coverage3.html">Coverage: identifier = Member Number; status = active; type = health insurance plan policy; subscriberId = 12345678901; dependent = 01; relationship = Self; period = 2024-01-01 --&gt; 2024-10-31; network = XYZ123-UPMC CONSUMER ADVA</a></td></tr></table><h3>Items</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Sequence</b></td><td><b>Revenue</b></td><td><b>ProductOrService</b></td><td><b>Serviced[x]</b></td></tr><tr><td style="display: none">*</td><td>1</td><td><span title="Codes:{https://www.nubc.org/CodeSystem/RevenueCodes Dummy}">Dummy</span></td><td><span title="Codes:{http://terminology.hl7.org/CodeSystem/data-absent-reason not-applicable}">Not Applicable</span></td><td>2024-11-02</td></tr></table><blockquote><p><b>adjudication</b></p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudicationDiscriminator benefitpaymentstatus}">Benefit Payment Status</span></p><p><b>reason</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBPayerAdjudicationStatus innetwork}">In Network</span></p></blockquote><blockquote><p><b>adjudication</b></p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudicationDiscriminator billingnetworkstatus}">Billing Network Status</span></p><p><b>reason</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBPayerAdjudicationStatus innetwork}">In Network</span></p></blockquote><blockquote><p><b>adjudication</b></p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication paidtoprovider}">Payment Amount</span></p><h3>Amounts</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Value</b></td><td><b>Currency</b></td></tr><tr><td style="display: none">*</td><td>620</td><td>United States dollar</td></tr></table></blockquote><blockquote><p><b>adjudication</b></p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication paidbypatient}">Patient Pay Amount</span></p><h3>Amounts</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Value</b></td></tr><tr><td style="display: none">*</td><td>0</td></tr></table></blockquote><blockquote><p><b>total</b></p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication paidtoprovider}">Payment Amount</span></p><h3>Amounts</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Value</b></td><td><b>Currency</b></td></tr><tr><td style="display: none">*</td><td>620</td><td>United States dollar</td></tr></table></blockquote><blockquote><p><b>total</b></p><p><b>category</b>: <span title="Codes:{http://terminology.hl7.org/CodeSystem/adjudication submitted}">Submitted Amount</span></p><h3>Amounts</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Value</b></td><td><b>Currency</b></td></tr><tr><td style="display: none">*</td><td>2650</td><td>United States dollar</td></tr></table></blockquote><blockquote><p><b>total</b></p><p><b>category</b>: <span title="Codes:{http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication paidbypatient}">Patient Pay Amount</span></p><h3>Amounts</h3><table class="grid"><tr><td style="display: none">-</td><td><b>Value</b></td><td><b>Currency</b></td></tr><tr><td style="display: none">*</td><td>0</td><td>United States dollar</td></tr></table></blockquote></div>`
            },
            "identifier": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType",
                                "code": "uc"
                            }
                        ]
                    },
                    "system": "https://www.xxxplan.com/fhir/EOBIdentifier",
                    "value": "AW123412341234123412341234123412"
                }
            ],
            "status": "active",
            "type": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/claim-type",
                        "code": "institutional"
                    }
                ],
                "text": "Institutional"
            },
            "subType": {
                "coding": [
                    {
                        "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBInstitutionalClaimSubType",
                        "code": "outpatient"
                    }
                ],
                "text": "Outpatient"
            },
            "use": "claim",
            "patient": {
                "reference": "Patient/102"
            },
            "billablePeriod": {
                "start": "2024-01-01",
                "end": "2024-10-31"
            },
            "created": "2024-11-02T00:00:00+00:00",
            "insurer": {
                "reference": "Organization/50",
                "display": "UnitedCare Health Insurance"
            },
            "provider": {
                "reference": "Organization/64",
                "display": "Grace Hospital"
            },
            "outcome": "partial",
            "careTeam": [
                {
                    "sequence": 1,
                    "provider": {
                        "reference": "Organization/64"
                    },
                    "role": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBClaimCareTeamRole",
                                "code": "rendering",
                                "display": "Rendering provider"
                            }
                        ]
                    },
                    "qualification": {
                        "coding": [
                            {
                                "system": "http://nucc.org/provider-taxonomy",
                                "code": "364SX0200X",
                                "display": "Oncology Clinical Nurse Specialist"
                            }
                        ]
                    }
                }
            ],
            "supportingInfo": [
                {
                    "sequence": 2,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "clmrecvddate"
                            }
                        ]
                    },
                    "timingDate": "2024-11-30"
                },
                {
                    "sequence": 3,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "typeofbill"
                            }
                        ]
                    },
                    "code": {
                        "coding": [
                            {
                                "system": "https://www.nubc.org/CodeSystem/TypeOfBill",
                                "code": "Dummy"
                            }
                        ]
                    }
                },
                {
                    "sequence": 4,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "pointoforigin"
                            }
                        ]
                    },
                    "code": {
                        "coding": [
                            {
                                "system": "https://www.nubc.org/CodeSystem/PointOfOrigin",
                                "code": "Dummy"
                            }
                        ]
                    }
                },
                {
                    "sequence": 5,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "admtype"
                            }
                        ]
                    },
                    "code": {
                        "coding": [
                            {
                                "system": "https://www.nubc.org/CodeSystem/PriorityTypeOfAdmitOrVisit",
                                "code": "Dummy"
                            }
                        ]
                    }
                },
                {
                    "sequence": 6,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "discharge-status"
                            }
                        ]
                    },
                    "code": {
                        "coding": [
                            {
                                "system": "https://www.nubc.org/CodeSystem/PatDischargeStatus",
                                "code": "Dummy"
                            }
                        ]
                    }
                },
                {
                    "sequence": 7,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "medicalrecordnumber"
                            }
                        ]
                    },
                    "valueString": "1234-234-1243-12345678901m"
                },
                {
                    "sequence": 8,
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBSupportingInfoType",
                                "code": "patientaccountnumber"
                            }
                        ]
                    },
                    "valueString": "1234-234-1243-12345678901a"
                }
            ],
            "diagnosis": [
                {
                    "sequence": 1,
                    "diagnosisCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/sid/icd-10-cm",
                                "code": "S06.0X1A",
                                "display": "Concussion with loss of consciousness of 30 minutes or less, initial encounter."
                            }
                        ]
                    },
                    "type": [
                        {
                            "coding": [
                                {
                                    "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBClaimDiagnosisType",
                                    "code": "patientreasonforvisit"
                                }
                            ]
                        }
                    ]
                }
            ],
            "insurance": [
                {
                    "focal": true,
                    "coverage": {
                        "reference": "Coverage/367"
                    }
                }
            ],
            "item": [
                {
                    "sequence": 1,
                    "revenue": {
                        "coding": [
                            {
                                "system": "https://www.nubc.org/CodeSystem/RevenueCodes",
                                "code": "Dummy"
                            }
                        ]
                    },
                    "productOrService": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/data-absent-reason",
                                "code": "not-applicable",
                                "display": "Not Applicable"
                            }
                        ]
                    },
                    "servicedDate": "2024-11-02"
                }
            ],
            "adjudication": [
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudicationDiscriminator",
                                "code": "benefitpaymentstatus"
                            }
                        ]
                    },
                    "reason": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBPayerAdjudicationStatus",
                                "code": "innetwork"
                            }
                        ]
                    }
                },
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudicationDiscriminator",
                                "code": "billingnetworkstatus"
                            }
                        ]
                    },
                    "reason": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBPayerAdjudicationStatus",
                                "code": "innetwork"
                            }
                        ]
                    }
                },
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication",
                                "code": "paidtoprovider"
                            }
                        ],
                        "text": "Payment Amount"
                    },
                    "amount": {
                        "value": 620,
                        "currency": "USD"
                    }
                },
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication",
                                "code": "paidbypatient"
                            }
                        ],
                        "text": "Patient Pay Amount"
                    },
                    "amount": {
                        "value": 0
                    }
                }
            ],
            "total": [
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication",
                                "code": "paidtoprovider"
                            }
                        ],
                        "text": "Payment Amount"
                    },
                    "amount": {
                        "value": 620,
                        "currency": "USD"
                    }
                },
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/adjudication",
                                "code": "submitted"
                            }
                        ],
                        "text": "Submitted Amount"
                    },
                    "amount": {
                        "value": 2650,
                        "currency": "USD"
                    }
                },
                {
                    "category": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBAdjudication",
                                "code": "paidbypatient"
                            }
                        ],
                        "text": "Patient Pay Amount"
                    },
                    "amount": {
                        "value": 0,
                        "currency": "USD"
                    }
                }
            ]
        };

        ExplanationOfBenefit eob = check parser:parse(eocJson).ensureType();
        eobs.push(eob.clone());
    }
}
