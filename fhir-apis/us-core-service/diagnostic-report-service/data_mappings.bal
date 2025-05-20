import ballerinax/health.fhir.r4.international401;

isolated function mapLabReportToDiagnosticReport(LabReport labReport) returns international401:DiagnosticReport => {
    extension: [],
    code: {
        coding: [
            {
                system: "http://loinc.org",
                code: "11502-2",
                display: "Laboratory report"
            }
        ]
    },
    subject: {
        reference: string `Patient/${labReport.patient_id}`,
        display: labReport.patient_name
    },
    status: labReport.report_status != () ? <international401:DiagnosticReportStatus>labReport.report_status : "preliminary",
    basedOn: [
        {
            display: labReport.insurance_name
        }
    ],
    performer: from var authorsItem in labReport.authors ?: []
        select {
            display: authorsItem.name,
            reference: authorsItem.org

        },
    effectivePeriod: {
        'start: labReport.report_date
    },
    identifier: [
        {
            id: labReport.document_id
        }
    ],
    id: labReport.id.toString()
};

isolated function mapSubjectToPatient(Subject subject) returns international401:Patient => {

    name: [
        {
            text: subject.name
        }
    ],
    birthDate: subject.birth_date != () ? <string>subject.birth_date : "",
    id: subject.patient_id.toString(),
    identifier: [
        {
            value: subject.patient_id

        }
    ],
    address: [
        {
            text: subject.address
        }
    ],
    telecom: [
        {
            value: subject.phone,
            use: "mobile"
        }
    ]
};
