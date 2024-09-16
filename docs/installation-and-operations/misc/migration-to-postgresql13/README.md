# Migrating your OpenProject installation to PostgreSQL 13

OpenProject version 12+ will default to PostgreSQL 13. If you have an existing OpenProject installation, please follow the guide below to upgrade your PostgreSQL version.

## Package-based installation

> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/packaged/).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

Please first check whether this guide applies to you at all. Only PostgreSQL installations that were installed by the OpenProject package are applicable to this guide.

To do that, please run the following command:

```shell
sudo cat /etc/openproject/installer.dat | grep postgres/autoinstall
```

And verify that it outputs: postgres/autoinstall **install**.

If that is not the case, you are likely using a self-provisioned database or a remote database. In this case, please follow the instructions from your provider or use generic PostgreSQL upgrade guides. A guide we can recommend for Debian/Ubuntu based servers is [this one](https://gorails.com/guides/upgrading-postgresql-version-on-ubuntu-server). Please adapt that guide or the following steps to your distribution.

In the following, we assume that you initially let OpenProject setup your PostgreSQL installation, using a local database.

NOTE: RedHat and CentOS are slightly different, depending on which PostgreSQL package/repository will be used.
For the documentation parts titled RedHat/CentOS RedHat Enterprise Linux 8 was used.

1. First, connect to your server and make sure your local version is PostgreSQL v10:

For Debian/Ubuntu:

```shell
sudo cat /var/lib/postgresql/10/main/PG_VERSION
10
```

For RedHat/CentOS:

```shell
sudo cat /var/lib/pgsql/10/data/PG_VERSION 
10
```

2. Install the new version of PostgreSQL:

For Debian/Ubuntu:

```shell
sudo apt-get update
sudo apt-get install postgresql-13
```

For RedHat/CentOS:

```shell
sudo yum install pgsql13
sudo /usr/bin/postgresql-13-setup initdb
```

3. Stop the PostgreSQL servers:

For Debian/Ubuntu:

```shell
sudo su - postgres -c "/usr/lib/postgresql/10/bin/pg_ctl stop --wait --pgdata=/var/lib/postgresql/10/main"
sudo su - postgres -c "/usr/lib/postgresql/13/bin/pg_ctl stop --wait --pgdata=/var/lib/postgresql/13/main"
```

For RedHat/CentOS:

```shell
sudo su - postgres -c "/usr/pgsql-10/bin/pg_ctl stop --wait --pgdata=/var/lib/pgsql/10/data"
sudo su - postgres -c "/usr/pgsql-13/bin/pg_ctl stop --wait --pgdata=/var/lib/pgsql/13/data"
```

4. Migrate your data to PostgreSQL 13:

For Debian/Ubuntu:

```shell
sudo su - postgres <<CMD
/usr/lib/postgresql/13/bin/pg_upgrade \
  --old-bindir=/usr/lib/postgresql/10/bin \
  --new-bindir=/usr/lib/postgresql/13/bin \
  --old-datadir=/var/lib/postgresql/10/main \
  --new-datadir=/var/lib/postgresql/13/main \
  --old-options '-c config_file=/etc/postgresql/10/main/postgresql.conf' \
  --new-options '-c config_file=/etc/postgresql/13/main/postgresql.conf'
CMD
```

For RedHat/CentOS:

```shell
sudo su - postgres <<CMD
/usr/pgsql-13/bin/pg_upgrade \
  --old-bindir=/usr/pgsql-10/bin \
  --new-bindir=/usr/pgsql-13/bin \
  --old-datadir=/var/lib/pgsql/10/data \
  --new-datadir=/var/lib/pgsql/13/data \
  --old-options '-c config_file=/var/lib/pgsql/10/data/postgresql.conf' \
  --new-options '-c config_file=/var/lib/pgsql/13/data/postgresql.conf'
CMD
```

5. Make PostgreSQL v13 the new default server to run on port 45432:

For Debian/Ubuntu:

```shell
sudo su - postgres -c "cp /etc/postgresql/{10,13}/main/conf.d/custom.conf"
sudo su - postgres -c "sed -i 's|45432|45433|' /etc/postgresql/10/main/conf.d/custom.conf"
sudo su - postgres -c "/usr/lib/postgresql/13/bin/pg_ctl start --wait --pgdata=/var/lib/postgresql/13/main -o '-c config_file=/etc/postgresql/13/main/postgresql.conf'"
```

For RedHat/CentOS:

```shell
sudo su - postgres -c "mkdir -p /var/lib/pgsql/13/data/conf.d"

sudo su - postgres -c "vi /var/lib/pgsql/13/data/postgresql.conf"
# at the section CONFIG FILE INCLUDES, please add the include directory conf.d
include_dir = 'conf.d'

sudo su - postgres -c "cp -p /var/lib/pgsql/10/data/conf.d/custom.conf /var/lib/pgsql/13/data/conf.d/custom.conf"
sudo su - postgres -c "sed -i 's|45432|45433|' /var/lib/pgsql/10/data/conf.d/custom.conf"
sudo su - postgres -c "/usr/pgsql-13/bin/pg_ctl start --wait --pgdata=/var/lib/pgsql/13/data -o '-c config_file=/etc/postgresql/13/main/postgresql.conf'"

# Getting the password for the PostgreSQL database from the configuration
sudo openproject config:get DATABASE_URL
postgres://openproject:[CRYPTICAL-PASSWORD-STRING]@127.0.0.1:45432/openproject

# Alter the password for user openproject in pgsql13
[root@openproject ~]# su - postgres
[postgres@openproject ~]$ psql --port 45432
psql (13.6)
Type "help" for help.
postgres=# ALTER USER openproject WITH PASSWORD '[CRYPTICAL-PASSWORD-STRING]';
ALTER ROLE
postgres=# \q
[postgres@openproject ~]$ logout
```

6. Check your OpenProject installation on the GUI. A version higher than `13.0` should be displayed for `PostgreSQL version` in the "Administration > Information" section.

7. If everything is fine, you can then remove your older PostgreSQL installation:

For Debian/Ubuntu:

```shell
sudo rm -rf /var/lib/postgresql/10/main
sudo apt-get purge postgresql-10
```

For RedHat/CentOS:

```shell
sudo rm -rf /var/lib/pgsql/10/data
sudo yum remove pgsql10
```

## Compose-based docker installation

> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/docker/).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

You can find the upgrade instructions for your docker-compose setup in the [openproject-deploy](https://github.com/opf/openproject-deploy/blob/stable/14/compose/control/README.md#upgrade) repository.

Remember that you need to have checked out that repository and work in the `compose` directory for the instructions to work.

## All-in-one docker installation

> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/docker/#all-in-one-container).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

The newer version of OpenProject includes an utility to automatically perform the upgrade for you. Assuming you followed the standard installation procedure, the folder (within the docker container) containing your PostgreSQL data will be located at `/var/openproject/pgdata`.

Then the goal is to take this folder, and apply `pg_upgrade` on it. This will generate an upgraded cluster in another folder. We can finally switch the old postgres folder with the upgraded one and restart the container.

First, ensure that you have stopped your container:

```shell
docker stop openproject
```

Once the docker has stopped, you are ready to run the upgrade command. In this case, we assume that your existing PostgreSQL data is stored on the host at `/var/lib/openproject/pgdata`. We will also map a local folder named `/var/lib/openproject/pgdata-next` to a special volume in the container, named `/var/openproject/pgdata-next`. This volume will contain the upgraded cluster:

```shell
docker run --rm -it \
  -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
  -v /var/lib/openproject/pgdata-next:/var/openproject/pgdata-next \
  openproject/openproject:14 root ./docker/prod/postgres-db-upgrade
```

If everything goes well, the process should end with a message as follows:

```text
Upgrade Complete                                              
----------------                                              
Optimizer statistics are not transferred by pg_upgrade so,                  
once you start the new server, consider running:
    ./analyze_new_cluster.sh                                
                                         
Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh            
```

You can then perform the following operation to switch the upgraded PostgreSQL with the older version:

```shell
sudo mv /var/lib/openproject/pgdata /var/lib/openproject/pgdata-prev
sudo mv /var/lib/openproject/pgdata-next /var/lib/openproject/pgdata
```

Finally, you can restart OpenProject with the same command that you used before. For instance:

docker run -d -p 8080:80 --name openproject -e SECRET_KEY_BASE=secret \
  -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
  -v /var/lib/openproject/assets:/var/openproject/assets \
  [...]
  openproject/openproject:14

If your new installation looks fine, you can then choose to remove `/var/lib/openproject/pgdata-prev`:

```shell
sudo rm -rf /var/lib/openproject/pgdata-prev
```

If you encounter an issue, you can switch back to the previous PostgreSQL folder by reverting the folder switch:

```shell
sudo mv /var/lib/openproject/pgdata /var/lib/openproject/pgdata-next
sudo mv /var/lib/openproject/pgdata-prev /var/lib/openproject/pgdata
```

And then restart OpenProject.

## Upgrade table query plans after the upgrade

After an upgrade of PostgreSQL, we strongly recommend running the following SQL command to ensure query plans are regenerated as this doesn't necessarily happen automatically.

For that, open a database console. On a packaged installation, this is the way to do it:

```shell
psql $(openproject config:get DATABASE_URL)
```

Please change the command appropriately for other installation methods. Once connected, run the following command

```sql
ANALYZE VERBOSE;
```

## Troubleshooting

> User "openproject" does not have a valid SCRAM secret - psql: error: FATAL: password authentication failed for user "openproject"

Check `/var/lib/pgsql/13/data/pg_hba.conf` for any appearance of `scram-sha-256` and replace with `md5`

Check `/var/lib/pgsql/13/data/postgresql.conf` for any appearance of `scram-sha-256` and replace with `md5` (search for `encryption`)

Reload Configuration of PostgreSQL server with `systemctl reload postgresql-13`
