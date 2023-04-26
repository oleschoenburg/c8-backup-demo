#!/bin/bash

kubectl create serviceaccount ccs23-backup-client
kubectl annotate serviceaccount ccs23-backup-client iam.gke.io/gcp-service-account=zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding zeebe-gcs-sa@zeebe-io.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:zeebe-io.svc.id.goog[os-ccs23/ccs23-backup-client]"
