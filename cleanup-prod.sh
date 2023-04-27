#!/bin/bash

kubectl delete ns os-ccs23-prod &
gcloud storage rm -r --project zeebe-io gs://ccs23-backup &

wait