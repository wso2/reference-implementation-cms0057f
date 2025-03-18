var errorCode = 'access_denied';
var errorMessage = 'Audience validation failed';

var onLoginRequest = function(context) {
    var aud = context.request.params.aud[0];
    if (isValidAud(aud)) {
        executeStep(1);
    } else {
        sendError(context.request.params.redirect_uri[0], {
            'errorCode': errorCode,
            'errorMessage': errorMessage
        });
    }

};

function isValidAud(aud) {
    return aud == "https://inferno.healthit.gov/reference-server/r4";
}
