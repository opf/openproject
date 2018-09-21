# Upgrading your OpenProject installation

Note: this guide only applies if you've installed OpenProject using our DEB/RPM
packages.

Upgrading OpenProject is as easy as installing a newer OpenProject package and
running the `openproject configure` command.

## Backup

We try to ensure your upgrade path is as smooth as possible. This means that the below update + configure step should be the only change needed to get up to date with our packaged installation.

In the event of an error during the migrations, you will still want to have a recent backup you can restore to before reaching out to us. This is especially important for MySQL installations, since it does not support transactional migrations with changes to the table schema and you will have to rollback these changes manually. For PostgreSQL, if the Rails migrations fail, all previous changes will be rolled back for you to try again, or to install the older packages.

To perform a backup, run the following command

```bash
sudo openproject run backup
```

This will store the current database dump, attachments and config to `/var/db/openproject/backup`. For more information on the backup and restore mechanisms, [check our detailed backup guide](https://www.openproject.org/operations/backup/backup-guide-packaged-installation/).

## Debian / Ubuntu

    sudo apt-get update
    sudo apt-get install --only-upgrade openproject
    sudo openproject configure

## CentOS / RHEL

    sudo yum update
    sudo yum install openproject
    sudo openproject configure

## SuSE

    sudo zypper update openproject
    sudo openproject configure


## Re-configuring the application

Using `openproject configure`, the wizard will display new steps that weren't available yet or had not been configured in previous installations.
If you want to perform changes to your configuration or are unsure what steps are available, you can safely run `openproject reconfigure` to walk through the entire configuration process again.

Note that this still takes previous values into consideration. Values that should not change from your previous configurations can be skipped by pressing `<Return>`. This also applies for steps with passwords, which are shown as empty even though they may have a value. Skipping those steps equals to re-use the existing value.


# Upgrading between major releases (DEB/RPM packages)

Since OpenProject 8.0.0 is a major upgrade, you will need to perform some basic manual steps to upgrade your package.

First, please check that the package repository is correct. Compare your local package repository with the one printed on your matching distribution on [our Download and Installation page](https://www.openproject.org/download-and-installation/)

## Upgrade notes for OpenProject 8.0.

These following points are some known issues around the update to 8.0. It does not contain the entire list of changes. To see all changes, [please browse the release notes](https://www.openproject.org/release-notes/openproject-8-0/).

### Upgrades in NPM may result in package inconsistencies

As has been reported from the community, [there appear to be issues with NPM leftover packages](https://community.openproject.com/projects/openproject/work_packages/28571) upgrading to OpenProject 8.0.0. This is due to the packages applying a delta between your installed version and the to-be-installed 8.0. package. In some cases such as SLES12 and Centos 7, the `frontend/node_modules` folder is not fully correctly replaced. This appears to hint at an issue with yum, the package manager behind both.

To ensure the package's node_modules folder matches your local version, we recommend you simply remove `/opt/openproject/frontend/node_modules` entirely **before** installing the package

```
rm -rf /opt/openproject/frontend/node_modules
# Continue with the installation steps described below
```

### Migration from Textile to Markdown

OpenProject 8.0. has removed Textile, all previous content is migrated to GFM Markdown using [pandoc](https://pandoc.org). This will happen automatically during the migration run. A recent pandoc version will be downloaded by OpenProject.

For more information, please visit this separate guide: https://github.com/opf/openproject/tree/dev/docs/user/textile-to-markdown-migration


## Upgrade steps

If you have currently installed the stable 7.x release of OpenProject by using the `stable/7` package source,
you will need to adjust that package source.

### APT-based systems (Debian, Ubuntu)

 - Update the reference to `stable/7` in `/etc/apt/sources.list.d/openproject.list` to `stable/8`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

### YUM-based systems (CentOS, RHEL)

 - Update the reference to `stable/7` in `/etc/yum.repos.d/openproject.repo` to `stable/8`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

### SUSE Linux Enterprise Server 12

 - Update the reference to `stable/7` in `/etc/zypp/repos.d/openproject.repo` to `stable/8`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*


