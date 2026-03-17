// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/messaging;
import ballerina/uuid;
import ballerinax/kafka;

type StoredEnvelope record {|
    string id;
    anydata payload;
|};

public isolated client class KafkaMessageStore {
    *messaging:Store;

    private final kafka:Producer producer;
    private final kafka:Consumer consumer;
    private final string topic;

    public isolated function init(
        string|string[] bootstrapServers,
        string topic,
        string groupId,
        kafka:ProducerConfiguration producerConfig = {},
        kafka:ConsumerConfiguration consumerConfig = {}
    ) returns error? {
        self.topic = topic;

        kafka:ProducerConfiguration effectiveProducerConfig = producerConfig.clone();
        if effectiveProducerConfig.clientId is () {
            effectiveProducerConfig.clientId = string `kafka-store-producer-${topic}`;
        }
        self.producer = check new (bootstrapServers, effectiveProducerConfig);

        kafka:ConsumerConfiguration effectiveConsumerConfig = consumerConfig.clone();
        effectiveConsumerConfig.groupId = groupId;
        effectiveConsumerConfig.topics = [topic];
        if effectiveConsumerConfig.offsetReset is () {
            effectiveConsumerConfig.offsetReset = kafka:OFFSET_RESET_EARLIEST;
        }
        effectiveConsumerConfig.autoCommit = false;
        self.consumer = check new (bootstrapServers, effectiveConsumerConfig);
    }

    isolated remote function store(anydata message) returns error? {
        string id = uuid:createType1AsString();
        StoredEnvelope envelope = {
            id,
            payload: message
        };

        string payloadStr = envelope.toJsonString();
        check self.producer->send({
            topic: self.topic,
            key: id.toBytes(),
            value: payloadStr.toBytes()
        });
    }

    isolated remote function retrieve() returns messaging:Message|error? {
        kafka:AnydataConsumerRecord[] records = check self.consumer->poll(1);
        if records.length() == 0 {
            return;
        }

        kafka:AnydataConsumerRecord rec = records[0];
        string raw = check string:fromBytes(<byte[]>rec.value);
        json envelopeJson = check raw.fromJsonString();
        StoredEnvelope envelope = check envelopeJson.cloneWithType(StoredEnvelope);
        return {
            id: envelope.id,
            payload: envelope.payload
        };
    }

    isolated remote function acknowledge(string id, boolean success = true) returns error? {
        // No-op acknowledge; offsets are managed by the Kafka consumer configuration.
        return;
    }
}

