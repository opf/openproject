# AIO PostgreSQL tests

Run from the repository root with Docker available:

```shell
docker build -t openproject-postgresql-test docker/tests/postgresql
docker run --rm -v "$PWD:/source:ro" openproject-postgresql-test /source/docker/tests/postgresql/upgrade.sh
docker run --rm -v "$PWD:/source:ro" openproject-postgresql-test /source/docker/tests/postgresql/provision.sh
```

The tests create disposable PostgreSQL clusters inside containers:

- `upgrade.sh` checks PostgreSQL 17→18 upgrades with vector data and checksums enabled and disabled.
- `provision.sh` checks AIO version mismatch rejection, pgvector availability without provisioning-time activation, external database handling, and PostgreSQL 17 pins.

The provisioning test substitutes application migration/seeding commands and the final supervisor launch. It tests AIO database setup, not the full application or packaged installer.
