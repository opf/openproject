# Migrating from an old MySQL database

If you need to migrate from any older version of OpenProject, upgrading multiple versions in order to get the newest version will be cumbersome. For example, for upgrading from OpenProject 4.3 to the stable 10.6, you will need to upgrade to OpenProject 7.2, and then to OpenProject 10.6.

If you also need to migrate from MySQL to PostgreSQL during that process, the steps will become more involved.

To make this easier there is a script which automates database migration and conversion in one simple step. The only dependency is [a docker installation](https://www.docker.com/get-started). It's included in the docker image itself but you will want to run it directly on the docker host. To do that you can either copy it onto your system from `/app/script/migration/migrate-from-pre-8.sh` or simply download it [here](https://github.com/opf/openproject/tree/dev/script/migration/migrate-from-pre-8.sh).

All the script needs is docker to be installed. It will start containers as required for the migration and clean them up afterwards. The result of the migration will be a SQL dump of OpenProject in the current stable version. This can then be used with a fresh packaged installation, or an upgraded package. See [how to restore a backup](../../../installation-and-operations/operation/restoring/).

## Usage

### Create a backup

First, you will need to create a backup to get the MySQL database dump. Please see our separate guide on [Backing up](../../operation/backing-up/). In a packaged installation, the following command will output a full backup to `/var/db/openproject/backup`:

```shell
openproject run backup
```

This will output a MySQL dump at `/var/db/openproject/backup/mysql-dump-<timestamp>.sql.gz`. You will need to gunzip this:

```shell
cp /var/db/openproject/backup/mysql-dump-<timestamp>.sql.gz /tmp/openproject-mysql.dump.gz
gunzip /tmp/openproject/openproject-mysql.dump.gz
```

### Run the docker migration script

With docker installed, use the following command to start the upgrade process on your MySQL dump.

```shell
bash migrate-from-pre-8.sh <docker host IP> <Path to MySQL dump file> [sql|custom]
```

You will need to find the docker host IP to connect to the temporary MySQL database the docker container will start and connect to a host port. It will likely be `host.docker.internal` but you need to double-check with your docker version and OS. You can use `hostname -I` to confirm the address.

The script will output a `<database name>-migrated.dump` pg_dump file which has been migrated and upgraded to the current stable version. You can also pass `sql` as a parameter after the input dump file to have the script output a `.sql` file instead of a `.dump` file.

## Restoring the migrated database

You now have an old packaged installation with an old database, and a separate database dump of the current version migrated to PostgreSQL.

To upgrade OpenProject and use this dump, you have two options:

### Upgrading your existing installation

You can simply upgrade your package first and then switch to a PostgreSQL database. You will basically have to follow our [Upgrading guide](../../operation/upgrading/).

1. Upgrade the package according to the upgrade guide. Switch to the current stable package repository, and let your package manager upgrade the openproject package

2. Run `openproject reconfigure` to choose to auto install a PostgreSQL database in the first step of the wizard.

3. After this is completed, stop the servers to restore the database separately

   `service openproject stop`

The following command will restore the database. **WARNING:** This will remove the database returned by `openproject config:get DATABASE_URL`, so please double check this is what you want to do:

   `pg_restore --clean --if-exists --dbname $(openproject config:get DATABASE_URL) /path/to/migrated/postgresql.dump`  

4. Execute configure script to ensure the migrations are complete and to restart the server

### Re-Installing OpenProject

The alternative option is to remove your current installation, upgrade the newest package and configure a PostgreSQL database. This will ensure the package wizard will install and maintain a PostgreSQL database for you.

Remove your OpenProject installation, follow our ["Migrate to a different environment"](../../misc/migration/) guide to install OpenProject on a new server and then restore the backup you made earlier, replacing the old database backup with the migrated PostgreSQL dump file.

The steps for this option is as follows:

1. Remove OpenProject with your package manager, e.g., `sudo apt remove openproject` on Debian/Ubuntu systems.

2. Use our [packaged installation guide](../../installation/packaged/) for your distribution to install the newest version

3. From your backup, restore the configuration and attachment files ([See our restoring guide](../../operation/restoring/) for more information):

   `tar xzf conf-<timestamp>.tar.gz -C /etc/openproject/conf.d/`

   `tar xzf attachments-<timestamp>.tar.gz -C /var/db/openproject/files`

4. Run `openproject reconfigure` and select to install a PostgreSQL database

5. This will install and migrate a new PostgreSQL database

6. After this is completed, stop the servers to restore the database separately

   `service openproject stop`

   `pg_restore --dbname $(openproject config:get DATABASE_URL) /path/to/migrated/postgresql.dump`  

7. Execute configure script to ensure the migrations are complete and to restart the server

   `openproject configure`

## Problems with the migration?

Please let us know if you have any questions regarding this upgrade path. Reach out to us [through our contact data or form on our website](https://www.openproject.org/contact/) with feedback and issues you experienced.

We're very interested in providing a smooth upgrade at all times, and would like to document issues you experience during the upgrade.

### Known problems

**Permission errors when trying to start the OP7 container**

If you run into permission errors trying to start the OP7 container, you might have advanced tmpfs protections in place. Disable them temporarily with `sudo sysctl fs.protected_regular=0` (https://askubuntu.com/questions/1250974)
