# PostgreSQL addon tests

Run from `packaging/addons/addon-postgres` with Docker available:

```shell
docker build -t addon-postgres-test tests
docker run --rm -v "$PWD:/source:ro" addon-postgres-test /source/tests/provision.sh

docker build -f tests/package.Dockerfile -t addon-postgres-package-test tests
docker run --rm -v "$PWD:/source:ro" addon-postgres-package-test /source/tests/package.sh
```

`provision.sh` uses an image with PostgreSQL 17, its pgvector package, and PostgreSQL 18 (without pgvector) from PGDG. It checks that reconfiguring an existing PostgreSQL 17 database retains its major version and leaves vector inactive. It then provisions an addon-managed PostgreSQL 18 server and checks that the addon installs `postgresql-18-pgvector` from PGDG and creates the database without activating vector.

`package.sh` installs PostgreSQL 18 and pgvector on clean Debian 12 using the addon, then checks connectivity on the configured port, the server major version, the installed pgvector package, and vector availability without activation.

Both tests run real database and package commands against Debian and PGDG and substitute only the wizard functions. They fail if the addon prints a `WARNING:` or `ERROR:` line. They test the addon, not installation of a complete OpenProject package, and run in CI via [`addon-postgres-test.yml`](../../../../.github/workflows/addon-postgres-test.yml) when files in this addon change. Enterprise Linux is not covered.
