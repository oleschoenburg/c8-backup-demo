#!/bin/bash
kubectl create ns os-ccs23-prod

# Create bucket if it does not already exist
gcloud storage buckets create --project zeebe-io gs://ccs23-backup

# Setup service accounts and workload identity
kubectl -n os-ccs23-prod create serviceaccount ccs23-backup-client
kubectl -n os-ccs23-prod annotate serviceaccount ccs23-backup-client iam.gke.io/gcp-service-account=zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:zeebe-io.svc.id.goog[os-ccs23-prod/ccs23-backup-client]"

# Install C8
helm install -n os-ccs23-prod ccs23-prod camunda/camunda-platform --values config/prod.yaml --values config/backup.yaml
kubectl -n os-ccs23-prod rollout status statefulset os-ccs23-prod-zeebe elasticsearch-master &
kubectl -n os-ccs23-prod rollout status deploy ccs23-prod-operate &
kubectl -n os-ccs23-prod rollout status statefulset ccs23-prod-zeebe & 
wait

# Setup ES Snapshot Repository
kubectl -n os-ccs23-prod port-forward svc/elasticsearch-master 9200:9200 &
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
kill %1

# Deploy sample workload
kubectl -n os-ccs23-prod apply -f config/workload.yaml
kubectl -n os-ccs23-prod rollout status -f config/workload.yaml