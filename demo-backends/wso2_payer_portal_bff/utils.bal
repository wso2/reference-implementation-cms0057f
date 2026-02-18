import ballerina/time;
import ballerina/lang.regexp;

function AddDurationToDate(string date, string durationDays) returns string|error {
    // Parse the duration days
    int days = check int:fromString(durationDays);
    
    // Parse the input date string to extract date components
    // Handle formats: YYYY, YYYY-MM, YYYY-MM-DD, or YYYY-MM-DDThh:mm:ss+zz:zz
    string dateOnly;
    boolean hasTime = date.includes("T");
    
    if hasTime {
        // Extract date part before 'T'
        regexp:RegExp tPattern = re `T`;
        string[] parts = tPattern.split(date);
        dateOnly = parts[0];
    } else {
        dateOnly = date;
    }
    
    // Parse date components
    regexp:RegExp dashPattern = re `-`;
    string[] dateParts = dashPattern.split(dateOnly);
    int year = check int:fromString(dateParts[0]);
    int month = dateParts.length() > 1 ? check int:fromString(dateParts[1]) : 1;
    int day = dateParts.length() > 2 ? check int:fromString(dateParts[2]) : 1;
    
    // Create Civil date with UTC offset
    time:Civil baseDate = {
        year: year, 
        month: month, 
        day: day, 
        hour: 0, 
        minute: 0,
        utcOffset: {hours: 0, minutes: 0}
    };
    
    // Add the duration
    time:Duration duration = {days: days};
    time:Civil futureDate = check time:civilAddDuration(baseDate, duration);
    
    // Format the result based on input format
    string formattedDate;
    if dateParts.length() == 1 {
        // YYYY format
        formattedDate = string `${futureDate.year}`;
    } else if dateParts.length() == 2 {
        // YYYY-MM format
        formattedDate = string `${futureDate.year}-${futureDate.month < 10 ? "0" : ""}${futureDate.month}`;
    } else {
        // YYYY-MM-DD format (with or without time)
        formattedDate = string `${futureDate.year}-${futureDate.month < 10 ? "0" : ""}${futureDate.month}-${futureDate.day < 10 ? "0" : ""}${futureDate.day}`;
        
        // If original had time component, append it
        if hasTime {
            regexp:RegExp tPattern2 = re `T`;
            string[] timeParts = tPattern2.split(date);
            formattedDate = formattedDate + "T" + timeParts[1];
        }
    }
    
    return formattedDate;
}
