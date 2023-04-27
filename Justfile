deps: 
  helm repo add camunda "https://helm.camunda.io"
  helm repo update
setup:
  kubectl ctx gke_zeebe-io_europe-west1-b_zeebe-cluster
  - kubectl create ns os-ccs23
  kubectl ns os-ccs23
  # Create bucket if it does not already exist
  -gcloud storage buckets create --project zeebe-io gs://ccs23-backup
  # Setup service accounts and workload identity
  ./scripts/setup-auth.sh
  # Install C8
  helm install ccs23 camunda/camunda-platform --values setup/platform.yaml --values setup/backup.yaml
  kubectl rollout status statefulset ccs23-zeebe elasticsearch-master
  # Setup ES Snapshot Repository
  ./scripts/setup-es.sh
workload:
  kubectl apply -f setup/workload.yaml
backup:
  curl --request POST 'http://localhost:9600/actuator/backups' -H 'Content-Type: application/json' -d '{ "backupId": 100 }'
upgrade:
  helm upgrade ccs23 camunda/camunda-platform --values setup/platform.yaml --values setup/backup.yaml
  kubectl rollout status statefulset ccs23-zeebe
cleanup:
  helm uninstall ccs23
  kubectl delete pvc -l app.kubernetes.io/instance=ccs23
  kubectl delete pvc -l release=ccs23
  - gcloud storage rm -r --project zeebe-io gs://ccs23-backup
