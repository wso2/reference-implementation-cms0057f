function init() returns error? {
    check loadClaimData();
    check loadCoverageData();
    check loadDiagnosticReportData();
    check loadEncounterData();
    check loadPatientData();
}
