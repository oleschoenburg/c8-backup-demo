#!/bin/bash
kubectl -n os-ccs23-prod port-forward svc/elasticsearch-master 9200:9200 &
kubectl -n os-ccs23-prod port-forward svc/ccs23-prod-zeebe-gateway 9601:9600 &
kubectl -n os-ccs23-prod port-forward deploy/ccs23-prod-operate 9602:8080 &

sleep 5
c8backup backup --elastic localhost:9200 --elastic-repository gcs --zeebe localhost:9601 --operate localhost:9602

kill %1 %2 %3