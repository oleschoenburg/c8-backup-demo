#!/bin/bash
kubectl ctx gke_zeebe-io_europe-west1-b_zeebe-cluster
kubectl create ns os-ccs23
kubectl ns os-ccs23

# Create bucket if it does not already exist
gcloud storage buckets create --project zeebe-io gs://ccs23-backup

# Setup service accounts and workload identity
kubectl create serviceaccount ccs23-backup-client
kubectl annotate serviceaccount ccs23-backup-client iam.gke.io/gcp-service-account=zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:zeebe-io.svc.id.goog[os-ccs23/ccs23-backup-client]"

# Install C8
helm install ccs23 camunda/camunda-platform --values config/platform.yaml --values config/backup.yaml
kubectl rollout status statefulset ccs23-zeebe elasticsearch-master

# Setup ES Snapshot Repository
kubectl port-forward svc/elasticsearch-master 9200:9200 &
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
kubectl apply -f config/workload.yaml
kubectl rollout status -f config/workload.yaml