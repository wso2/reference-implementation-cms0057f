public type CustomPatient record {
    string patientType;
    string patientId;
    string version;
    string lastUpdatedOn;
    string originSource;
    Description description;
    Identifier[] identifiers;
    string firstName;
    string lastName;
    string gender;
    LocatoionDetail[] locatoionDetail;

};

public type Identifier record {
    IdType id_type;
    string id_value;
};

public type IdType record {
    Code[] codes;
};

public type Code record {
    string system_source;
    string identifier_code;
};

public type Description record {
    string status;
    string details?;
};

public type LocatoionDetail record {
    string nation?;
    string town?;
    string region?;
    string zipCode?;
    string identifier?;
    string province?;
};

public type ResponseResource record {
    string resourceId;
    string version;
};
