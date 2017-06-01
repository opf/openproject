# Backup Guide

We advice to backup your OpenProject installation regularly — especially before upgrading to a newer version.

## Backup the Database

###OpenProject Version 3.0.15 and newer

Execute the following command in a shell in the directory where OpenProject is installed:

```bash
RAILS_ENV=production bundle exec rake backup:database:create
```

The command will create dump of your database which can be found at `OPENPROJECT_DIRECTORY/backup/openproject-production-db-<DATE>.sql` (for MySQL) or `OPENPROJECT_DIRECTORY/backup/openproject-production-db-<DATE>.backup` (for PostgreSQL).

Optionally, you can specify the path of the backup file. Therefore you have to replace the `/path/to/file.backup` with the path of your choice

```bash
RAILS_ENV=production bundle exec rake backup:database:create[/path/to/backup/file.backup]
```
*Note:* You can restore any database backup with the following command. Be aware that you have to replace the `/path/to/backup/file.backup` path with your actual backup path.

```bash
RAILS_ENV=production bundle exec rake backup:database:restore[/path/to/backup/file.backup]
```

If your database dump is from an old version of OpenProject, also run the following command after the restore:

```bash
RAILS_ENV=production bundle exec rake db:migrate
```

to migrate your data to the database structure of your installed OpenProject version.

### OpenProject prior Version 3.0.15

Determine which Database you are using. You can find the relevant information in the `OPENPROJECT_DIRECTORY/config/database.yml` file. It looks similar to this:

```yaml
production:
  adapter: postgresql
  database: openproject-production
  host: localhost
  username: my_postgres_user
  password: my_secret_password
  encoding: utf8
  min_messages: warning
```

Locate the database entry for your production database. If your adapter is postgresql, then you have a PostgreSQL database. If it is mysql2, you use a MySQL database. Now follow the steps for your database adapter.

#### PostgreSQL
You can backup your PostgreSQL database with the `pg_dump` command and restore backups with the `pg_restore` command. (There might be other (and more convenient) tools, like pgAdmin, depending on your specific setup.)

An example backup command with `pg_dump` looks like this:

```bash
pg_dump --clean --format=custom --no-owner --file=/path/to/your/backup/file.backup --username=POSTGRESQL_USER --host=HOST DATABASE_NAME
```

Please, replace the path to your backup file, the username, host, and database name with your actual data. You can find all relevant information in the database.yml file.

Consult the man page of `pg_dump` for more advanced parameters, if necessary.

The database dump can be restored similarly with `pg_restore`:

```bash
pg_restore --clean --no-owner --single-transaction
--dbname=DATABASE_NAME --host=HOST --username=POSTGRESQL_USER
/path/to/your/backup/file.backup
```

Consult the man page of `pg_restore` for more advanced parameters, if necessary.

#### MySQL
You can backup your MySQL database for example with the mysqldump command and restore backups with the mysql command line client. (There might be other (and more convenient) tools, like phpMyAdmin, adminer, or other tools, depending on your specific setup.)

An example backup command with `mysqldump` looks like this:

```bash
mysqldump --single-transaction --add-drop-table --add-locks --result-file=/path/to/your/backup/file.sql --host=HOST --user=MYSQL_USER --password DATABASE_NAME
```

Please, replace the path to your backup file, the MySQL username, host and database name with your actual data. You can find all relevant information in the `database.yml` file.

Consult the man page of `mysqldump` for more advanced parameters, if necessary.

The database dump can be restored similarly with `mysql` (on a \*nix compatible shell):

```bash
mysql --host=HOST --user=MYSQL_USER --password DATABASE_NAME < /path/to/your/backup/file.sql
```
Consult the man page of mysql for more advanced parameters, if necessary.

## Backup your Configuration Files
Please make sure to create a backup copy of at least the following configuration files (all listed as a relative path from the OpenProject installation directory):

`Gemfile.local` (if present)
`Gemfile.plugins` (if present)
`config/database.yml` (if present)
`config/configuration.yml` (if present)
`config/settings.yml` (if present)

Some OpenProject options can be given as environment variables. If you have configured environment variables for OpenProject, consider to backup them too.

## Backup Files Uploaded by Users (attachments)
Files uploaded by users (e.g. when adding an attachment to a WorkPackage) are stored on the hard disk. The directory where those files are stored can be configured in the `config/configuration.yml` via the `attachments_storage_path` setting (or an
appropriate environment variable).

If you have not changed the `attachment_storage_path` setting, all files will be uploaded to the files directory (relative to your OpenProject installation).

Make sure to backup this directory.

## Backup Repositories
You can manage Repositories with OpenProject — so one or more of your projects may have a repository. Please make sure to backup these too. The path to a project’s repository can be found in the repository settings of the respective project (it can be individually defined for every project). Each of the defined locations has to be backed up.
