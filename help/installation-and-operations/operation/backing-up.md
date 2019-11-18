---
sidebar_navigation:
  title: Backing up
  priority: 600
---

# Backing up your OpenProject installation

We advise to backup your OpenProject installation regularly — especially before upgrading to a newer version.

## What should be backed up

In general the following parts of your OpenProject installation should be backed up:

- Data stored in the database
- Configuration files
- Uploaded files (attachments)
- Repositories (typically subversion) if applicable

## Packaged installation (DEB/RPM)

The DEB/RPM packages provide a backup tool which can be used to take a snaphsot
of the current OpenProject installation. This tool will create a backup of
all parts mentioned above. The backup tool is used by executing the following
command:

```
sudo openproject run backup
```

The command will create backup files in the following location on your system:

```
/var/db/openproject/backup
```

The content of that directory should look very similar to the following (depending on your database engine, you will see either a `mysql-dump-<date>.sql.gz` or a `postgresql-dump-<pgdump>` file).

```
root@test-packager-backup:/opt/openproject# ls -l /var/db/openproject/backup/
total 24
-rw-r----- 1 openproject openproject  117 Apr  8 09:55 attachments-20150408095521.tar.gz
-rw-r----- 1 openproject openproject  667 Apr  8 09:55 conf-20150408095521.tar.gz
-rw-r----- 1 openproject openproject 8298 Apr  8 09:55 postgres-dump-20150408095521.sql.gz
-rw-r----- 1 openproject openproject  116 Apr  8 09:55 svn-repositories-20150408095521.tar.gz
```

You should then copy those dump files to a secure location, for instance an S3 bucket or some sort of backup server.
