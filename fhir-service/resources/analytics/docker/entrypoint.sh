#!/bin/bash
set -euo pipefail

java -jar /home/ballerina/fhir.service.jar &
java_pid=$!

/opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf &
fluent_pid=$!

trap 'kill -TERM $java_pid $fluent_pid 2>/dev/null || true' TERM INT
wait -n $java_pid $fluent_pid
code=$?
kill -TERM $java_pid $fluent_pid 2>/dev/null || true
wait || true
exit $code