# Fixing time entries corrupted by upgrading to 10.4.0

<div class="alert alert-info" role="alert">

**Note**: This guide only concerns installations having upgraded exactly to the OpenProject version 10.4.0. Installations having upgraded to 10.4.1 directly are not affected.

</div>

The migration scripts that ran as part of the OpenProject 10.4.0 upgrade include an unfortunate bug that leads to some installations suffering data loss. 
Installations, that had time entry activities enabled/disabled per project, will have all their time entries assigned to a single time entry activity.

This guide describes how to fix the data once this has happened.

## Preconditions

* A backup file of a database state prior to 10.4.0.
* Credentials with the permission to create a database in the database server the OpenProject installation is running against.
* Console access to the OpenProject server.

## 1. Create a second database from the backup

Backup scripts are by default created via the [built in OpenProject command](../../operation/backing-up). 
When not following the default, the database or the OpenProject server itself may have been backed up. 
This guide only covers the proceedings for the the built in backup command. 
But the reader might deduce the steps neccessary to restore accordingly for a custom backup from this guide.

As a result of this step, a second database, not the database OpenProject is currently connecting to, will contain the data of the backup.

### 1.1 Get necessary database information

First, connect to the OpenProject server and get the necessary details about your current database:

```bash
$ openproject config:get DATABASE_URL
#=> e.g.: postgres://<dbusername>:<dbpassword>@<dbhost>:<dbport>/<dbname>
```

Example:

```bash
$ openproject config:get DATABASE_URL
postgres://openproject:L0BuQvlagjmxdOl6785kqwsKnfCEx1dv@127.0.0.1:45432/openproject
```

### 1.2 Create auxillary database

Using this connection string, the following command will create the database the backup will be restored to (named `openproject_backup` in this example):

```bash
$ psql "postgres://<dbusername>:<dbpassword>@<dbhost>:<dbport>/<dbname>" -c 'CREATE DATABASE <new_dbname>'
CREATE DATABASE
```

Example:

```bash
$ psql "postgres://openproject:L0BuQvlagjmxdOl6785kqwsKnfCEx1dv@127.0.0.1:45432/openproject" -c 'CREATE DATABASE openproject_backup'
CREATE DATABASE
```

The command above might not work for some installations. In that case the following is a viable alternative:

```bash
$ su postgres -c createdb -O <dbusernamer> openproject_backup
```

Example:

```bash
$ su postgres -c createdb -O openproject openproject_backup
```

### 1.3 Restore backup to auxillary database

Next, that newly created database will receive the data from a backup file which typically can be found in `/var/db/openproject/backup`

```bash
$ ls -al /var/db/openproject/backup/
total 1680
drwxr-xr-x 2 openproject openproject    4096 Nov 19 21:00 .
drwxr-xr-x 6 openproject openproject    4096 Nov 19 21:00 ..
-rw-r----- 1 openproject openproject 1361994 Nov 19 21:00 attachments-20191119210038.tar.gz
-rw-r----- 1 openproject openproject    1060 Nov 19 21:00 conf-20191119210038.tar.gz
-rw-r----- 1 openproject openproject     126 Nov 19 21:00 git-repositories-20191119210038.tar.gz
-rw-r----- 1 openproject openproject  332170 Nov 19 21:00 postgresql-dump-20191119210038.pgdump
-rw-r----- 1 openproject openproject     112 Nov 19 21:00 svn-repositories-20191119210038.tar.gz
```

We will need the most recently created (but created before the migration to 10.4) file following the schema `postgresql-dump-<TIMESTAMP>.pgdump`.

Using that file we can then restore the database to the newly created database (called `openproject_backup` in our example). **In the following steps, ensure that you do not restore to the currently running database**. 

```bash
$ pg_restore -d "postgres://<dbusername>:<dbpassword>@<dbhost>:<dbport>/<new_dbname>" /var/db/openproject/backup/postgresql-dump-<TIMESTAMP>.pgdump` 
```

Example:

```bash
$ pg_restore -d "postgres://openproject:L0BuQvlagjmxdOl6785kqwsKnfCEx1dv@127.0.0.1:45432/openproject_backup" /var/db/openproject/backup/postgresql-dump-20191119210038.pgdump` 
```

That command will restore the contents of the backup file into the auxillary database.

## 2. Run the script to fix the database entries

The script that fixes the time entries can then be called:

```bash
$ BACKUP_DATABASE_URL="postgres://<dbusername>:<dbpassword>@<dbhost>:<dbport>/<new_dbname>" sudo openproject run bundle exec rails openproject:reassign_time_entry_activities
```

Example

```bash
$ BACKUP_DATABASE_URL="postgres://openproject:L0BuQvlagjmxdOl6785kqwsKnfCEx1dv@127.0.0.1:45432/openproject_backup" sudo openproject run bundle exec rails openproject:reassign_time_entry_activities
```

The script will then print out the number of time entries it has fixed.

```bash

Fixing 341 time entries.
Done.

```

## 3. Cleanup

The database containing the backup data can be removed once the script has finished (again, **ensure to reference the auxillary database for the drop command**):

```bash
$ psql "postgres://<dbusername>:<dbpassword>@<dbhost>:<dbport>/<dbname>" -c 'DROP DATABASE <new_dbname>'
DROP DATABASE
```

Example:

```bash
$ psql "postgres://openproject:L0BuQvlagjmxdOl6785kqwsKnfCEx1dv@127.0.0.1:45432/openproject" -c 'DROP DATABASE openproject_backup'
DROP DATABASE
```
