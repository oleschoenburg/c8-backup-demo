# C8 Backup Demo

## Prerequisites
Two service accounts are needed, one with read-write and one with read-only permissions.

```shell
gcloud iam service-accounts create os-gcs-rw --project zeebe-io
gcloud iam service-accounts create os-gcs-ro --project zeebe-io

gcloud projects add-iam-policy-binding zeebe-io \
    --member "serviceAccount:os-gcs-rw@zeebe-io.iam.gserviceaccount.com" \
    --role "roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding zeebe-io \
    --member "serviceAccount:os-gcs-ro@zeebe-io.iam.gserviceaccount.com" \
    --role "roles/storage.objectViewer"

gcloud iam service-accounts add-iam-policy-binding os-gcs-ro@zeebe-io.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:zeebe-io.svc.id.goog[os-ccs23-dev/ccs23-restore-client]"

gcloud iam service-accounts add-iam-policy-binding os-gcs-rw@zeebe-io.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:zeebe-io.svc.id.goog[os-ccs23-prod/ccs23-backup-client]"
```

## Getting started
1. Install [Backup CLI]
2. Run `./deps.sh` to install (and update) the helm charts.
3. Run `./setup-prod.sh` to deploy a fresh production cluster.
4. Run `./upgrade-prod.sh` to apply any changes in the `config/` manifests to the production cluster.
5. Run `./backup.sh` to take a single backup of the production cluster.
6. Run `./setup-dev.sh` to deploy a fresh development cluster.
7. Run `./upgrade-dev.sh` to apply any changes in the `config/` manifests to the development cluster.
8. Run `./restore.sh` to restore the development cluster based on the latest available backup.
9. Run `./cleanup.sh` to delete everything, including the backup bucket!

## Resources

- [Helm charts](https://github.com/camunda/camunda-platform-helm)
- [Backup & Restore Documentation](https://docs.camunda.io/docs/self-managed/backup-restore/backup-and-restore/)
- [Backup CLI]

[Backup CLI]: https://github.com/oleschoenburg/c8-backup