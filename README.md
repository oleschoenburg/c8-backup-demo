# C8 Backup Demo

## Getting started
1. Install [Backup CLI]
2. Run `./deps.sh` to install (and update) the helm charts.
3. Run `./setup.sh` to deploy a fresh cluster.
4. Run `./upgrade.sh` to apply any changes in the `config/` manifests.
5. Run `./backup.sh` to take a single backup.
6. Run `./cleanup.sh` to delete everything, including the backup bucket!

## Resources

- [Helm charts](https://github.com/camunda/camunda-platform-helm)
- [Backup & Restore Documentation](https://docs.camunda.io/docs/self-managed/backup-restore/backup-and-restore/)
- [Backup CLI]

[Backup CLI]: https://github.com/Sijoma/camunda-backup-cli