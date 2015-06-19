# Backup Guide

We advice to backup your OpenProject installation regularly — especially before upgrading to a newer version.

## What should be backed up

In general the following parts of your OpenProject installation should be backed up:

* Data stored in the database
* Configuration files
* Uploaded files (attachments)
* Repositories (typically subversion) if applicable

## Backup via packager command line client

The packager installation provides a backup tool which can be used to take a snaphsot of the current OpenProject installation. It will create a backup of all parts mentioned above. The backup tool is used by executing the following command:

`openproject run backup`

for the _OpenProject Core Editon_ or a slighly different command if the
_OpenProject Community Edition_ is used (a `-ce` is prepended):

`openproject-ce run backup`

The command will create backup files in the following location:

`/var/db/openproject/backup` or `/var/db/openproject-ce/backup`
depending on the Edition used (as above `-ce` is used for Community Edition).

In detail the content of the directory should look very similar to the following:

```bash
root@test-packager-backup:/opt/openproject# ls -l /var/db/openproject/backup/
total 24
-rw-r----- 1 openproject openproject  117 Apr  8 09:55 attachments-20150408095521.tar.gz
-rw-r----- 1 openproject openproject  667 Apr  8 09:55 conf-20150408095521.tar.gz
-rw-r----- 1 openproject openproject 8298 Apr  8 09:55 mysql-dump-20150408095521.sql.gz
-rw-r----- 1 openproject openproject  116 Apr  8 09:55 svn-repositories-20150408095521.tar.gz
```

## Restore notice

The backup created via the packager command line client consists of four parts which are all zipped using `gzip`. Except the MySQL database dump these parts can be restored by untar/unzip the `*.tar.gzip` and copy the content to the proper location. The command to untar and unzip the
`*.tar.gz` files looks like this (using sample file names from above):

```bash
tar vxfz attachments-20150408095521.tar.gz
```

To restore the MySQL dump it is recommended to use the `mysql` comand line client.

First the dump has to be extracted (unzipped) and then restored. The command used should look very similar to this:

```bash
gzip -d mysql-dump-20150408095521.sql.gz
mysql -u <user> -h <host> -p <database> < mysql-dump-20150408095521.sql
```

The `<user>`, `<host>` and `<database>` variables have to be replaced with actual values.

