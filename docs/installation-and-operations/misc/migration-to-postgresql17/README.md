# Migrating your OpenProject installation to PostgreSQL 17

OpenProject version 16+ will default to PostgreSQL 17. If you have an existing OpenProject installation, please follow the guide below to upgrade your PostgreSQL version.  
For the time being, using an older Postgres version is still possible, but not recommended.  
This documentation shows how to upgrade PostgreSQL via a SQL dump.  
If you prefer doing the upgrade using the [in-place method](https://www.postgresql.org/docs/current/pgupgrade.html), you are free to do so.


## Docker Compose

> [!IMPORTANT]
> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/docker/).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

### 1. Backup the Current PostgreSQL Database

Create a backup of your current PostgreSQL database. Run the following command from your OpenProject project directory:

```bash
docker compose exec -it -u postgres db pg_dump -d openproject -x -O > openproject.sql
```

This creates a backup named `openproject.sql`. 

### 2. Stop OpenProject Services

Shut down all running containers:

```bash
docker compose down
```

### 3. Prepare for PostgreSQL 17

To upgrade to PostgreSQL 17, you need to override the default database image.

#### Create `docker-compose.override.yml`

Create a file named `docker-compose.override.yml` in the docker compose directory. 
Replace the default PostgreSQL version with 17. 
Also, define a new volume for the upgraded database to avoid overwriting the existing one.

Here’s an example configuration:

```yaml
volumes:
  pgdata17:

services:
  db:
    image: postgres:17
    volumes:
      - pgdata17:/var/lib/postgresql/data

```

### 4. Start the New Database Container

With your override file in place, start only the database container:

```bash
docker compose up db -d
```

This starts a clean PostgreSQL 17 container with an empty data directory.

### 5. Restore the Backup to PostgreSQL 17

Now that the new database is running, restore your backup:

```bash
docker compose exec -T -u postgres db psql -d openproject < openproject.sql
```

This will import your data into the new PostgreSQL 17 container.

### 6. Start the Full OpenProject Stack

With your data restored, bring up the rest of the OpenProject services:

```bash
docker compose up -d
```

### Confirmation

You now have OpenProject running with PostgreSQL 17. 
Verify everything works correctly by visiting your OpenProject instance in the browser.


## Docker All-in-One

> [!IMPORTANT]
> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/docker/#all-in-one-container).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

This only works if you are using OpenProject >= 16.2 because older versions have PostgreSQL 13 as the default database.

### 1. Backup the Existing Database


Create a PostgreSQL dump using:

```bash
docker exec -it $OP_CONTAINER_NAME su - postgres -c 'pg_dump -d openproject -x -O' > openproject.sql
```

This command connects to the running container and exports the database into a SQL file on your host machine.

### 2. Stop the OpenProject container

```bash
docker stop $OP_CONTAINER_NAME
```

### 3. Start a New PostgreSQL 17 Container

Run a fresh PostgreSQL 17 container using a new volume:

```bash
docker run --rm -d --name postgres \
-e POSTGRES_PASSWORD=postgres \
-e LANG=C.UTF-8 \
-e LC_ALL=C.UTF-8 \
-v /var/lib/openproject/pgdata17:/var/lib/postgresql/data \
postgres:17
```

### 4. Create OpenProject user

Connect to the new PostgreSQL 17 container and drop the `openproject` database:

```bash
echo "CREATE USER openproject WITH PASSWORD 'openproject';" | docker exec -i postgres psql -U postgres
```

### 5. Create a New Database

Now create a fresh `openproject` database:

```bash
echo "CREATE DATABASE openproject OWNER openproject;" | docker exec -i postgres psql -U postgres
```

### 6. Restore the Database from the Dump

Restore your data:

```bash
docker exec -i postgres psql -U openproject -d openproject < openproject.sql
```

This imports your backup into the newly created database.

### 7. Stop PostgreSQL container

```bash
docker stop postgres
```

### 8. Relaunch OpenProject with PostgreSQL 17

You can now run a new OpenProject container connected to your upgraded PostgreSQL 17 data volume:

```bash
docker run -d -p 8080:80 --name openproject \
  -e OPENPROJECT_HOST__NAME=openproject.example.com \
  -e SECRET_KEY_BASE=<your-secret-key-base> \
  -v /var/lib/openproject/pgdata17:/var/openproject/pgdata \
  -v /var/lib/openproject/assets:/var/openproject/assets \
  openproject/openproject:17
```

Make sure the environment variables and version match your setup.

### Confirmation

Visit your OpenProject instance to confirm everything works as expected.



## Package-Based Installation

> [!IMPORTANT]
> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/packaged/).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

### 1. Stop OpenProject

```bash
sudo service openproject stop
```

### 2. Backup the Database

```bash
pg_dump $(sudo openproject config:get DATABASE_URL) -x -O > openproject.sql
```

### 3. Stop Existing PostgreSQL

#### On Debian/Ubuntu:
```bash
sudo pg_ctlcluster 13 main stop
```

#### On CentOS/RHEL and SLES:
```bash
sudo systemctl stop postgresql-13
```

### 4. Install PostgreSQL 17

#### On Debian/Ubuntu:
```bash
sudo apt update
sudo apt install postgresql-17
sudo pg_createcluster 17 main --start
```

#### On CentOS/RHEL:
```bash
sudo dnf install -y postgresql17-server postgresql17-contrib
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable --now postgresql-17
```

#### On SLES:
```bash
TODO: sudo zypper addrepo https://download.postgresql.org/pub/repos/zypp/17/suse/sles-15.5-x86_64/ openSUSE-PostgreSQL-17
TODO: sudo zypper install --repo openSUSE-PostgreSQL-17 postgresql17 postgresql17-server  postgresql17-libs postgresql17-contrib
#TODO:? sudo su - postgres -c '/usr/lib/postgresql17/bin/initdb -D /var/lib/pgsql/17/data'
sudo systemctl enable postgresql
sudo systemctl start postgresql
```


### 5. Copy Configuration Files

#### On Debian/Ubuntu:
```bash
sudo su - postgres -c "cp /etc/postgresql/13/main/pg_hba.conf /etc/postgresql/17/main/pg_hba.conf"
sudo su - postgres -c "cp /etc/postgresql/13/main/conf.d/custom.conf /etc/postgresql/17/main/conf.d/custom.conf"
sudo pg_ctlcluster 17 main restart
```

#### On CentOS/RHEL:
```bash
sudo su - postgres -c "cp /var/lib/pgsql/13/data/pg_hba.conf /var/lib/pgsql/17/data/pg_hba.conf"
sudo su - postgres -c "cp -r /var/lib/pgsql/13/data/conf.d /var/lib/pgsql/17/data/"
sudo su - postgres -c "cp -r /var/lib/pgsql/13/data/postgresql.conf /var/lib/pgsql/17/data/postgresql.conf"
sudo service postgresql-17 restart
```

#### On SLES:
```bash
sudo su - postgres -c "cp /var/lib/pgsql/13/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf"
sudo su - postgres -c "cp -r /var/lib/pgsql/13/data/conf.d /var/lib/pgsql/data/"
sudo su - postgres -c "cp -r /var/lib/pgsql/13/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf"
sudo systemctl restart postgresql
```

### 6. Remove Old PostgreSQL 

#### On Debian/Ubuntu:
```bash
sudo apt remove --purge postgresql-13
```

#### On CentOS/RHEL:
```bash
sudo dnf remove postgresql13-server
```

#### On SLES:
```bash
sudo zypper remove postgresql13-server
```


### 7. Recreate the OpenProject User and Database

```bash
sudo su - postgres -c "psql -p 45432 -c \"create user openproject with password '$(sudo openproject config:get DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')'\""
sudo su - postgres -c "psql -p 45432 -c 'create database openproject owner openproject'"
```

### 8. Restore the Database

```bash
psql $(sudo openproject config:get DATABASE_URL) < openproject.sql
```


### 9. Restart OpenProject

```bash
sudo openproject restart
```

### Confirmation

Visit your OpenProject instance in the browser to confirm everything works as expected.


## Helm Chart installation

> Please follow this section only if you have installed OpenProject using [this procedure](../../installation/helm-chart/).
> Before attempting the upgrade, please ensure you have performed a backup of your installation by following the [backup guide](../../operation/backing-up/).

1. Stop your frontend or scale it down to 0 to prevent frontend changes.

2. Backup your database by entering the shell of the existing PostgreSQL pod:

```shell
kubectl exec -it <postgresql-pod-name> -- bash
```

Create a PostgreSQL dump of the database and save it to the persistent directory:

```shell
PGPASSWORD=$(cat "${POSTGRES_POSTGRES_PASSWORD_FILE:-/dev/null}" && echo "$POSTGRES_POSTGRES_PASSWORD") pg_dumpall -U postgres > /bitnami/postgresql/backup.sql
```

3. Prepare the Upgrade by renaming the current PostgreSQL data directory to ensure it is preserved in case of issues after the upgrade:

```shell
mv /bitnami/postgresql/data /bitnami/postgresql/data-old
```

4. Change the Bitnami PostgreSQL version by adding the following lines to you values.yaml.

```yaml
postgresql:
  image:
    tag: 17.5.0-debian-12-r16
```

5. Restore the Database:

After upgrading the Helm chart, enter the shell of the newly upgraded PostgreSQL pod:

```shell
kubectl exec -it <new-postgresql-pod-name> -- bash
```

Restore the backup by running the following command:

```shell
PGPASSWORD=$(cat "${POSTGRES_POSTGRES_PASSWORD_FILE:-/dev/null}" && echo "$POSTGRES_POSTGRES_PASSWORD") psql -U postgres -h localhost -f /bitnami/postgresql/backup.sql
```

6. Restore Frontend Availability by starting the frontend or scaling it up again.

7. Verify the Upgrade by ensuring everything is working as expected by checking that the PostgreSQL instance is running correctly and the frontend is accessible.

8. Remove Backup Files:

Once verified, enter the shell of the PostgreSQL pod again and remove the backup files to clean up:

```shell
rm /bitnami/postgresql/backup.sql
rm -r /bitnami/postgresql/data-old
```

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

Check `/var/lib/pgsql/17/data/pg_hba.conf` for any appearance of `scram-sha-256` and replace with `md5`

Check `/var/lib/pgsql/17/data/postgresql.conf` for any appearance of `scram-sha-256` and replace with `md5` (search for `encryption`)

Reload Configuration of PostgreSQL server with `systemctl reload postgresql-17`
