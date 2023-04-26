#!/bin/bash
kubectl port-forward svc/ccs23-zeebe-gateway 9600:9600 &
backupId=$(date +%s)
curl --silent --request POST 'http://localhost:9600/actuator/backups' \
    --connect-timeout 30 --retry-connrefused --retry 10 --retry-delay 5 \
    -H 'Content-Type: application/json' \
    -d "{ \"backupId\": \"$backupId\" }" | jq
sleep 15
curl --request GET "http://localhost:9600/actuator/backups/$backupId" | jq
kill %1