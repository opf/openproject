# Migrating your packaged OpenProject database to PostgreSQL

**Note:** this guide only applies if you've installed OpenProject using our DEB/RPM packages.

This guide will migrate your packaged MySQL installation to a PostgreSQL installation using [pgloader](https://github.com/dimitri/pgloader). 

## Backing up

Before beginning the migration, please ensure you have created a backup of your current installation. Please follow our [backup and restore guides](../../operation).

This guide should leave you with a set of archives that you can use to restore, should the migration end up in an unstable state:

- **Database**: mysql-dump-&lt;timestamp&gt;.sql.gz
- **Attachments**: attachments-&lt;timestamp&gt;.tar.gz
- **Custom env configuration**: conf-&lt;timestamp&gt;.tar.gz
- **Repositories**: svn- and git-&lt;timestamp&gt;.tar.gz


## Installation of pgloader

We ship a custom version of pgloader (named `pgloader-ccl`), which embeds some memory optimizations useful when you are migrating from a large MySQL database. This also allows us to provide a unified migration experience for all installation types. This package is available for all the currently supported distributions at https://packager.io/gh/opf/pgloader-ccl.

### Ubuntu 18.04

```
wget -qO- https://dl.packager.io/srv/opf/pgloader-ccl/key | sudo apt-key add -
sudo wget -O /etc/apt/sources.list.d/pgloader-ccl.list \
  https://dl.packager.io/srv/opf/pgloader-ccl/master/installer/ubuntu/18.04.repo
sudo apt-get update
sudo apt-get install pgloader-ccl
```

### Ubuntu 16.04

```
wget -qO- https://dl.packager.io/srv/opf/pgloader-ccl/key | sudo apt-key add -
sudo wget -O /etc/apt/sources.list.d/pgloader-ccl.list \
  https://dl.packager.io/srv/opf/pgloader-ccl/master/installer/ubuntu/16.04.repo
sudo apt-get update
sudo apt-get install pgloader-ccl
```

### Debian 9

```
wget -qO- https://dl.packager.io/srv/opf/pgloader-ccl/key | sudo apt-key add -
sudo wget -O /etc/apt/sources.list.d/pgloader-ccl.list \
  https://dl.packager.io/srv/opf/pgloader-ccl/master/installer/debian/9.repo
sudo apt-get update
sudo apt-get install pgloader-ccl
```

### CentOS / RHEL 7

```
sudo wget -O /etc/yum.repos.d/pgloader-ccl.repo \
  https://dl.packager.io/srv/opf/pgloader-ccl/master/installer/el/7.repo
sudo yum install pgloader-ccl
```

### SuSE Enterprise Linux 12

```
sudo wget -O /etc/zypp/repos.d/pgloader-ccl.repo \
  https://dl.packager.io/srv/opf/pgloader-ccl/master/installer/sles/12.repo
sudo zypper install pgloader-ccl
```

## Optional: Install and create PostgreSQL database

If you have not yet installed and set up a PostgreSQL installation database, please set up a PostgreSQL database now. 

OpenProject requires at least PostgreSQL 9.5 installed. Please check <https://www.postgresql.org/download/> if your distributed package is too old.

```bash
[root@host] apt-get install postgresql postgresql-contrib libpq-dev
```

Once installed, switch to the PostgreSQL system user.

```bash
[root@host] su - postgres
```

Then, as the PostgreSQL user, create the system user for OpenProject. This will prompt you for a password. We are going to assume in the following guide that password were 'openproject'. Of course, please choose a strong password and replace the values in the following guide with it!

```bash
[postgres@host] createuser -P -d openproject
```

Next, create the database owned by the new user

```bash
[postgres@host] createdb -O openproject openproject
```

Lastly, exit the system user

```bash
[postgres@host] exit
# You will be root again now.
```

## Set the MYSQL_DATABASE_URL to migrate from

The following command saves the current MySQL `DATABASE_URL` as `MYSQL_DATABASE_URL` in the OpenProject configuration:

```bash
openproject config:set MYSQL_DATABASE_URL="$(openproject config:get DATABASE_URL)"
openproject config:get MYSQL_DATABASE_URL

# Will output something of the kind
# mysql2://user:password@localhost:3306/dbname
```

This will be used later by the migration script.

## Configuring OpenProject to use the PostgreSQL database

Form the `DATABASE_URL` string to match your selected password and add it to the openproject configuration:

```bash
openproject config:set DATABASE_URL="postgresql://openproject:<PASSWORD>@localhost/openproject"
```


**Please note:**  Replace  `<PASSWORD>`  with the password you provided above. If you used any special characters, [check whether they need to be percent-encoded](https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding) for the database URL.

You can use this command to escape any characters in the password:

```bash
openproject run ruby -r cgi -e "puts CGI.escape('your-password-here');"
```


## Migrating the database

You are now ready to migrate from MySQL to PostgreSQL. The OpenProject packages embed a migration script that can be launched as follows:

```
sudo openproject run ./docker/mysql-to-postgres/bin/migrate-mysql-to-postgres
```

This might take a while depending on current installation size.

## Optional: Uninstall MySQL

If the packaged installation auto-installed MySQL before and you no longer need it (i.e. only OpenProject used a MySQL database on your server), you can remove the MySQL packages. 

You can check the output of `dpkg -l | grep mysql` to check for packages to be removed. Only keep `libmysqlclient-dev`  for Ruby dependencies on the mysql adapter.

The following is an exemplary removal of an installed version MySQL 5.7. 

```
[root@host] apt-get remove mysql-server
[root@host] openproject config:unset MYSQL_DATABASE_URL
```

**Note:** OpenProject still depends on `mysql-common` and other dev libraries of MySQL to build the `mysql2` gem for talking to MySQL databases. Depending on what packages you try to uninstall, `openproject` will be listed as a dependent package to be uninstalled if trying to uninstall `mysql-common`. Be careful here with the confirmation of removal, because it might just remove openproject itself due to the apt dependency management.


## Running openproject reconfigure

After you migrated your data, all you need to do is run through the configuration process of the packaged installation to remove the MySQL configuration

```bash
openproject reconfigure
```


In the database installation screen, make sure to select `skip`.
Keep all other values the same by simply confirming them by pressing `enter` .


After the configuration process has run through, your OpenProject installation will be running on PostgreSQL!
