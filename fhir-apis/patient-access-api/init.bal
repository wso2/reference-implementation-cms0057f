function init() returns error? {
    check loadPatientData();
    check loadCoverageData();
    check loadEobData();
    check loadMedicationRequestData();
    check loadOrganizationData();
}
