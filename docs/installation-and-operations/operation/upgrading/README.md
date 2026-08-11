---
sidebar_navigation:
  title: Upgrading
  priority: 7
---

# Upgrading your OpenProject installation

> **Note**: We strongly recommend that you have backed up your installation before upgrading OpenProject to a newer version, especially when performing multiple upgrades at once. Please follow the [backup](../backing-up) instructions.

> **Note**: OpenProject supports migrating from one major version to the next. That means that migrating from a version X (and any of its minor and patch level) to version X+1 (and any of its minor and patch level) is supported. Migrating to X+2 however cannot be done directly but requires to install X+1 in between. Please refer to the [Step-wise database migration script](#step-wise-database-migration-script) section for an easy way to do this.

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Package-based installation](#package-based-installation-debrpm) | How to upgrade a package-based installation of OpenProject.  |
| [Docker-based installation](#compose-based-installation)     | How to upgrade a Docker-based installation of OpenProject.   |
| [Upgrade notes from 10.5.x](#upgrade-notes-from-105x)        | How to upgrade from OpenProject 10.5.x or greater to OpenProject 13.x and higher |
| [Upgrade notes from 9.x to 10.4.x](#upgrade-notes-from-9x-to-104x)             | How to upgrade from OpenProject 9.x or to OpenProject 10.4.x|
| [Upgrade notes for 8.x to 9.x](#upgrade-notes-for-8x-to-9x)  | How to upgrade from OpenProject 8.x to OpenProject 9.x.      |
| [Upgrade notes for 7.x to 8.x](#upgrade-notes-for-openproject-7x-to-8x) | How to upgrade from OpenProject 7.x to OpenProject 8.x.      |

## Package-based installation (DEB/RPM)

This section concerns upgrading of your OpenProject installation for packaged-based installation methods.

### Patch and minor releases

Upgrading to a newer patch or minor version of OpenProject is as easy as installing a newer OpenProject package and
running the `openproject configure` command.
Please follow the steps listed below according to your Linux distribution.

### Debian / Ubuntu

```shell
sudo apt-get update
sudo apt-get install --only-upgrade openproject
sudo openproject configure
```

**A note for Ubuntu 22.04 installations**

On Ubuntu 22.04., you might see warnings like these:

> W: `https://dl.packager.io/srv/deb/opf/openproject/stable/17/ubuntu/dists/22.04/InRelease`: Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details.

This message is due to Ubuntu 22.04 switching to a more secure way of adding repository sources, which is not yet supported by the repository provider. There is ongoing work on this item, the message is for information only.

If you get an error like the following:

> E: Repository '`https://dl.packager.io/srv/deb/opf/openproject/stable/17/ubuntu` 22.04 InRelease' changed its 'Origin' value from '' to '`https://packager.io/gh/opf/openproject`'
> E: Repository '`https://dl.packager.io/srv/deb/opf/openproject/stable/17/ubuntu` 22.04 InRelease' changed its 'Label' value from '' to 'Ubuntu 22.04 packages for opf/openproject'

These two messages messages are expected, due to a change in Origin and Label repository metadata, to better explain what the repository is about. You should allow the change, and/or run `sudo apt-get update --allow-releaseinfo-change` for the update to go through.

### CentOS / RHEL

```shell
sudo yum update
sudo yum install openproject
sudo openproject configure
```

### SuSE

```shell
sudo zypper refresh openproject
sudo zypper update openproject
sudo openproject configure
```

### Major upgrades

OpenProject uses a different package repository for each Major version of OpenProject.
This means that if you want to switch from (e.g.) OpenProject 11.x to 12.x, you will need to explicitly update your package source to be able to install the newer versions.

As in 17.0., also the package URL is changing, we recommend you remove the package repository information first, and then re-add it:

**Debian / Ubuntu**

```shell
rm /etc/apt/sources.list.d/openproject.list
```

**Enterprise Linux / Centos**

```shell
rm /etc/yum.repos.d/openproject.repo
```

**SLES15**

```shell
rm /etc/zypp/repos.d/openproject.repo
```

Then follow the first steps of the [installation guide](../../installation/packaged) for adding the correct information. Please follow the link below to see the appropriate steps for your Linux distribution.

| Distribution (64 bits only)                                              |
|--------------------------------------------------------------------------|
| [Ubuntu 22.04 Jammy Jellyfish](../../installation/packaged/#ubuntu-2204) |
| [Ubuntu 20.04 Focal](../../installation/packaged/#ubuntu-2004)           |
| [Debian 12 Bookworm](../../installation/packaged/#debian-12)             |
| [Debian 11 Bullseye](../../installation/packaged/#debian-11)             |
| [CentOS/RHEL 9.x](../../installation/packaged/#centos-9--rhel-9)         |
| [Suse Linux Enterprise Server 15](../../installation/packaged/#sles-15)  |

After following the steps to update the package source, updating the openproject package and running `openproject configure`, your system will be up to date.

In case you experience issues, please note the exact steps you took, copy the output of all commands you ran and open a post in our [installation support forum](https://community.openproject.org/projects/openproject/forums/9), or as an Enterprise customer, reaching out to [our customer support](mailto:support@openproject.org).

### Running openproject configure

It is important that you run the `openproject configure` command after _every_ upgrade of OpenProject, as this will ensure your installation is being updated and necessary database migrations are being performed.

Using `openproject configure`, the wizard will display new steps that weren't available yet or had not been configured in previous installations.

If you want to perform changes to your configuration or are unsure what steps are available, you can safely run `openproject reconfigure` to walk through the entire configuration process again.

Note that this still takes previous values into consideration. Values that should not change from your previous configurations can be skipped by pressing `<Return>`. This also applies for steps with passwords, which are shown as empty even though they may have a value. Skipping those steps equals to re-use the existing value.

## Compose-based installation

> [!NOTE]
> Please make sure the git repository with the docker-compose.yml file is up-to-date. If you're using an old version of the repository, the update might fail.

When using the Compose-based docker installation, you can simply do the following:

```shell
docker-compose pull --ignore-buildable
docker-compose up -d
```

Please note that you can override the `TAG` that is used to pull the OpenProject image from
the [Docker Hub](https://hub.docker.com/r/openproject/openproject/).

### All-in-one container

When using the all-in-one docker container, you need to perform the following steps:

1. First, pull the latest version of the image:

```shell
docker pull openproject/openproject:VERSION
# e.g. docker pull openproject/openproject:17
```

Then stop and remove your existing container (we assume that you are running with the recommended production setup here):

```shell
docker stop openproject
docker rm openproject
```

Finally, re-launch the container in the same way you launched it previously.
This time, it will use the new image:

```shell
docker run -d ... openproject/openproject:VERSION
```

#### I have already started OpenProject without mounted volumes. How do I save my data during an update?

You can extract your data from the existing container and mount it in a new one with the correct configuration.

1. Stop the container to avoid changes to the data. Stopping the container does not delete any data as long as you don't remove the container.
2. Copy the data to a new directory on the host, e.g. `/var/lib/openproject`, or a mounted network drive, say `/volume1`.
3. Launch the new container mounting the folders in that directory as described above.
4. Delete the old container once you confirmed the new one is working correctly.

You can copy the data from the container using `docker cp` like this:

```shell
# Find out the container name with `docker ps`, we use `openproject-community1` here.
# The target folder should be what ever persistent volume you have on the system, e.g. `/volume1`.
docker cp openproject-community1:/var/openproject/assets /volume1/openproject/assets
docker cp openproject-community1:/var/openproject/pgdata /volume1/openproject/pgdata
```

Make sure the folders have the correct owner so the new container can read and write them.

```shell
sudo chown -R 102 /volume1/openproject/*
```

After that it's simply a matter of launching the new container mounted with the copied `pgdata` and `assets` folders
as described in the [installation section](../../installation/docker/).

## Upgrade notes from 16.x

Starting from 16.x OpenProject only supports migrating from one major version (and its minor and patch levels) to the next major version (and its minor and patch levels). So all installations need to migrate to any 16.x version before continuing.

OpenProject 17.0 upgraded to a new major version of `good_job`, its underlying processor for background jobs. This upgrade was already prepared with
OpenProject 15.3, so if you've had any version between 15.3 and 16.6 running in your environment, you should be safe to proceed to 17.0.
However, if you directly upgraded from a version before 15.3, make sure to at least leave the background workers running on version 16.6 for a few minutes,
so that they can process all pending jobs, before continuing the upgrade to 17.0.

## Upgrade notes from 10.5.x

Generally, there are no special steps or caveats when upgrading to OpenProject 13.x or higher from any version greater than 10.5.x. Simply follow the upgrade steps outlined above for your type of installation.

If you are using Docker, you should mount your OpenProject volume at `/var/openproject/assets` instead of `/var/db/openproject`

## Upgrade notes from 9.x to 10.4.x

When upgrading from OpenProject <= 10.4.x to a newer version, you might need to remove the old cron jobs from ```/etc/cron.d/```.
You can list all OpenProject related cronjobs by using the ```sudo ls  /etc/cron.d/openproject-*``` command.

## Upgrade notes for 8.x to 9.x

These following points are some known issues regarding the update to 9.0.

### MySQL is being deprecated

OpenProject 9.0. is deprecating MySQL support. You can expect full MySQL support for the course of 9.0 releases, but we are likely going to be dropping MySQL completely in one of the following releases.

For more information regarding motivation behind this and migration steps, please see [this blog post](https://www.openproject.org/blog/deprecating-mysql-support/). In the post, you will find documentation for a mostly-automated migration script to PostgreSQL to help you get up and running with PostgreSQL.

### Package repository moved into opf/openproject

The OpenProject community installation is now using the same repository as the OpenProject development core.

Please update your package source according to our [installation section](../../installation/packaged).

You will need to replace `opf/openproject-ce` with `opf/openproject` together with a change from `stable/8` to `stable/9` in order to perform the update.

If you have currently installed the stable 8.x release of OpenProject by using the `stable/8` package source,
you will need to adjust that package source.

#### APT-based systems (Debian, Ubuntu)

- Update the reference to `opf/openproject-ce` in `/etc/apt/sources.list.d/openproject.list` to `opf/openproject`.
- Update the reference to `stable/8` in `/etc/apt/sources.list.d/openproject.list` to `stable/9`.
- Perform the Upgrade steps as mentioned above in _Upgrading your OpenProject installation_

#### YUM-based systems (CentOS, RHEL)

- Update the reference to `opf/openproject-ce` in `/etc/yum.repos.d/openproject.repo` to `opf/openproject`.
- Update the reference to `stable/8` in `/etc/yum.repos.d/openproject.repo` to `stable/9`.
- Perform the Upgrade steps as mentioned above in _Upgrading your OpenProject installation_

#### SUSE Linux Enterprise Server 12

- Update the reference to `opf/openproject-ce` in `/etc/zypp/repos.d/openproject.repo` to `opf/openproject`.
- Update the reference to `stable/8` in `/etc/zypp/repos.d/openproject.repo` to `stable/9`.
- Perform the Upgrade steps as mentioned above in _Upgrading your OpenProject installation_

## Upgrade notes for OpenProject 7.x to 8.x

These following points are some known issues around the update to 8.0. It does not contain the entire list of changes. To see all changes, [please browse the release notes](../../../release-notes/8/8-0-0/).

### Upgrades in NPM may result in package inconsistencies

As has been reported from the
community, [there appear to be issues with NPM leftover packages](https://community.openproject.org/wp/28571) upgrading
to OpenProject 8.0.0. This is due to the packages applying a delta between your installed version and the
to-be-installed 8.0. package.

To ensure the package's node_modules folder matches your local version, we recommend you simply remove `/opt/openproject/frontend/node_modules` entirely **before** installing the package

```shell
rm -rf /opt/openproject/frontend/node_modules
# Continue with the installation steps described below
```

### Migration from Textile to Markdown

OpenProject 8.0. has removed Textile, all previous content is migrated to GFM Markdown using [pandoc](https://pandoc.org). This will happen automatically during the migration run. A recent pandoc version will be downloaded by OpenProject.

For more information, please visit [this separate guide](../../misc/textile-migration).

## Step-wise database migration script

For migrating database dumps from OpenProject version 10 or later to the current version, you can use the [`bin/migrate`](https://github.com/opf/openproject/blob/dev/bin/migrate) script. This script automates the process of restoring a database dump and sequentially applying migrations through each OpenProject version until the latest version is reached.

### Prerequisites

- Docker installed and running
- Docker Hub access (to pull OpenProject images)
- A database dump file from OpenProject 10.x or later in `.sql` plain text format

### Usage

```shell
./bin/migrate [OPTIONS] <dump-file>
```

### Options

| Option | Description |
|--------|-------------|
| `-n, --change-schema-name NAME` | Change the PostgreSQL schema name to `NAME` before dumping the migrated database. Default schema is `public`. |
| `-f, --format FORMAT` | Output format for the migrated dump. Options: `sql` (default, gzipped), `pgdump` (custom/binary format). |

### Examples

Migrate a database dump to the latest version:

```shell
./bin/migrate openproject-10.5.sql
```

Migrate and output in PostgreSQL custom format:

```shell
./bin/migrate -f pgdump openproject-10.5.sql
```

Migrate and change the schema name to `custom_schema`:

```shell
./bin/migrate -n custom_schema openproject-10.5.sql
```

Migrate with both custom format and schema name:

```shell
./bin/migrate -f pgdump -n custom_schema openproject-10.5.sql
```

### Output

The script creates a new file with the migrated database dump. The output filename is derived from the input filename:

- For SQL format (default): `{input}-migrated.sql.gz` (gzipped)
- For pgdump format: `{input}-migrated.pgdump`

### Notes

- The script requires a dump from OpenProject 10.x or later. For older versions, use `script/migrate/migrate-from-pre-8.sh` first.
- The script starts a temporary PostgreSQL 17 container for the migration process.
- Each OpenProject version's Docker image is pulled on demand during migration.
- The migration process may take significant time depending on the size of your database and the number of versions to migrate through.
- The script automatically cleans up the temporary container and files on exit.
- When moving from a packaged installation to Docker Compose across multiple major versions, run this script on your SQL dump before importing it. See the [packaged → Docker Compose migration guide](../../misc/packaged-docker-migration/).
