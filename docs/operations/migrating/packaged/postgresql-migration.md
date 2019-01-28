# Migrating your packaged OpenProject database to PostgreSQL

**Note:** this guide only applies if you've installed OpenProject using our DEB/RPM packages.

This guide will migrate your packaged MySQL installation to a PostgreSQL installation using [pgloader](https://github.com/dimitri/pgloader). 

## Backing up

Before beginning the migration, please ensure you have created a backup of your current installation. Please follow our [backup and restore documentation](https://www.openproject.org/operations/backup/backup-guide-packaged-installation/) for our packaged installation.

This guide should leave you with a set of archives that you should manually move to your new environment:

- **Database**: mysql-dump-\<timestamp>.sql.gz
- **Attachments**: attachments-\<timestamp>.tar.gz
- **Custom env configuration**: conf-\<timestamp>.tar.gz
- **Repositories**: svn- and git-\<timestamp>.tar.gz



## Installation of pgloader



### Apt Systems

For systems with APT package managers (Debian, Ubuntu), you should already have `pgloader` available and can install as root with with:

```
[root@host] apt-get install pgloader
```



[For other installations, please see the project page itself for steps on installing with Docker or from source](https://github.com/dimitri/pgloader#install).



After installation, check that pgloader is in your path and accessible:



```
[root@host] pgloader --version

# Should output something of the kind
pgloader version "3.5.2"
compiled with SBCL 1.4.5.debian
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
[postgres@host] createuser -W openproject
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

## Remember the current database URL

Note down or copy the current MySQL `DATABASE_URL`. The following command exports it to the curent shell as `MYSQL_DATABASE_URL`:

```bash
openproject config:get DATABASE_URL

# Will output something of the kind
# mysql2://user:password@localhost:3306/dbname

# Re-export but replace mysql2 with mysql!
export MYSQL_DATABSAE_URL="mysql://user:password@localhost:3306/dbname"
```



**Please note:** Ensure that the URL starts with `mysql://` , not with ` mysql2://` !



## Configuring OpenProject to use the PostgreSQL database

Form the `DATABASE_URL` string to match your entered password and pass it to the openproject configuration. The following command also exports it to the current shell as `POSTGRES_DATABASE_URL`

```bash
openproject config:set DATABASE_URL="postgresql://openproject:<PASSWORD>@localhost/openproject"
export POSTGRES_DATABASE_URL="postgresql://openproject:<PASSWORD>@localhost/openproject"
```



**Please note:**  Replace  `<PASSWORD>`  with the password you provided above. If you used any special characters, [check whether they need to be percent-encoded](https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding) for the database URL.



## Migrating the databases

You are now ready to use `pgloader`. You simply point it the old and new database URL

```bash
pgloader --verbose $MYSQL_DATABASE_URL $POSTGRES_DATABASE_URL
```



This might take a while depending on current installation size.



## Optional: Uninstall MySQL

If you let the packaged installation auto-install MySQL before and no longer need it, you can remove MySQL packages. 

```
[root@host] apt-get remove mysql-client mysql-server mysql-common
```

You can check the output of `dpkg - l | grep mysql` to check for additional packages removable. Only keep `libmysqlclient-dev`  for Ruby dependencies on the mysql adapter.





## Running openproject reconfigure

After you restored all data and updated your installer.dat, all you need to do is run through the configuration process of the packaged installation to remove the MySQL configuration

```bash
openproject reconfigure
```



In the MySQL installation screen, select `skip` now. Keep all other values the same by simply confirming them by pressing  `enter` .



After the configuration process has run through , your database will be running on PostgreSQL!