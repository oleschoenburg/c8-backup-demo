#!/bin/bash
kubectl port-forward svc/elasticsearch-master 9200:9200 &
kubectl port-forward svc/ccs23-zeebe-gateway 9601:9600 &
kubectl port-forward deploy/ccs23-operate 9602:8080 &

sleep 5
c8backup backup --elastic localhost:9200 --elastic-repository gcs --zeebe localhost:9601 --operate localhost:9602

kill %1 %2 %3