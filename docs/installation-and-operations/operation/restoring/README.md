---
sidebar_navigation:
  title: Restoring
  priority: 8
---

# Restoring an OpenProject backup

## Package-based installation (DEB/RPM)

Assuming you have a backup of all the OpenProject files at hand (see the [Backing up](../backing-up) guide), here is how you would restore your OpenProject installation from that backup.

As a reference, we will assume you have the following dumps on your server, located in `/var/db/openproject/backup`:

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

### Stop the processes

First, it is a good idea to stop the OpenProject instance:

```bash
sudo service openproject stop
```

### Restoring assets

Go into the backup directory:

```bash
cd /var/db/openproject/backup
```

Untar the attachments to their destination:

```bash
tar xzf attachments-20191119210038.tar.gz -C /var/db/openproject/files
```

Untar the configuration files to their destination:

```bash
tar xzf conf-20191119210038.tar.gz -C /etc/openproject/conf.d/
```

Untar the repositories to their destination:

```bash
tar xzf git-repositories-20191119210038.tar.gz -C /var/db/openproject/git
tar xzf svn-repositories-20191119210038.tar.gz -C /var/db/openproject/svn
```

### Restoring the database

Note: in this section, the `<dbusername>`, `<dbhost>` and `<dbname>` variables that appear below have to be replaced with
the values that are contained in the `DATABASE_URL` setting of your
installation. 

First, get the necessary details about your database:

```bash
openproject config:get DATABASE_URL
#=> e.g.: postgres://<dbusername>:<dbpassword>@<dbhost>:<dbport>/<dbname>
```

Then, to restore the PostgreSQL dump please use the `pg_restore` command utility:

```bash
pg_restore -h <dbhost> -p <dbport> -U <dbusername> -d <dbname> postgresql-dump-20191119210038.pgdump
```

Example:

```bash
$ openproject config:get DATABASE_URL
postgres://openproject:L0BuQvlagjmxdOl6785kqwsKnfCEx1dv@127.0.0.1:45432/openproject

$ pg_restore -h 127.0.0.1 -p 45432 -U openproject -d openproject postgresql-dump-20191119210038.pgdump
```

### Restart the OpenProject processes

Finally, restart all your processes as follows:

```bash
sudo service openproject restart
```

## Docker-based installation

For Docker-based installations, assuming you have a backup as per the procedure described in the [Backing up](../backing-up) guide, you simply need to restore files into the correct folders (when using the all-in-one container), or restore the docker volumes (when using the Compose file), then start OpenProject using the normal docker or docker-compose command.
