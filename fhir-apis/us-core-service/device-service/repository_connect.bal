import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreImplantableDeviceProfile[] devices = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreImplantableDeviceProfile {
    uscore700:USCoreImplantableDeviceProfile|error device = parser:parse(payload, uscore700:USCoreImplantableDeviceProfile).ensureType();

    if device is error {
        return r4:createFHIRError(device.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            device.id = (createOperationNextId).toBalString();
        }

        lock {
            devices.push(device.clone());
        }

        return device;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreImplantableDeviceProfile {
    lock {
        foreach var item in devices {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a device resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreImplantableDeviceProfile byId = check getById(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    lock {
        r4:BundleEntry[] bundleEntries = [];
        foreach var item in devices {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        r4:Bundle cloneBundle = bundle.clone();
        cloneBundle.entry = bundleEntries;
        return cloneBundle.clone();
    }
}

function init() returns error? {
    lock {
        json deviceJson = {
            "resourceType": "Device",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Device</b><a name=\"udi-1\"> </a><a name=\"hcudi-1\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Device &quot;udi-1&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-implantable-device.html\">US Core Implantable Device Profile (version 7.0.0)</a></p></div><h3>UdiCarriers</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>DeviceIdentifier</b></td><td><b>CarrierHRF</b></td></tr><tr><td style=\"display: none\">*</td><td>09504000059118</td><td>(01)09504000059118(17)141120(10)7654321D(21)10987654d321</td></tr></table><p><b>status</b>: active</p><p><b>expirationDate</b>: 2014-11-20</p><p><b>lotNumber</b>: 7654321D</p><p><b>serialNumber</b>: 10987654d321</p><p><b>type</b>: Coated femoral stem prosthesis, modular <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#468063009)</span></p><p><b>patient</b>: <a href=\"Patient-example.html\">Patient/example: Amy Shaw</a> &quot; SHAW&quot;</p></div>"
            },
            "udiCarrier": [
                {
                    "deviceIdentifier": "09504000059118",
                    "carrierHRF": "(01)09504000059118(17)141120(10)7654321D(21)10987654d321"
                }
            ],
            "status": "active",
            "expirationDate": "2014-11-20",
            "lotNumber": "7654321D",
            "serialNumber": "10987654d321",
            "type": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "version": "http://snomed.info/sct/731000124108",
                        "code": "468063009",
                        "display": "Coated femoral stem prosthesis, modular"
                    }
                ]
            },
            "patient": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            }
        };
        uscore700:USCoreImplantableDeviceProfile device = check parser:parse(deviceJson, uscore700:USCoreImplantableDeviceProfile).ensureType();
        devices.push(device.clone());
    }
}
