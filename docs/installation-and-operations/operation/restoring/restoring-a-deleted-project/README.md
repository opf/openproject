---
sidebar_navigation:
  title: Restoring a deleted project
  priority: 8
keywords: deleted project, restore, restoring
---

# Restoring a deleted project

Sometimes it may happen that you delete a project on accident.
Perhaps it would be too much trouble or more recent data lost to restore a complete backup.

For these kinds of cases we describe here how to restore a single project from a backup.
The following files will be used in the examples.

* [dump.sql](./dump.sql)
* [restore.sql](./restore.sql)

There is also a script ([restore.sh](./restore.sh)) that shows how to use everything together.

## 0. Prerequisites

* you have a Backup of your OpenProject installation with the missing data still present
* you have restored the database dump of this backup into a new, separate database called `openproject_backup`
  * Created, for instance, via
    * `psql -c 'create database openproject_backup'`
    * `pg_restore -d openproject_backup openproject.pgdump`
* your present OpenProject database is called `openproject`

It does not matter where the actual Postgres server is running.
In all the following examples we simply use `psql -d openproject_backup` and `psql -d openproject` respectively. Where `openproject_backup` and `openproject` are the names of the databases within Postgres.

In your case you may have to provide more options (e.g. the user or host) to connect to the respective database.

## 1. Dump project data from backup

First we copy the data from the backup, that was deleted later.
For each relevant table, a `missing_<table-name>` table is created
that only contains the missing data.

This is then saved to `missing_data.sql` which will be used to import
the missing data into the current database.

Before performing the next step, edit the `dump.sql` file and change the missing project ID
to the correct value in the head of the file where it says 'DEFINE MISSING PROJECT ID HERE'.

```shell
cat dump.sql | psql -d openproject_backup

pg_dump -d openproject_backup -t 'missing_*' -f missing_data.sql
```

## 2. Restore missing data

Now that we have the missing data, we can restore it in the current database.

```shell
cat missing_data.sql | psql -d openproject
cat restore.sql | psql -d openproject
```

First we create the tables with the missing data in the current database.
This has no effect on the actual data of OpenProject yet.
Only with executing `restore.sql` will the data be copied from the `missing_<table-name>` tables
into the corresponding actual `<table-name>` tables.

After this is done, the `missing_*` tables are dropped.
This all happens within a transaction.

**Project hierarchy**

Now it can happen that the project hierarchy does not look correct in the projects dropdown after
you restored a deleted project. To fix this, delete the restored project's `lft` and `rgt` columns
and rebuild the hierarchy.

To do this, start an OpenProject console (e.g. `sudo openproject run console`) and execute the following.

```ruby
p = Project.find_by(name: "Restored project")

p.update_column :lft, nil
p.update_column :rgt, nil

Project.rebuild!
```

This may take a moment depending on the number of projects you have.
After this is finished, the project hierarchy will look correct again.

This operation is perfectly safe and will not affect any actual data.
It just affects the display of projects in the projects dropdown and projects list.
