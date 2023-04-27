#!/bin/bash

# Connect to dev
kubectl -n os-ccs23-dev port-forward svc/elasticsearch-master 9200:9200 &
kubectl -n os-ccs23-dev port-forward svc/ccs23-dev-zeebe-gateway 9601:9600 &
kubectl -n os-ccs23-dev port-forward deploy/ccs23-dev-operate 9602:8080 &

sleep 3

# Lookup information about the latest backup
backupId=$(curl -s localhost:9601/actuator/backups | jq 'map(select(.state == "COMPLETED")) | map(.backupId)  | sort | last')
zeebeIndices=$(curl -s localhost:9200/_cat/indices | grep zeebe | awk '{print $3}')
zeebeSnapshot=camunda_zeebe_records-"$backupId"
operateIndices=$(curl -s localhost:9200/_cat/indices | grep operate | awk '{print $3}')
operateSnapshots=$(curl -s localhost:9602/actuator/backups/"$backupId" | jq -r .details[].snapshotName)

# Shut down Zeebe
kubectl -n os-ccs23-dev scale statefulset ccs23-dev-zeebe --replicas=0
kubectl -n os-ccs23-dev scale deploy ccs23-dev-zeebe-gateway --replicas=0

## Shut down Operate
kubectl -n os-ccs23-dev scale deploy ccs23-dev-operate --replicas=0
kubectl -n os-ccs23-dev rollout status deploy ccs23-dev-operate

# Delete Operate indices from ES
for index in $operateIndices
do
  echo "Deleting index $index"
  curl -s -X DELETE "localhost:9200/$index"
done

# Restore Operate indices from ES snapshot
for snapshot in $operateSnapshots
do
  echo "Restoring snapshot $snapshot"
  curl -s -X POST "http://localhost:9200/_snapshot/gcs/$snapshot/_restore?wait_for_completion=true" | jq
done

# Delete Zeebe indices from ES
for index in $zeebeIndices
do
  echo "Deleting index $index"
  curl -s -X DELETE "localhost:9200/$index"
done

# Restore all Zeebe indices from ES Snapshot
curl -s -X POST "http://localhost:9200/_snapshot/gcs/$zeebeSnapshot/_restore?wait_for_completion=true" | jq


# Delete Zeebe data for each node
NODEID=0 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl apply -f - 
NODEID=1 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl apply -f - 
NODEID=2 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl apply -f - 

NODEID=0 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl wait --for=condition=complete -f -
NODEID=1 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl wait --for=condition=complete -f -
NODEID=2 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl wait --for=condition=complete -f -

# Run restore job for each node
NODEID=0 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl apply -f - 
NODEID=1 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl apply -f - 
NODEID=2 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl apply -f - 

NODEID=0 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl wait --for=condition=complete -f -
NODEID=1 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl wait --for=condition=complete -f -
NODEID=2 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl wait --for=condition=complete -f -

kubectl -n os-ccs23-dev scale statefulset ccs23-dev-zeebe --replicas=3
kubectl -n os-ccs23-dev scale deploy ccs23-dev-operate --replicas=1
kubectl -n os-ccs23-dev scale deploy ccs23-dev-zeebe-gateway --replicas=1

kill %1 %2 %3