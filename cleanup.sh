#!/bin/bash

helm uninstall ccs23
kubectl delete pvc -l app.kubernetes.io/instance=ccs23
kubectl delete pvc -l release=ccs23
gcloud storage rm -r --project zeebe-io gs://ccs23-backup
kubectl delete -f config/workload.yaml