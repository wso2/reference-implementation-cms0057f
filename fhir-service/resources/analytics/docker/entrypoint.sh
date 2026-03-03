#!/bin/bash
set -e

# Start the Ballerina service
echo "[entrypoint] Starting Ballerina app..."
exec java -jar /home/ballerina/fhir.service.jar &

# Start Fluent Bit server
/opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf
