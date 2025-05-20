import ballerinax/mysql.driver as _;

public isolated function getLabReportsByPatientId(string patientId) returns LabReport[]|error {
    LabReport[] labReports = [];
    stream<LabReportDAO, error?> resultStream = dbClient->query(
        sqlQuery = `SELECT * FROM LabReport WHERE patient_id=${patientId}`,
        rowType = LabReportDAO
    );
    check from LabReportDAO report in resultStream
        do {
            LabReport labReport = check report.cloneWithType();
            labReports.push(labReport);
        };
    return labReports;
}

public isolated function getAllLabReports() returns LabReport[]|error {
    LabReport[] labReports = [];
    stream<LabReport, error?> resultStream = dbClient->query(
        sqlQuery = `SELECT * FROM LabReport`,
        rowType = LabReport
    );
    check from LabReport report in resultStream
        do {
            labReports.push(report);
        };
    return labReports;
}

