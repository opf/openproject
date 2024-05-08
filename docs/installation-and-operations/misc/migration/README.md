# Migrating your packaged OpenProject installation to another environment

**Note:** this guide only applies if you've installed OpenProject using our DEB/RPM packages.

Migrating your OpenProject packaged installation to another host or environment is trivial and may be combined with, e.g., minor or major package upgrades due to our migration system.

## Backing up

To create a dump of all your data in the old installation, please follow our [backup and restore guides](../../operation) for our packaged installation.

This guide should leave you with a set of archives that you should manually move to your new environment:

- **Database**: postgresql-dump\<timestamp>.pgdump
- **Attachments**: attachments-\<timestamp>.tar.gz
- **Custom env configuration**: conf-\<timestamp>.tar.gz
- **Repositories**: svn- and git-\<timestamp>.tar.gz

## Migration

The following steps outline the migration process to the OpenProject package (possibly, a newer version).

## Stop OpenProject on old server

To stop the servers from being accessed on the old installation, stop the service with `service openproject stop` or `systemctl stop openproject` depending on your distribution.

## Install new package

Follow the first step (**Installation**) of our [packaged installation guides](../../installation/packaged/) up until _but excluding_ the [Step 0: Start the wizard](../../installation/packaged/#step-0-start-the-wizard) step.

With this done, you should have an installed version of OpenProject with the `openproject` command existing. Do not yet run `openproject configure`, because you will first take over the configuration
from your previous installation.

### Moving Configuration

On your old host, the configuration of the package resides in `/etc/openproject`.

This folder is split into two relevant files:

**The installer.dat file**
The `/etc/openproject/installer.dat` is the result of your input in the installation wizard (`openproject configure`). It contains all configuration options that the wizard generates, such as database URL, storage paths, hostname et cetera.

If most of your environment is the same (e..g, new server under the same domain), you will want to copy the entire configuration folder `/etc/openproject`. This will cause `openproject configure` to take all values from your previous installation.

You can simply look through the installer.dat and change those values you need.

**The conf.d folder**

Additional environment, either generated from the wizard or entered by you through `openproject config:set` is written to  `/etc/openproject/conf.d/{server,database,other}`. Also look through those and check which contain relevant values for your new installation.

### PostgreSQL database

On your new host or cluster, ensure you have created a database user and database, ideally using the same names as the old environment (You may want to choose a different random password, however).

In the following, the values `<dbuser>`, `<dbhost>` and `<dbname>` variables have to be replaced with your database user and database above.
To read the values from the old installation, you can execute the following command:

```shell
openproject config:get DATABASE_URL
#=> e.g.: postgres://dbusername:dbpassword@dbhost:dbport/dbname
```

First the dump has to be extracted (unzipped) and then restored. The command used should look very similar to the following. The `--clean` option is used to drop any database object within `<dbname>` so ensure this is the correct database you want to restore, as you will lose all data within it!

```shell
# Restore the PostgreSQL dump
pg_restore -h <dbhost> -u <dbuser> -W --dbname <dbname> --clean postgresql-dump-20180408095521.pgdump
```

### Attachments

Your storage path on the old installation can be shown using the following command:

```shell
openproject config:get OPENPROJECT_ATTACHMENTS__STORAGE__PATH
#=> e.g., /var/db/openproject/files
```

On versions prior to 12.5, the environment variable was named differently. Use
the following command to show the storage path:

```shell
openproject config:get ATTACHMENTS_STORAGE_PATH
#=> e.g., /var/db/openproject/files
```

Simply extract your attachments dump into that folder with `tar -xvzf <dump>.tar.gz`,
creating it beforehand if needed. Ensure that this is writable by the `openproject` user.

### Repositories

For repositories, the same approach applies as for the attachments:

Your SVN and Git storage paths on the old installation can be shown using the following command:

```shell
# Subversion
openproject config:get SVN_REPOSITORIES
#=> e.g., /var/db/openproject/svn

# Git
openproject config:get GIT_REPOSITORIES
#=> e.g., /var/db/openproject/git
```

Simply extract your respective repository dumps into ech folder, creating it beforehand if needed. The dumps will only be created if you use that feature in your old installation.

## Running openproject configure

After you restored all data and updated your installer.dat, all you need to do is run through the configuration process of the packaged installation:

```shell
openproject configure
```

It will take all values from your previous installation. *It may ask you additional wizard questions*  for new features that did not exist on the old installations, or the ones you removed/left empty in the `installer.dat` file.

This step will also perform database migrations, install and configure all necessary dependencies and start the server.
