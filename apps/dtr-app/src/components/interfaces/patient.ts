export interface Patient {
    id: string;
    name: { given: string[]; family: string }[];
    gender: string;
    birthDate: string;
    address: {
        country: string;
        city: string;
        line: string[];
        postalCode: string;
        state: string;
    }[];
    telecom: { system: string; value: string; use?: string }[];
    identifier: { system: string; value: string }[];
}
