#!/bin/bash

helm -n os-ccs23-dev upgrade ccs23-dev camunda/camunda-platform --values config/prod.yaml --values config/backup.yaml
kubectl -n os-ccs23-dev apply -f config/workload.yaml
kubectl -n os-ccs23-dev rollout status deploy ccs23-dev-operate &
kubectl -n os-ccs23-dev rollout status statefulset ccs23-dev-zeebe &
kubectl -n os-ccs23-dev rollout status -f config/workload.yaml &

wait