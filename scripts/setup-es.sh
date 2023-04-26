#!/bin/bash
kubectl port-forward svc/elasticsearch-master 9200:9200 &
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