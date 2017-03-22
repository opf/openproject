# Backup your OpenProject installation

**Note:** this guide only applies if you've installed OpenProject using our DEB/RPM
packages.

We advise to backup your OpenProject installation regularly — especially before
upgrading to a newer version.

## What should be backed up

In general the following parts of your OpenProject installation should be backed up:

* Data stored in the database
* Configuration files
* Uploaded files (attachments)
* Repositories (typically subversion) if applicable

## How to backup

The DEB/RPM packages provide a backup tool which can be used to take a snaphsot
of the current OpenProject installation. This tool will create a backup of
all parts mentioned above. The backup tool is used by executing the following
command:

    sudo openproject run backup

The command will create backup files in the following location on your system

    /var/db/openproject/backup

The content of that directory should look very similar to the following:

```bash
root@test-packager-backup:/opt/openproject# ls -l /var/db/openproject/backup/
total 24
-rw-r----- 1 openproject openproject  117 Apr  8 09:55 attachments-20150408095521.tar.gz
-rw-r----- 1 openproject openproject  667 Apr  8 09:55 conf-20150408095521.tar.gz
-rw-r----- 1 openproject openproject 8298 Apr  8 09:55 mysql-dump-20150408095521.sql.gz
-rw-r----- 1 openproject openproject  116 Apr  8 09:55 svn-repositories-20150408095521.tar.gz
```

## How to restore

The backup created with the tool consists of four parts
which are all compressed using `gzip`. Except the MySQL database dump these parts
can be restored by decompressing the `*.tar.gz` files and copy the content to the
proper location. The command to untar and unzip the `*.tar.gz` files looks like
this (using sample file names from above):

```bash
tar vxfz attachments-20150408095521.tar.gz
```

To restore the MySQL dump it is recommended to use the `mysql` command line client.

First the dump has to be extracted (unzipped) and then restored. The command
used should look very similar to this:

```bash
zcat mysql-dump-20150408095521.sql.gz | mysql -u <dbuser> -h <dbhost> -p <dbname>
```

The `<dbuser>`, `<dbhost>` and `<dbname>` variables have to be replaced with
the values that are container in the `DATABASE_URL` setting of your
installation. This setting can be seen by running:

```bash
openproject config:get DATABASE_URL
#=> e.g.: mysql2://dbusername:dbpassword@dbhost:dbport/dbname
```

