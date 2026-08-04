# Migrating your packaged OpenProject installation to Docker Compose

This guide describes how to transition from a packaged (DEB/RPM) OpenProject installation to a Docker Compose based setup.

> [!IMPORTANT]
> Packaged installation updates are no longer available for newer OpenProject versions on several distributions.
> Migrating to Docker Compose (or Kubernetes) is the recommended path forward.
> Older OpenProject versions can still be migrated; you do not need to stay on the packaged installation indefinitely.

The overall process is:

1. [Back up the packaged installation](#step-1-back-up-your-packaged-installation)
2. [Retrieve and reuse `SECRET_KEY_BASE`](#step-2-retrieve-and-reuse-secret_key_base)
3. [Install OpenProject with Docker Compose](#step-3-install-openproject-with-docker-compose)
4. [Prepare the database dump for the target version](#step-4-prepare-the-database-dump-for-the-target-version)
5. [Restore the database into Docker Compose](#step-5-restore-the-database-into-docker-compose)
6. [Restore attachments](#step-6-restore-attachments)
7. [Start OpenProject and verify](#step-7-start-openproject-and-verify)

## Step 1: Back up your packaged installation

To prevent data loss, create a full backup of your current OpenProject instance and store it in a secure location.
Follow the [package-based backup guide](../../operation/backing-up/#package-based-installation-debrpm).

That backup typically includes:

- `postgresql-dump-<timestamp>.pgdump` (Database backup)
- `attachments-<timestamp>.tar.gz` (Attachments / Uploaded files)
- `conf-<timestamp>.tar.gz` (Configuration of the packaged installation - including secrets)
- `git-repositories-<timestamp>.tar.gz` / `svn-repositories-<timestamp>.tar.gz` (Repository data, if used)

**Important:** The packaged installation PostgreSQL backup uses the binary/custom backup mode. This backup can fail when the Docker Compose PostgreSQL version differs from the packaged one. To prevent this, please use a separate manual plain SQL backup using this command:

```shell
pg_dump $(sudo openproject config:get DATABASE_URL) -x -O > openproject.sql
```

You will need this plain SQL dump and the `attachments-<timestamp>.tar.gz` archive from the packaged backup available for the steps below.

## Step 2: Retrieve and reuse `SECRET_KEY_BASE`

OpenProject uses `SECRET_KEY_BASE` as the key derivation input for Rails secrets (session cookies, reminder and invitation tokens, and similar signed values). If possible, you want to retain this information, as otherwise users will be logged out and have some of their tokens reset.

On a packaged installation, retrieve the existing value:

```shell
sudo openproject config:get SECRET_KEY_BASE
```

If that returns nothing, try the legacy name (older packages set both to the same value):

```shell
sudo openproject config:get SECRET_TOKEN
```

> [!TIP]
> Packaged installations historically exposed both `SECRET_KEY_BASE` and `SECRET_TOKEN`.
> Docker Compose only uses `SECRET_KEY_BASE`.
> Prefer keeping the same value so existing sessions and tokens remain valid.
> If you generate a new `SECRET_KEY_BASE`, all user sessions are invalidated and some tokens (for example invitation or reminder tokens) stop working until reissued.

You will set this value in the Docker Compose `.env` file in the next step.

## Step 3: Install OpenProject with Docker Compose

Follow the [Docker Compose installation guide](../../installation/docker-compose/) to clone the repository and create your `.env` file.

Before the first start, set at least:

```shell
SECRET_KEY_BASE=<value from step 2>
OPENPROJECT_HOST__NAME=<your public hostname>
```

Then start the stack once so volumes and the database container exist:

```shell
docker compose up -d
```

Confirm that the frontend comes up (a fresh empty instance is expected at this point).
You will replace the seeded database and attachments in the following steps.

> [!Note]
> This guide focuses on the Docker Compose installation method, as that is recommended for production migrations.
> The all-in-one docker container restore path is documented separately in the [Backup Restoring Guide](../../operation/restoring/#using-the-all-in-one-container).

## Step 4: Prepare the database dump for the target version

Docker Compose installs the current OpenProject major version.
OpenProject cannot always migrate a database dump across multiple major versions in one step.
If you restore a dump from an older packaged version (for example 13.x) directly into a current Compose stack, the `seeder` service may crash and restart without a clear error.

For dumps from OpenProject **10.x or later**, download and use the [`bin/migrate`](https://github.com/opf/openproject/blob/dev/bin/migrate) script.
It starts temporary Docker containers and applies migrations major version by major version until the dump matches the current release:

```shell
# Download the script (or clone the OpenProject repository)
curl -fsSL -o migrate https://raw.githubusercontent.com/opf/openproject/dev/bin/migrate
chmod +x migrate

# Migrate your SQL dump
./migrate /path/to/openproject.sql
```

This produces a migrated dump such as `openproject-migrated.sql.gz`.
Use that file in the next step.

Further options and prerequisites are documented under [Step-wise database migration script](../../operation/upgrading/#step-wise-database-migration-script).

> [!NOTE]
> If your packaged installation is already on the same major version as the Docker Compose target (or only one major behind), you can skip this step and import `openproject.sql` directly.
> When in doubt, run `bin/migrate`. It is the safer path for older packaged releases.

## Step 5: Restore the database into Docker Compose

After Compose has been started at least once, import the (migrated) SQL dump into the `db` container.
These steps mirror the [Using Docker Compose](../../operation/restoring/#using-docker-compose) section of the restoring guide.

From the directory that contains your `docker-compose.yml`:

```shell
# Stop application processes so nothing writes to the database during import
docker compose stop web worker cron seeder

# Drop and recreate the database (Compose connects as the postgres superuser by default)
# This is using the FORCE flag to ensure we drop the connection if any process is still connected to it
docker compose exec -T db psql -U postgres -c 'DROP DATABASE IF EXISTS openproject WITH (FORCE);'
docker compose exec -T db psql -U postgres -c 'CREATE DATABASE openproject OWNER postgres;'

# Import the dump (use the migrated dump from Step 4 when applicable)
# For a plain .sql file:
docker compose exec -T db psql -U postgres -d openproject < openproject-migrated.sql

# For a gzipped dump produced by bin/migrate:
gunzip -c openproject-migrated.sql.gz | docker compose exec -T db psql -U postgres -d openproject
```

Ownership notices referring to a packaged `openproject` role can usually be ignored when importing with `-x -O` dumps (or dumps produced by `bin/migrate`).
If your dump requires that role, create it before importing:

```shell
docker compose exec -T db psql -U postgres -c "DO \$\$ BEGIN CREATE ROLE openproject LOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END \$\$;"
```

## Step 6: Restore attachments

Packaged backups store attachments in `attachments-<timestamp>.tar.gz`.
In Docker Compose, attachments live in the `opdata` volume, mounted into the application containers at `/var/openproject/assets`.
Extract the archive into the `files` subdirectory of that volume.

### If you use a bind-mounted assets directory

The Compose `.env.example` often sets `OPDATA=/var/openproject/assets`. In that case:

```shell
sudo mkdir -p /var/openproject/assets/files
sudo tar -xzf attachments-<timestamp>.tar.gz -C /var/openproject/assets/files
sudo chown -R 1000:1000 /var/openproject/assets
```

### If you use the default named Docker volume

Find the volume name (it is prefixed by your Compose project directory name):

```shell
docker volume ls | grep opdata
# e.g. openproject_opdata
```

Then extract the archive into that volume:

```shell
docker run --rm \
  -v openproject_opdata:/var/openproject/assets \
  -v /path/to/backup:/backup:ro \
  alpine sh -c "
    mkdir -p /var/openproject/assets/files &&
    tar -xzf /backup/attachments-<timestamp>.tar.gz -C /var/openproject/assets/files &&
    chown -R 1000:1000 /var/openproject/assets
  "
```

Replace `openproject_opdata` and `/path/to/backup` with your actual volume name and backup directory.

> [!NOTE]
> Docker-based installations do not support integrated Subversion/Git repositories managed by OpenProject.
> If you relied on that feature in the packaged installation, point projects at external repositories after the migration.
> See the [Docker limitations](../../installation/docker/#limitations).

## Step 7: Start OpenProject and verify

Run database migrations / seed against the restored data, then bring the stack back up:

```shell
docker compose run --rm seeder
docker compose up -d
docker compose logs -f web worker seeder
```

Confirm that:

- You can sign in with an existing user (especially if you reused `SECRET_KEY_BASE`)
- Projects and work packages look correct
- Attachments open and download successfully
- Background jobs are processed (no repeated seeder crash loop)

If the seeder still crash-loops after a direct import, return to [Step 4](#step-4-prepare-the-database-dump-for-the-target-version) and migrate the dump with `bin/migrate` before importing again.

## Related documentation

- [Backing up](../../operation/backing-up/)
- [Restoring](../../operation/restoring/) — including [Using Docker Compose](../../operation/restoring/#using-docker-compose)
- [Docker Compose installation](../../installation/docker-compose/)
- [Step-wise database migration script](../../operation/upgrading/#step-wise-database-migration-script)
- [Migrating a packaged installation to another packaged environment](../migration/)
