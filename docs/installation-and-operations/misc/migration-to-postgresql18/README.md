---
sidebar_navigation:
  title: Migrating to PostgreSQL 18
---

# Migrating your OpenProject installation to PostgreSQL 18

OpenProject 18.0 defaults to PostgreSQL 18 in new packaged, all-in-one (AIO), and Docker Compose installations. The database packages and images include pgvector; OpenProject handles extension creation during application migrations. Existing databases are not upgraded automatically, and OpenProject does not require pgvector for an application update.

A PostgreSQL major upgrade requires dump/restore or `pg_upgrade`. Changing an image tag does not upgrade database files.

Before starting, [back up your installation](../../operation/backing-up/), including attachments and configuration. Schedule downtime and stop all application writers before the final database dump. Keep the original database and a copy of the previous deployment configuration until verification succeeds. Do not delete volumes with `docker compose down -v`.

## Staying on your current PostgreSQL version

### AIO

Set `PGVERSION=17` when starting an AIO container with PostgreSQL 17 data. OpenProject 18 bundles PostgreSQL 17 and 18. For PostgreSQL 13 or 15, keep your previous OpenProject image until you migrate using dump/restore.

AIO now exits with an error if its configured PostgreSQL version differs from the existing data. It no longer selects the older version automatically. External databases are unaffected.

### Docker Compose

Keep the existing PostgreSQL image and data mount together. With the new Compose file, create `docker-compose.override.yml` containing:

```yaml
services:
  db:
    image: postgres:17
    volumes: !override
      - "${PGDATA:-pgdata}:/var/lib/postgresql/data"
```

Also set `POSTGRES_VERSION=17` in `.env`. The explicit image above preserves the original image family. The `!override` tag requires Docker Compose 2.24.4 or newer and replaces the entire volume list; without it, Compose could retain both old and new mount targets.

For development Compose, use `pgdata` as the source for `db` and apply the same override to `db-test` with source `pgdata-test`.

If you deliberately switch an existing PostgreSQL 17 deployment to pgvector, use `pgvector/pgvector:pg17-bookworm` with the same PostgreSQL 17 mount target. Back up first, check locale/collation compatibility, and follow the pgvector instructions below. Selecting `POSTGRES_VERSION=17` alone does not restore the old mount layout.

### Packaged installations

Existing configured installations retain their current database server. Running `openproject configure` does not install PostgreSQL 18 over an existing managed database. To create a new installation using PostgreSQL 17, install it yourself and choose to reuse an existing database in the wizard.

### Helm

Do not substitute a `pgvector/pgvector` image into the existing Bitnami subchart: its startup scripts, paths, and environment variables differ.

Before updating a chart, pin `postgresql.image.repository` and `postgresql.image.tag` to the image you currently use. For PostgreSQL 17, pin the complete PostgreSQL 17 tag from your deployment, rather than assuming the tag is simply `17`. The current legacy chart defaults to PostgreSQL 15; those installations must retain their actual PostgreSQL 15 image until migrated.

## Docker Compose upgrade

These instructions apply to `opf/openproject-docker-compose`. Run the dump with your **old** Compose configuration first.

1. Stop every service except the database. This stops web requests, workers, scheduled tasks, and collaborative editing:

   ```shell
   docker compose stop
   docker compose up -d db
   ```

2. Dump the database after `pg_isready` reports that it is accepting connections:

   ```shell
   docker compose exec -T db sh -c 'pg_isready -U "${POSTGRES_USER:-postgres}" -d "$POSTGRES_DB"'
   docker compose exec -T db sh -c 'pg_dump -U "${POSTGRES_USER:-postgres}" -d "$POSTGRES_DB" --no-owner --no-privileges' > openproject.sql
   docker compose down
   ```

   The default database is `openproject`. Adjust the user and database for customized installations. Store the dump securely.

3. Update to the new Compose files. Set `POSTGRES_VERSION=18` and choose a **new, empty** host directory in `.env`, for example:

   ```dotenv
   POSTGRES_VERSION=18
   PGDATA=/var/lib/openproject/pgdata18
   ```

   Remove any PostgreSQL 17 override. The new image is `pgvector/pgvector:pg18-bookworm`, and its volume is mounted at `/var/lib/postgresql`. The actual cluster resides in `18/docker` beneath that mount. Do not point this at your old data directory.

4. Start only the database and wait for readiness:

   ```shell
   docker compose up -d db
   docker compose exec -T db sh -c 'pg_isready -U "${POSTGRES_USER:-postgres}" -d "$POSTGRES_DB"'
   ```

   The image initializes the configured database with pgvector available for application migrations. The default entrypoint handles ownership on ordinary local volumes. For NFS, root-squashed storage, or explicit container users, provision writable storage for the image's PostgreSQL user before starting it. Do not change ownership of the original database.

5. Restore the dump, stopping on the first SQL error:

   ```shell
   docker compose exec -T db sh -c 'psql -U "${POSTGRES_USER:-postgres}" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1' < openproject.sql
   ```

6. Run the verification below, then start OpenProject:

   ```shell
   docker compose up -d
   ```

For named volumes, use a new named volume instead of the example host directory. Do not reuse the old volume. Development Compose follows the same procedure for `db`; also recreate or migrate its separate `db-test` database and rebuild the backend image for PostgreSQL 18 client tools.

## AIO upgrade using dump/restore

Use the previous OpenProject image for the dump. Record its exact tag, environment, attachment mounts, and PostgreSQL data mount.

1. Stop the AIO container to stop all writers. Start a temporary maintenance container with the previous image, the existing data mounted at `/var/openproject/pgdata`, and the matching version (17 below):

   ```shell
   docker stop "$OP_CONTAINER_NAME"
   docker run --rm --name openproject-pg-dump \
     -e PGVERSION=17 \
     -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
     --entrypoint bash openproject/openproject:17 \
     -c 'set -e; export PGBIN=/usr/lib/postgresql/$PGVERSION/bin;
         su postgres -c "$PGBIN/pg_ctl -D /var/openproject/pgdata -l /tmp/postgres.log -w start" >&2;
         trap '\''su postgres -c "$PGBIN/pg_ctl -D /var/openproject/pgdata -m fast -w stop" >&2'\'' EXIT;
         su postgres -c "$PGBIN/pg_dump -d openproject --no-owner --no-privileges"' > openproject.sql
   ```

   Use the same image variant and exact tag as your existing installation. Substitute your actual data mount. Custom PostgreSQL configurations may require additional mounts and `pg_ctl` options.

2. Initialize a separate PostgreSQL 18 directory. Set `PGDATA` explicitly to keep the flat data layout expected by AIO:

   ```shell
   docker run -d --name openproject-pg-restore \
     -e POSTGRES_PASSWORD=temporary-restore-password \
     -e PGDATA=/var/lib/postgresql/data \
     -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 \
     -v /var/lib/openproject/pgdata18:/var/lib/postgresql/data \
     pgvector/pgvector:pg18-bookworm
   docker exec openproject-pg-restore pg_isready -U postgres -d postgres
   ```

3. Once ready, create the application role and database, then restore the dump:

   ```shell
   docker exec openproject-pg-restore createuser -U postgres --superuser openproject
   docker exec openproject-pg-restore createdb -U postgres -O openproject openproject
   docker exec openproject-pg-restore psql -U postgres -v ON_ERROR_STOP=1 -c "ALTER ROLE openproject PASSWORD 'openproject';"
   docker exec -i openproject-pg-restore psql -U openproject -d openproject -v ON_ERROR_STOP=1 < openproject.sql
   ```

   Restore the application database role's password to match your AIO connection settings before cutover. The default AIO role is `openproject` with password `openproject`. Preserve any custom roles, grants, tablespaces, and additional databases separately; this dump covers the application database only.

4. Verify the restored database, then stop and remove the temporary container:

   ```shell
   docker stop openproject-pg-restore
   docker rm openproject-pg-restore
   ```

5. Recreate AIO with the OpenProject 18 image, `PGVERSION=18`, the new directory mounted at `/var/openproject/pgdata`, and your original attachment and application settings. AIO corrects local data ownership when it starts. Keep the original PostgreSQL 17 directory untouched.

### AIO `pg_upgrade` alternative

The bundled `docker/prod/postgres-db-upgrade` helper targets PostgreSQL 18. Stop AIO, back up first, and mount the original cluster plus an empty destination at `/var/openproject/pgdata-next` in a maintenance container:

```shell
docker run --rm \
  -e PGVERSION=17 \
  -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
  -v /var/lib/openproject/pgdata18:/var/openproject/pgdata-next \
  openproject/openproject:18 root ./docker/prod/postgres-db-upgrade
```

The helper runs the new `pg_upgrade` in copy mode, matches the source checksum setting when initializing the destination, and analyzes the new cluster. Both clusters must be stopped. Required extension libraries must exist for both server versions. It refuses destinations with another PostgreSQL major. Review the PostgreSQL upgrade output, including any required extension updates, before cutover.

Keep source and destination in separate directories. Do not pre-create `vector` in a `pg_upgrade` destination: the upgrade copies its definition. For nonstandard locales, authentication, tablespaces, or PostgreSQL configuration, follow the [PostgreSQL upgrade documentation](https://www.postgresql.org/docs/18/pgupgrade.html).

## Packaged installation upgrade

Stop OpenProject before the final dump:

```shell
sudo systemctl stop openproject
sudo -u postgres pg_dump -p 45432 --no-owner --no-privileges -d openproject > openproject.sql
```

Adjust the database, port, and role to your installation. Install PostgreSQL 18 and pgvector alongside the existing server:

```shell
# Debian / Ubuntu, with the PostgreSQL package repository configured
sudo apt-get update
sudo apt-get install postgresql-18 postgresql-18-pgvector

# Enterprise Linux, with the PostgreSQL package repository configured
sudo dnf install postgresql18-server postgresql18 postgresql18-contrib pgvector_18
sudo /usr/pgsql-18/bin/postgresql-18-setup initdb
```

Configure PostgreSQL 18 on a different port while the original server remains installed. On Debian/Ubuntu, check `pg_lsclusters`: installing another major does not always create its cluster. If no PostgreSQL 18 cluster exists, create one on the new port:

```shell
sudo pg_createcluster 18 main --port=45433 --start
```

If the cluster already exists, set its port with `sudo pg_conftool 18 main set port 45433` and restart it with `sudo pg_ctlcluster 18 main restart`. Choose an unused port. RPM installations require configuring the new cluster's port before starting `postgresql-18`.

Create the application role and database on PostgreSQL 18, preserving the role name and password from your installation. Restore with `psql -p NEW_PORT -d DATABASE -v ON_ERROR_STOP=1 < openproject.sql` as a database administrator.

Run `sudo openproject reconfigure`, select the existing-database option, and enter the new server's connection details. Start OpenProject and verify application access, attachments, and background jobs. Do not remove the original cluster until verification succeeds.

## Adding pgvector to an existing database

The database server must have pgvector installed before OpenProject can create the extension during application migrations.

For a local packaged database, install the package matching the running server major, for example `postgresql-17-pgvector` on Debian/Ubuntu or `pgvector_17` on Enterprise Linux. In AIO, matching packages are bundled. For Compose, deliberately switch to the matching pgvector image while preserving the major and data layout. For externally managed databases, ask the provider to make pgvector available.

After installing pgvector, run OpenProject's application migrations. If the application database user cannot create extensions, ask a database administrator to create it in the **application database**, then rerun the migrations:

```sql
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA pg_catalog;
```

Do not grant the application role superuser privileges just to activate an extension. Do not assume that installing a package activates it in every database.

## Verification and rollback

Run these queries in the application database:

```sql
SHOW server_version;
SELECT default_version FROM pg_available_extensions WHERE name = 'vector';
```

Expect PostgreSQL 18 and an available pgvector version. If vector was present in the source database, or after application migrations create it, also check:

```sql
SELECT extversion FROM pg_extension WHERE extname = 'vector';
SELECT '[1,2,3]'::vector <-> '[1,2,3]'::vector AS distance;
```

Expect an extension version and distance `0`. Check representative application records and attachment access, then restart/recreate the database container or service and verify persistence.

If validation fails before accepting new writes, stop the new application and database and restore the previous image, configuration, and original data mount. If the application version also changed, restore that version too. Once users write to the new database, switching back would discard those writes: retain both databases and plan recovery explicitly. Never start PostgreSQL 17 against PostgreSQL 18 files.
