#!/bin/bash
set -xeo pipefail

# Lookup information about the latest backup
kubectl -n os-ccs23-prod port-forward svc/ccs23-prod-zeebe-gateway 9601:9600 &
kubectl -n os-ccs23-prod port-forward svc/elasticsearch-master 9200:9200 &
sleep 1

backupId=$(curl -s localhost:9601/actuator/backups | jq 'map(select(.state == "COMPLETED")) | map(.backupId)  | sort | last')
zeebeSnapshot=camunda_zeebe_records-"$backupId"
operateSnapshots=$(curl -s localhost:9200/_snapshot/gcs/camunda_operate_"$backupId"_\* | jq -r .snapshots[].snapshot)
kill %1 %2
if [ -z "$backupId" ]; then
  echo "No completed backups found"
  exit 1
fi

# Shut down Zeebe
kubectl -n os-ccs23-dev scale statefulset ccs23-dev-zeebe --replicas=0
kubectl -n os-ccs23-dev scale deploy ccs23-dev-zeebe-gateway --replicas=0

## Shut down Operate
kubectl -n os-ccs23-dev scale deploy ccs23-dev-operate --replicas=0
kubectl -n os-ccs23-dev rollout status deploy ccs23-dev-operate
sleep 10

kubectl -n os-ccs23-dev port-forward svc/elasticsearch-master 9200:9200 &

sleep 3
# Delete Operate indices from ES
for index in $(curl -s localhost:9200/operate\* | jq -r keys[])
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
for index in $(curl -s localhost:9200/zeebe\* | jq -r keys[])
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

# Delete jobs
NODEID=0 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl delete -f - 
NODEID=1 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl delete -f - 
NODEID=2 BACKUPID=$backupId envsubst < config/data-deletion-job.yaml | kubectl delete -f - 

NODEID=0 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl delete -f - 
NODEID=1 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl delete -f - 
NODEID=2 BACKUPID=$backupId envsubst < config/restore-job.yaml | kubectl delete -f - 

kubectl -n os-ccs23-dev scale statefulset ccs23-dev-zeebe --replicas=3
kubectl -n os-ccs23-dev scale deploy ccs23-dev-operate --replicas=1
kubectl -n os-ccs23-dev scale deploy ccs23-dev-zeebe-gateway --replicas=1

kill %1