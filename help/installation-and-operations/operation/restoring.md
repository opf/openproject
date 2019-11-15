---
sidebar_navigation:
  title: Restoring
  priority: 500
---

# Restoring an OpenProject backup

## Packaged installation (DEB/RPM)

Assuming you have a backup of all the OpenProject files at hand (see the [Backing up](../backing-up) guide), here is how you would restore your OpenProject installation from that backup.

As a reference, we will assume you have the following dumps on your server, located in `/var/db/openproject/backup`:

```
-rw-r----- 1 openproject openproject  117 Apr  8 09:55 attachments-20150408095521.tar.gz
-rw-r----- 1 openproject openproject  667 Apr  8 09:55 conf-20150408095521.tar.gz
-rw-r----- 1 openproject openproject 8298 Apr  8 09:55 postgres-dump-20150408095521.sql.gz
-rw-r----- 1 openproject openproject  116 Apr  8 09:55 svn-repositories-20150408095521.tar.gz
```

### Stop the processes

First, it is a good idea to stop the OpenProject instance:

```
sudo service openproject stop
```

### Restoring assets

Untar the attachments to their destination:

```
tar xzf /var/db/openproject/backup/attachments-20150408095521.tar.gz -C /var/db/openproject/files/
```

Untar the configuration to its destination:

```
tar xzf /var/db/openproject/backup/conf-20150408095521.tar.gz -C /etc/openproject/
```

Untar the repositories to their destination:

```
tar xzf /var/db/openproject/backup/svn-repositories-20150408095521.tar.gz -C /var/db/openproject/repositories
```

### Restoring the database

Note: in this section, the `<dbusername>`, `<dbhost>` and `<dbname>` variables that appear below have to be replaced with
the values that are contained in the `DATABASE_URL` setting of your
installation. This setting can be seen by running:

First, get the necessary details about your database:

```
openproject config:get DATABASE_URL
#=> e.g.: postgres://dbusername:dppassword@dbhost:dbport/dbname
```

Then, to restore the PostgreSQL dump please use the `psql` command utilities:

```
zcat /var/db/openproject/backup/postgres-dump-20150408095521.sql.gz | psql -h <dbhost> -u <dbusername> -W <dbname>
```

### Restart the OpenProject processes

Finally, restart all your processes as follows:

```
sudo service openproject restart
```
