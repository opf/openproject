# Changing database encoding

This instructions are primarily intended to help with an error encountered when migrating to OpenProject 15.
The error happens when migration tries to create an ICU collation and database encoding doesn't support it.
We suggest to use unicode encoding for maximum compatibility.

## Preconditions

- Credentials with the permission to create a database in the database server the OpenProject installation is running against.
- Shell access to the OpenProject server.

## 1. Create a database dump

This and following steps assume that you are using built in `openproject` command.

```shell
openproject run backup
```

Ensure it finished successfully and note down the path after `Generating database backup` that should normally be
in form `/var/db/openproject/backup/postgresql-dump-<DATE_TIME_DIGITS>.pgdump`.

See also [Backing up your OpenProject installation page](../../operation/backing-up).

## 2. Create a new database with different encoding

Note down the database connection URL that should be in form `postgres://<USERNAME>:<PASSWORD>@<HOST>:<PORT>/<DATABASE>`:

```shell
openproject config:get DATABASE_URL
```

Create new database using `psql` command, after deciding on the name, for example `openproject-unicode`:

```shell
psql '<DATABASE_URL>' -c 'CREATE DATABASE "<NEW_DATABASE_NAME>" ENCODING UNICODE'
```

Options for `CREATE DATABASE` can be found at [PostgreSQL documentation page](https://www.postgresql.org/docs/current/sql-createdatabase.html).

Or alternatively using `createdb` command:

```shell
su postgres -c createdb -E UNICODE -O <dbusernamer> openproject_backup
```

Instructions for `createdb` command can be found at [PostgreSQL documentation page](https://www.postgresql.org/docs/17/app-createdb.html).

## 3. Restore the dump to the new database

To get the new database URL you need to replace the old database name with the new database name in the connection URL that you got in the previous step.
For example if it was `postgres://openproject:hard-password@some-host:5432/openproject` and new database name was chosen to be `openproject-unicode`, then
new database URL will be `postgres://openproject:hard-password@some-host:5432/openproject-unicode`.

```shell
pg_restore -d '<NEW_DATABASE_URL>' '<PATH_TO_THE_DATABASE_DUMP>'
```

See also [Restoring an OpenProject backup](../../operation/restoring/).

## 4. Change configuration to use the new database

Using the new database URL from previous step:

```shell
openproject config:set DATABASE_URL=<NEW_DATABASE_URL>
```

See also [Configuring a custom database server page](../../configuration/database/).
