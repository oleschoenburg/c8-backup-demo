# C8 Backup Demo

## Getting started

1. Install [just](https://just.systems/man/en/), a modern make alternative.
2. Install [Backup CLI]
3. Run `just deps` to install (and update) the helm charts.
4. Run `just setup` to deploy a fresh cluster.
5. Run `just backup` to take a backup.
6. Run `just cleanup` to delete everything, including the backup bucket!

## Resources

- [Helm charts](https://github.com/camunda/camunda-platform-helm)
- [Backup & Restore Documentation](https://docs.camunda.io/docs/self-managed/backup-restore/backup-and-restore/)
- [Backup CLI]

[Backup CLI]: https://github.com/Sijoma/camunda-backup-cli