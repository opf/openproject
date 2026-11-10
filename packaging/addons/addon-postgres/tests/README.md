# PostgreSQL addon tests

Run from `packaging/addons/addon-postgres` with Docker available:

```shell
docker build -t addon-postgres-test tests
docker run --rm -v "$PWD:/source:ro" addon-postgres-test /source/tests/provision.sh

docker build -f tests/package.Dockerfile -t addon-postgres-package-test tests
docker run --rm -v "$PWD:/source:ro" addon-postgres-package-test /source/tests/package.sh
```

`provision.sh` checks that reconfiguring an existing PostgreSQL 17 database skips installation and leaves vector disabled. It also checks that pgvector is available but not activated when creating a new application database on PostgreSQL 18.

`package.sh` installs PostgreSQL 18 and pgvector on clean Debian 12 using the addon, then checks connectivity on the configured port and pgvector availability without activation. It downloads packages from Debian and PGDG.

Both tests run real database commands and substitute only the wizard functions. They test the addon, not installation of a complete OpenProject package. The provisioning image already contains PostgreSQL; the package test exercises OS package installation.
