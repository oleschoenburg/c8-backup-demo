#!/bin/bash

helm -n os-ccs23-prod upgrade ccs23-prod camunda/camunda-platform --values config/prod.yaml --values config/backup.yaml
kubectl -n os-ccs23-prod apply -f config/workload.yaml
kubectl -n os-ccs23-prod rollout status deploy ccs23-prod-operate &
kubectl -n os-ccs23-prod rollout status statefulset ccs23-prod-zeebe & 
kubectl -n os-ccs23-prod rollout status -f config/workload.yaml &

wait