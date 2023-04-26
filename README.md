# C8 Backup Demo

## Getting started

1. Install [just](https://just.systems/man/en/), a modern make alternative.
2. Connect to the right kubernetes context, you can check with `kubectl ctx`.
3. Run `just deps` to install (and update) the helm charts.
4. Run `just setup` to deploy a fresh cluster.

## Resources

- [Helm charts](https://github.com/camunda/camunda-platform-helm)
- [Backup & Restore Documentation](https://docs.camunda.io/docs/self-managed/backup-restore/backup-and-restore/)