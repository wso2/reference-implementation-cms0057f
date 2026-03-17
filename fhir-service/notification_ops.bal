// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerinax/health.clients.fhir as fhirClient;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import xlibb/pipeline;

configurable string kafkaServer = ?;
configurable string notificationFailureTopic = "pas-notification-failure-store";
configurable string notificationDeadLetterTopic = "pas-notification-dead-letter-store";
configurable string notificationReplayTopic = "pas-notification-replay-store";
configurable string notificationStoreConsumerGroup = "pas-notification-store";
configurable int notificationReplayMaxRetries = 3;
configurable decimal notificationReplayRetryInterval = 2;
configurable boolean notificationReplayEnabled = false;

type NotificationDispatch record {|
    international401:Subscription subscription;
    string claimResponseId;
    international401:ClaimResponse claimResponse;
|};

type PreparedNotification record {|
    string endpoint;
    map<string|string[]> headers;
    NotificationBundle bundle;
|};
 
isolated function sendNotificationDirect(
    international401:Subscription subscription,
    string claimResponseId,
    international401:ClaimResponse claimResponse
) returns error? {
    string endpoint = subscription.channel.endpoint ?: "";
    if endpoint == "" {
        return error("Subscription endpoint is empty");
    }

    NotificationBundle bundle = check buildNotificationBundle(
        subscription,
        claimResponseId,
        claimResponse
    );

    map<string|string[]> headers = {
        "Content-Type": "application/fhir+json"
    };

    string? authHeader = extractAuthHeader(subscription);
    if authHeader is string {
        headers["Authorization"] = authHeader;
    }

    http:Client httpClient = check new (endpoint, {
        timeout: 30,
        retryConfig: {
            count: 3,
            interval: 2
        }
    });

    http:Response|error response = httpClient->post("/", bundle, headers);
    if response is http:Response {
        if response.statusCode >= 200 && response.statusCode < 300 {
            log:printInfo(string `Notification sent successfully to ${endpoint}`);
            return;
        }
        return error(string `HTTP ${response.statusCode}`);
    }

    return error(string `HTTP error: ${response.message()}`);
}

final pipeline:HandlerChain? notificationPipeline = (notificationReplayEnabled)
    ? (checkpanic new (
        name = "pasNotificationPipeline",
        processors = prepareNotification,
        destinations = deliverNotification,
        failureStore = checkpanic new KafkaMessageStore(
            kafkaServer,
            notificationFailureTopic,
            string `${notificationStoreConsumerGroup}-${notificationFailureTopic}`
        ),
        replayListenerConfig = {
            pollingInterval: 5,
            maxRetries: notificationReplayMaxRetries,
            retryInterval: notificationReplayRetryInterval,
            deadLetterStore: checkpanic new KafkaMessageStore(
                kafkaServer,
                notificationDeadLetterTopic,
                string `${notificationStoreConsumerGroup}-${notificationDeadLetterTopic}`
            ),
            replayStore: checkpanic new KafkaMessageStore(
                kafkaServer,
                notificationReplayTopic,
                string `${notificationStoreConsumerGroup}-${notificationReplayTopic}`
            )
        }
    ))
    : ();

@pipeline:TransformerConfig {id: "prepare_notification"}
isolated function prepareNotification(pipeline:MessageContext msgCtx) returns PreparedNotification|error {
    NotificationDispatch dispatch = check msgCtx.getContentWithType(NotificationDispatch);

    // Get endpoint from channel
    string endpoint = dispatch.subscription.channel.endpoint ?: "";
    if endpoint == "" {
        return error("Subscription endpoint is empty");
    }

    // Build notification bundle
    NotificationBundle bundle = check buildNotificationBundle(
        dispatch.subscription,
        dispatch.claimResponseId,
        dispatch.claimResponse
    );

    map<string|string[]> headers = {
        "Content-Type": "application/fhir+json"
    };

    // Extract auth header from channel headers
    string? authHeader = extractAuthHeader(dispatch.subscription);
    if authHeader is string {
        headers["Authorization"] = authHeader;
    }

    return {
        endpoint,
        headers,
        bundle
    };
}

@pipeline:DestinationConfig {
    id: "deliver_notification",
    retryConfig: {
        maxRetries: 3,
        retryInterval: 2
    }
}
isolated function deliverNotification(pipeline:MessageContext msgCtx) returns anydata|error {
    PreparedNotification prepared = check msgCtx.getContentWithType(PreparedNotification);

    http:Client httpClient = check new (prepared.endpoint, {
        timeout: 30
    });

    http:Response|error response = httpClient->post("/", prepared.bundle, prepared.headers);
    if response is http:Response {
        if response.statusCode >= 200 && response.statusCode < 300 {
            log:printInfo(string `Notification sent successfully to ${prepared.endpoint}`);
            return ();
        }
        return error(string `HTTP ${response.statusCode}`);
    }

    return error(string `HTTP error: ${response.message()}`);
}

# Send notification for ClaimResponse update
#
# + fhirConnector - FHIR Connector instance
# + claimResponseId - ClaimResponse ID
# + organizationId - Organization ID
# + claimResponse - Updated ClaimResponse
# + return - Error if sending fails
public isolated function sendNotifications(
        fhirClient:FHIRConnector fhirConnector,
        string claimResponseId,
        string organizationId,
        international401:ClaimResponse claimResponse
) returns error? {

    log:printInfo(string `Sending notifications for ClaimResponse ${claimResponseId}`);

    // Get active subscriptions
    international401:Subscription[] subscriptions =
        check getActiveSubscriptionsByOrg(fhirConnector, organizationId);

    if subscriptions.length() == 0 {
        log:printWarn(string `No active subscriptions for org ${organizationId}`);
        return;
    }

    // Send notification to each subscription
    foreach international401:Subscription sub in subscriptions {
        pipeline:HandlerChain? maybePipeline = notificationPipeline;
        if maybePipeline is pipeline:HandlerChain {
            pipeline:HandlerChain hc = maybePipeline;
            NotificationDispatch dispatch = {
                subscription: sub,
                claimResponseId,
                claimResponse
            };

            pipeline:ExecutionSuccess|pipeline:ExecutionError execResult = hc.execute(dispatch);
            if execResult is pipeline:ExecutionError {
                log:printError(
                    string `Failed to send notification to ${sub.id ?: "unknown"} (stored for replay)`,
                    'error = execResult
                );
            }
        } else {
            error? result = sendNotificationDirect(sub, claimResponseId, claimResponse);
            if result is error {
                log:printError(string `Failed to send notification to ${sub.id ?: "unknown"}: ${result.message()}`);
            }
        }
    }
}

# Send handshake notification to subscription endpoint
#
# + subscriptionId - Subscription ID
# + subscription - PASSubscription resource
# + return - True if successful
public isolated function sendHandshakeNotification(
        string subscriptionId,
        international401:Subscription subscription
) returns boolean|error {

    string endpoint = subscription.channel.endpoint ?: "";
    if endpoint == "" {
        return error("Subscription endpoint is empty");
    }

    log:printInfo(string `Sending handshake to ${endpoint}`);

    // Build handshake bundle
    json bundle = {
        "resourceType": "Bundle",
        "type": "history",
        "timestamp": time:utcToString(time:utcNow()),
        "entry": [
            {
                "fullUrl": string `urn:uuid:${uuid:createType1AsString()}`,
                "resource": {
                    "resourceType": "Parameters",
                    "parameter": [
                        {
                            "name": "subscription",
                            "valueReference": {
                                "reference": string `Subscription/${subscriptionId}`
                            }
                        },
                        {
                            "name": "type",
                            "valueCode": "handshake"
                        },
                        {
                            "name": "status",
                            "valueCode": "requested"
                        }
                    ]
                }
            }
        ]
    };

    // Send HTTP POST
    http:Client httpClient = check new (endpoint, {
        timeout: 10
    });

    map<string|string[]> headers = {
        "Content-Type": "application/fhir+json"
    };

    // Extract auth header from channel headers
    string? authHeader = extractAuthHeader(subscription);
    if authHeader is string {
        headers["Authorization"] = authHeader;
    }

    http:Response|error response = httpClient->post("/", bundle, headers);

    if response is http:Response {
        if response.statusCode >= 200 && response.statusCode < 300 {
            log:printInfo(string `Handshake successful for ${subscriptionId}`);
            return true;
        }
    }

    log:printError(string `Handshake failed for ${subscriptionId}`);
    return false;
}

# Build notification bundle
#
# + subscription - PASSubscription resource
# + claimResponseId - ClaimResponse ID
# + claimResponse - ClaimResponse resource
# + return - Notification bundle
isolated function buildNotificationBundle(
        international401:Subscription subscription,
        string claimResponseId,
        international401:ClaimResponse claimResponse
) returns NotificationBundle|error {

    string subscriptionId = subscription.id ?: "";
    string bundleId = string `notification-${time:utcNow()[0]}`;
    string statusId = string `status-${time:utcNow()[0]}`;

    // Build SubscriptionStatus as Parameters (R4)
    SubscriptionStatusParameters statusParams = {
        resourceType: "Parameters",
        id: statusId,
        'parameter: [
            {
                name: "subscription",
                valueReference: {
                    reference: string `Subscription/${subscriptionId}`
                }
            },
            {
                name: "topic",
                valueCanonical: "http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic"
            },
            {
                name: "status",
                valueCode: subscription.status
            },
            {
                name: "type",
                valueCode: "event-notification"
            },
            {
                name: "notification-event",
                part: [
                    {
                        name: "event-number",
                        valueString: "1"
                    },
                    {
                        name: "timestamp",
                        valueInstant: time:utcToString(time:utcNow())
                    },
                    {
                        name: "focus",
                        valueReference: {
                            reference: string `ClaimResponse/${claimResponseId}`
                        }
                    }
                ]
            }
        ]
    };

    NotificationBundleEntry[] entries = [
        {
            fullUrl: string `urn:uuid:${statusId}`,
            'resource: statusParams.toJson(),
            request: {
                method: "GET",
                url: string `Subscription/${subscriptionId}/$status`
            },
            response: {
                status: "200"
            }
        }
    ];

    // Add ClaimResponse if full-resource payload
    string payloadType = extractPayloadType(subscription);
    if payloadType == "full-resource" {
        r4:BundleEntry bundleEntryResponse = {
            'resource: claimResponse,
            fullUrl: string `urn:uuid:${claimResponseId}`
        };

        r4:Bundle responseBundle = {
            'type: r4:BUNDLE_TYPE_COLLECTION,
            entry: [bundleEntryResponse]
        };

        entries.push({
            fullUrl: string `urn:uuid:${uuid:createType1AsString()}`,
            'resource: responseBundle.toJson(),
            request: {
                method: "PUT",
                url: string `Bundle/${claimResponseId}`
            },
            response: {
                status: "200"
            }
        });
    }

    NotificationBundle bundle = {
        resourceType: "Bundle",
        id: bundleId,
        'type: "history",
        timestamp: time:utcToString(time:utcNow()),
        entry: entries
    };

    return bundle;
}
