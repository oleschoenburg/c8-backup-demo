#!/bin/bash

kubectl create ns os-ccs23-dev

kubectl -n os-ccs23-dev create serviceaccount ccs23-restore-client
kubectl -n os-ccs23-dev annotate serviceaccount ccs23-restore-client iam.gke.io/gcp-service-account=zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:zeebe-io.svc.id.goog[os-ccs23-dev/ccs23-restore-client]"

helm install -n os-ccs23-dev ccs23-dev camunda/camunda-platform --values config/dev.yaml --values config/restore.yaml
kubectl -n os-ccs23-dev rollout status statefulset ccs23-dev-zeebe elasticsearch-master &
kubectl -n os-ccs23-dev rollout status deploy ccs23-dev-operate &
kubectl -n os-ccs23-dev rollout status statefulset ccs23-dev-zeebe & 
wait

# Setup ES Snapshot Repository
kubectl -n os-ccs23-dev port-forward svc/elasticsearch-master 9200:9200 &
sleep 1
curl -X PUT "localhost:9200/_snapshot/gcs?pretty" -H 'Content-Type: application/json' --connect-timeout 30 --retry-connrefused --retry 10 --retry-delay 5 -d'
{
  "type": "gcs",
  "settings": {
    "bucket": "ccs23-backup",
    "base_path": "elasticsearch"
  }
}
'
