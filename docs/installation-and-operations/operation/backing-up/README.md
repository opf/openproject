---
sidebar_navigation:
  title: Backing up
  priority: 9
---

# Backing up your OpenProject installation

We advise to backup your OpenProject installation regularly — especially before upgrading to a newer version.

## What should be backed up

In general the following parts of your OpenProject installation should be backed up:

- Data stored in the database
- Configuration files
- Uploaded files (attachments)
- Repositories (subversion, git) if applicable

## Package-based installation (DEB/RPM)

The DEB/RPM packages provide a backup tool which can be used to take a snapshot
of the current OpenProject installation. This tool will create a backup of
all parts mentioned above. The backup tool is invoked by executing the following
command:

```bash
sudo openproject run backup
```

The command will create backup files in the following location on your system:

```bash
/var/db/openproject/backup
```

The content of that directory should look very similar to the following.

```bash
root@ip-10-0-0-228:/home/admin# ls -al /var/db/openproject/backup/
total 1680
drwxr-xr-x 2 openproject openproject    4096 Nov 19 21:00 .
drwxr-xr-x 6 openproject openproject    4096 Nov 19 21:00 ..
-rw-r----- 1 openproject openproject 1361994 Nov 19 21:00 attachments-20191119210038.tar.gz
-rw-r----- 1 openproject openproject    1060 Nov 19 21:00 conf-20191119210038.tar.gz
-rw-r----- 1 openproject openproject     126 Nov 19 21:00 git-repositories-20191119210038.tar.gz
-rw-r----- 1 openproject openproject  332170 Nov 19 21:00 postgresql-dump-20191119210038.pgdump
-rw-r----- 1 openproject openproject     112 Nov 19 21:00 svn-repositories-20191119210038.tar.gz
```

You should then copy those dump files to a secure location, for instance an S3 bucket or some sort of backup server.

## Docker-based installation

If you are using docker-compose, then the data volumes are managed by Docker and you should have a look at the [official Docker documentation](https://docs.docker.com/storage/volumes/) for instructions on how to backup.

If you are using the all-in-one container, then you can simply backup any local volumes that you chose to bind-mount with the `-v` option when launching the container. For instance if you launched the container with:

```bash
sudo mkdir -p /var/lib/openproject/{pgdata,logs,static}

docker run -d -p 8080:80 --name openproject -e SECRET_KEY_BASE=secret \
  -v /var/lib/openproject/pgdata:/var/lib/postgresql/9.6/main \
  -v /var/lib/openproject/logs:/var/log/supervisor \
  -v /var/lib/openproject/static:/var/db/openproject \
  openproject/community:10
```

Then you would need to backup the `/var/lib/openproject` folder (for instance to S3 or FTP server).
