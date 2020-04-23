---
sidebar_navigation:
  title: Upgrading
  priority: 7
---

# Upgrading your OpenProject installation

<div class="alert alert-warning" role="alert">

**Note**: In the rest of this guide, we assume that you have taken the necessary steps to [backup](../backing-up) your OpenProject installation before upgrading.

</div>

## Package-based installation (DEB/RPM)

Upgrading OpenProject is as easy as installing a newer OpenProject package and
running the `openproject configure` command.

<div class="alert alert-info" role="alert">

Please note that the package-based installation uses different release channels for each MAJOR version of OpenProject. This means that if you want to switch from (e.g.) 9.x to 10.x, you will need to perform the steps described in the [installation section](../../installation/packaged) to update your package sources to point to the newer release channel. The rest of this section is only applicable if you want to upgrade a (e.g.) 10.x version to a 10.y vesion.

</div>

### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install --only-upgrade openproject
sudo openproject configure
```

### CentOS / RHEL

```bash
sudo yum update
sudo yum install openproject
sudo openproject configure
```

### SuSE

```bash
sudo zypper update openproject
sudo openproject configure
```


<div class="alert alert-info" role="alert">

Using `openproject configure`, the wizard will display new steps that weren't available yet or had not been configured in previous installations.

If you want to perform changes to your configuration or are unsure what steps are available, you can safely run `openproject reconfigure` to walk through the entire configuration process again.

Note that this still takes previous values into consideration. Values that should not change from your previous configurations can be skipped by pressing `<Return>`. This also applies for steps with passwords, which are shown as empty even though they may have a value. Skipping those steps equals to re-use the existing value.

</div>

## Docker-based installation

When using the Compose-based docker installation, you can simply do the following:

```bash
docker-compose pull
docker-compose up -d
```

Please note that you can override the `TAG` that is used to pull the OpenProject image from the [Docker Hub](https://hub.docker.com/r/openproject/community).


When using the all-in-one docker container, you need to perform the following steps:

1. First, pull the latest version of the image:

```bash
docker pull openproject/community:VERSION
# e.g. docker pull openproject/community:10
```

Then stop and remove your existing container (we assume that you are running with the recommended production setup here):

```bash
docker stop openproject
docker rm openproject
```

Finally, re-launch the container in the same way you launched it previously.
This time, it will use the new image:

```
docker run -d ... openproject/community:VERSION
```

## Upgrade notes for 8.x to 9.x

These following points are some known issues regarding the update to 9.0.

### MySQL is being deprecated

OpenProject 9.0. is deprecating MySQL support. You can expect full MySQL
support for the course of 9.0 releases, but we are likely going to be dropping
MySQL completely in one of the following releases.

For more information regarding motivation behind this and migration steps,
please see https://www.openproject.org/deprecating-mysql-support/ In this post,
you will find documentation for a mostly-automated migration script to
PostgreSQL to help you get up and running with PostgreSQL.

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

### Upgrade notes for OpenProject 7.x to 8.x

These following points are some known issues around the update to 8.0. It does not contain the entire list of changes. To see all changes, [please browse the release notes](https://docs.openproject.org/release-notes/8-0-0/).

#### Upgrades in NPM may result in package inconsistencies

As has been reported from the community, [there appear to be issues with NPM leftover packages](https://community.openproject.com/projects/openproject/work_packages/28571) upgrading to OpenProject 8.0.0. This is due to the packages applying a delta between your installed version and the to-be-installed 8.0. package. In some cases such as SLES12 and Centos 7, the `frontend/node_modules` folder is not fully correctly replaced. This appears to hint at an issue with yum, the package manager behind both.

To ensure the package's node_modules folder matches your local version, we recommend you simply remove `/opt/openproject/frontend/node_modules` entirely **before** installing the package

```
rm -rf /opt/openproject/frontend/node_modules
# Continue with the installation steps described below
```

#### Migration from Textile to Markdown

OpenProject 8.0. has removed Textile, all previous content is migrated to GFM Markdown using [pandoc](https://pandoc.org). This will happen automatically during the migration run. A recent pandoc version will be downloaded by OpenProject.

For more information, please visit this separate guide: https://github.com/opf/openproject/tree/dev/docs/user/textile-to-markdown-migration
