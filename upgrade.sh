#!/bin/bash

helm upgrade ccs23 camunda/camunda-platform --values config/platform.yaml --values config/backup.yaml
kubectl apply -f config/workload.yaml
kubectl rollout status deploy ccs23-operate
kubectl rollout status statefulset ccs23-zeebe
kubectl rollout status -f config/workload.yaml