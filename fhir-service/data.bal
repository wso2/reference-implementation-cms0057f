public json[] patientJsons = [
    {
        "resourceType": "Patient",
        "id": "101",
        "meta": {
            "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]
        },
        "identifier": [
            {
                "system": "http://hospital.org/patients",
                "value": "12345"
            },
            {
                "system": "urn:oid:wso2.healthcare.payer.memberID",
                "value": "588675dc-e80e-4528-a78f-af10f9755f23",
                "use": "secondary"
            }
        ],
        "name": [
            {
                "use": "official",
                "family": "Smith",
                "given": ["John"]
            }
        ],
        "gender": "male",
        "birthDate": "1979-04-15",
        "address": [
            {
                "line": ["123 Main St"],
                "city": "Anytown",
                "state": "CA",
                "postalCode": "90210",
                "country": "US"
            }
        ],
        "telecom": [
            {
                "system": "phone",
                "value": "+1 555-555-5555",
                "use": "mobile"
            },
            {
                "system": "email",
                "value": "john@example.com"
            }
        ]
    },
    {
        "resourceType": "Patient",
        "id": "102",
        "meta": {
            "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]
        },
        "identifier": [
            {
                "system": "http://hospital.org/patients",
                "value": "54321"
            },
            {
                "system": "urn:oid:wso2.healthcare.payer.memberID",
                "value": "644d85af-aaf9-4068-ad23-1e55aedd5205",
                "use": "secondary"
            }
        ],
        "name": [
            {
                "use": "official",
                "family": "Shaw",
                "given": ["Jax"]
            }
        ],
        "gender": "female",
        "birthDate": "1985-08-22",
        "address": [
            {
                "line": ["456 Elm Street"],
                "city": "Oaktown",
                "state": "NY",
                "postalCode": "10001",
                "country": "US"
            }
        ],
        "telecom": [
            {
                "system": "phone",
                "value": "+1 555-123-4567",
                "use": "mobile"
            },
            {
                "system": "email",
                "value": "jax.shaw@example.com"
            }
        ]
    }
];

public json[] allergyIntoleranceJsons = [
    {
        "resourceType": "AllergyIntolerance",
        "id": "20300",
        "meta": {
            "profile": [
                "http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance"
            ]
        },
        "clinicalStatus": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                    "code": "active",
                    "display": "Active"
                }
            ]
        },
        "verificationStatus": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                    "code": "confirmed",
                    "display": "Confirmed"
                }
            ]
        },
        "type": "allergy",
        "category": ["medication"],
        "criticality": "high",
        "code": {
            "coding": [
                {
                    "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                    "code": "7980",
                    "display": "Penicillin"
                }
            ],
            "text": "Penicillin"
        },
        "patient": {
            "reference": "Patient/101"
        },
        "onsetDateTime": "2012-06-10",
        "recordedDate": "2012-06-15",
        "recorder": {
            "reference": "Practitioner/practitioner-456"
        },
        "reaction": [
            {
                "manifestation": [
                    {
                        "coding": [
                            {
                                "system": "http://snomed.info/sct",
                                "code": "271807003",
                                "display": "Rash"
                            }
                        ],
                        "text": "Skin rash"
                    }
                ],
                "severity": "moderate",
                "description": "Developed itchy rash after taking penicillin"
            }
        ]
    },
    {
        "resourceType": "AllergyIntolerance",
        "id": "allergy-peanut",
        "meta": {
            "profile": [
                "http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance"
            ]
        },
        "clinicalStatus": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                    "code": "active",
                    "display": "Active"
                }
            ]
        },
        "verificationStatus": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                    "code": "confirmed",
                    "display": "Confirmed"
                }
            ]
        },
        "type": "allergy",
        "category": ["food"],
        "criticality": "high",
        "code": {
            "coding": [
                {
                    "system": "http://snomed.info/sct",
                    "code": "91935009",
                    "display": "Allergy to peanuts"
                }
            ],
            "text": "Peanut Allergy"
        },
        "patient": {
            "reference": "Patient/101"
        },
        "onsetDateTime": "2008-09-20",
        "recordedDate": "2008-09-25",
        "recorder": {
            "reference": "Practitioner/practitioner-456"
        },
        "reaction": [
            {
                "manifestation": [
                    {
                        "coding": [
                            {
                                "system": "http://snomed.info/sct",
                                "code": "39579001",
                                "display": "Anaphylaxis"
                            }
                        ],
                        "text": "Severe allergic reaction (anaphylaxis)"
                    }
                ],
                "severity": "severe",
                "description": "Swelling and difficulty breathing after eating peanut-containing food"
            }
        ]
    },
    {
        "resourceType": "AllergyIntolerance",
        "id": "allergy-pollen",
        "meta": {
            "profile": [
                "http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance"
            ]
        },
        "clinicalStatus": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                    "code": "active",
                    "display": "Active"
                }
            ]
        },
        "verificationStatus": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                    "code": "confirmed",
                    "display": "Confirmed"
                }
            ]
        },
        "type": "allergy",
        "category": ["environment"],
        "criticality": "low",
        "code": {
            "coding": [
                {
                    "system": "http://snomed.info/sct",
                    "code": "418689008",
                    "display": "Allergy to pollen"
                }
            ],
            "text": "Pollen Allergy"
        },
        "patient": {
            "reference": "Patient/102"
        },
        "onsetDateTime": "2015-04-01",
        "recordedDate": "2015-04-05",
        "recorder": {
            "reference": "Practitioner/practitioner-456"
        },
        "reaction": [
            {
                "manifestation": [
                    {
                        "coding": [
                            {
                                "system": "http://snomed.info/sct",
                                "code": "78352004",
                                "display": "Sneezing"
                            }
                        ],
                        "text": "Sneezing and runny nose"
                    }
                ],
                "severity": "mild",
                "description": "Seasonal sneezing and nasal congestion"
            }
        ]
    }
];

public json[] claimJsons = [];
public json[] claimResponseJsons = [];
public json[] coverageJsons = [];
public json[] diagnosticReportJsons = [];
public json[] encounterJsons = [];
public json[] eobJsons = [];
public json[] medicationRequestJsons = [];
public json[] observationJsons = [];
public json[] organizationJsons = [];
public json[] practitionerJsons = [];
public json[] questionnaireJsons = [];
// public json[] questionnairePackages = [];
public json[] questionnaireResponseJsons = [];
