# Migrating your packaged OpenProject database to Docker

This guide describes how to transition from a packaged based OpenProject database to Docker container environment. 

Please note that we will no longer provide package resources for future LTS versions of the distributions we currently support. This will likely become more relevant when ubuntu 22.04. approaches EOL. 

## Step 1: Backing up you packaged installation

To prevent data loss it is mandatory to backup your current OpenProject instance and save the backup file in a secure space. You can find how to back up your packaged installation in the [following guide](../../operation/backing-up/#package-based-installation-debrpm). 

Please ensure that you also create an SQL backup of your database, as there have been instances where binary backups could not be restored on a new PostgreSQL version. You can do so with the help of this command:

```shell
pg_dump $(sudo openproject config:get DATABASE_URL) -x -O > openproject.sql 
```

## Step 2: Install OpenProject in docker or docker compose

Follow the steps in our [Docker Installation guide](../../installation/docker/). Here you will find the all-in-one container solution and a one-container-per-process setup. We recommend using the latter.

You can also choose docker compose as a preferred installation method. Follow [this guide](../../installation/docker-compose/).

## Step 3: Restore your packaged installations backup in the new docker environment

Once the installation is complete and you can access the frontend of your new OpenProject instance, proceed to restore the backup created in Step 1. Refer to our [Backup Restoring Guide](../../operation/restoring/#3-restore-the-dump) for a detailed section on importing backups from a package-based installation.

## Step 4: Test your OpenProject Docker instance

After completing the steps above, it is essential that you review the restored data in the new instance. Check your projects and work packages, particularly attachments, to ensure everything is accessible and functions as it did before.
