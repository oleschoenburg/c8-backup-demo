#!/bin/bash

kubectl delete ns os-ccs23-prod &
kubectl delete ns os-ccs23-dev &
gcloud storage rm -r --project zeebe-io gs://ccs23-backup &

wait