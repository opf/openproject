# addon-postgres

PostgreSQL addon for pkgr.

New autoinstallations provision PostgreSQL 18 with pgvector available using packages from https://www.postgresql.org/download/linux/.

Existing configured installations retain their PostgreSQL major and are only checked for connectivity. Reused external databases are not modified. Install the matching pgvector package for existing databases. OpenProject handles extension creation during application migrations.

OpenProject packages use this vendored addon, not the upstream `pkgr/addon-postgres` repository.

Automatic installation is supported for OpenProject's Debian 11/12, Ubuntu 22.04, and Enterprise Linux 9 package targets. SLES requires a separately managed PostgreSQL installation.

## Development

    sudo apt-get update -qq && sudo apt-get install dialog -y

    export APP_NAME="testapp"
    export APP_SAFE_NAME="testapp"
    export INSTALLER_DIR="/path/to/pkgr-installer-dir"
    sudo useradd "$APP_NAME"
    sudo mkdir -p /etc/testapp/conf.d

    sudo -E INSTALLER_DEBUG=no WIZ_RECONFIGURE=no DATABASE=/tmp/test1 ./bin/configure
    sudo -E INSTALLER_DEBUG=no WIZ_RECONFIGURE=no DATABASE=/tmp/test1 ./bin/preinstall

## Tests

See [the test instructions](tests/README.md) for provisioning and Debian package installation checks.
