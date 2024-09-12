---
sidebar_navigation:
  title: Upgrading
  priority: 7
---

# Upgrading your OpenProject installation

> **Note**: We strongly recommend that you have backed up your installation before upgrading OpenProject to a newer version, especially when performing multiple upgrades at once. Please follow the [backup](../backing-up) instructions.

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Package-based installation](#package-based-installation-debrpm) | How to upgrade a package-based installation of OpenProject.  |
| [Docker-based installation](#compose-based-installation)     | How to upgrade a Docker-based installation of OpenProject.   |
| [Upgrade notes from 9.x](#upgrade-notes-from-9x)             | How to upgrade from OpenProject 9.x or greater to OpenProject 13.x and higher |
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

> W: https://dl.packager.io/srv/deb/opf/openproject/stable/14/ubuntu/dists/22.04/InRelease: Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details.

This message is due to Ubuntu 22.04 switching to a more secure way of adding repository sources, which is not yet supported by the repository provider. There is ongoing work on this item, the message is for information only.

If you get an error like the following:

> E: Repository 'https://dl.packager.io/srv/deb/opf/openproject/stable/14/ubuntu 22.04 InRelease' changed its 'Origin' value from '' to 'https://packager.io/gh/opf/openproject'
> E: Repository 'https://dl.packager.io/srv/deb/opf/openproject/stable/14/ubuntu 22.04 InRelease' changed its 'Label' value from '' to 'Ubuntu 22.04 packages for opf/openproject'

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

The necessary steps are the same as setting up the package source for the first time. You can also check the [installation guide](../../installation/packaged) for more information. Please follow the link below to see the appropriate steps for your Linux distribution.

| Distribution (64 bits only)                                              |
|--------------------------------------------------------------------------|
| [Ubuntu 22.04 Jammy Jellyfish](../../installation/packaged/#ubuntu-2204) |
| [Ubuntu 20.04 Focal](../../installation/packaged/#ubuntu-2004)           |
| [Debian 12 Bookworm](../../installation/packaged/#debian-12)             |
| [Debian 11 Bullseye](../../installation/packaged/#debian-11)             |
| [CentOS/RHEL 9.x](../../installation/packaged/#centos-9--rhel-9)         |
| [CentOS/RHEL 8.x](../../installation/packaged/#centos-8--rhel-8)         |
| [Suse Linux Enterprise Server 15](../../installation/packaged/#sles-15)  |

After following the steps to update the package source, updating the openproject package and running `openproject configure`, your system will be up to date.

In case you experience issues, please note the exact steps you took, copy the output of all commands you ran and open a post in our [installation support forum](https://community.openproject.org/projects/openproject/forums/9).

### Running openproject configure

It is important that you run the `openproject configure` command after _every_ upgrade of OpenProject, as this will ensure your installation is being updated and necessary database migrations are being performed.

Using `openproject configure`, the wizard will display new steps that weren't available yet or had not been configured in previous installations.

If you want to perform changes to your configuration or are unsure what steps are available, you can safely run `openproject reconfigure` to walk through the entire configuration process again.

Note that this still takes previous values into consideration. Values that should not change from your previous configurations can be skipped by pressing `<Return>`. This also applies for steps with passwords, which are shown as empty even though they may have a value. Skipping those steps equals to re-use the existing value.

## Compose-based installation
> **Note**: Please make sure the git repository with the docker-compose.yml file is up-to-date. If you're using an old version of the repository, the update might fail.

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
# e.g. docker pull openproject/openproject:14
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
as described in the [installation section](../../installation/docker/#one-container-per-process-recommended).

## Upgrade notes from 9.x

Generally, there are no special steps or caveats when upgrading to OpenProject 13.x or higher from any version greater than 9.x. Simply follow the upgrade steps outlined above for your type of installation.

If you are using Docker, you should mount your OpenProject volume at `/var/openproject/assets` instead of `/var/db/openproject`

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
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

#### YUM-based systems (CentOS, RHEL)

 - Update the reference to `opf/openproject-ce` in `/etc/yum.repos.d/openproject.repo` to `opf/openproject`.
 - Update the reference to `stable/8` in `/etc/yum.repos.d/openproject.repo` to `stable/9`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

#### SUSE Linux Enterprise Server 12

 - Update the reference to `opf/openproject-ce` in `/etc/zypp/repos.d/openproject.repo` to `opf/openproject`.
 - Update the reference to `stable/8` in `/etc/zypp/repos.d/openproject.repo` to `stable/9`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

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
