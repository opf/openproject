# PostgreSQL provisioning and upgrade tests

Run from the repository root with Docker available:

```shell
docker build -t openproject-postgresql-test docker/tests/postgresql
docker run --rm -v "$PWD:/source:ro" openproject-postgresql-test /source/docker/tests/postgresql/upgrade.sh
docker run --rm -v "$PWD:/source:ro" openproject-postgresql-test /source/docker/tests/postgresql/provision.sh
```

The tests create disposable PostgreSQL clusters inside containers. They exercise checksum-preserving 17→18 upgrades with vector data, AIO mismatch rejection, fresh-only extension activation, external database handling, explicit PostgreSQL 17 pins, and packaged database creation/reconfiguration.

The provisioning test substitutes application migration/seeding commands and the final supervisor launch. It validates database provisioning, not the full OpenProject application or OS package installation.

To exercise the real Debian 12 package installation from a clean OS image:

```shell
docker build -f docker/tests/postgresql/package.Dockerfile -t openproject-postgresql-package-test docker/tests/postgresql
docker run --rm -v "$PWD:/source:ro" openproject-postgresql-package-test /source/docker/tests/postgresql/package.sh
```

This test downloads packages from Debian and PGDG, creates the cluster through the installer, and checks PostgreSQL 18 and a vector query. It substitutes the wizard's input storage, not the package manager or database commands.
