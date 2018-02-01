# Upgrading your OpenProject installation

Note: this guide only applies if you've installed OpenProject using our DEB/RPM
packages.

Upgrading OpenProject is as easy as installing a newer OpenProject package and
running the `openproject configure` command.

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

Since OpenProject 7.0.0 is a major upgrade, you will need to perform some basic manual steps to upgrade your package.

If you have currently installed the stable 6.0.x release of OpenProject by using the `stable/6` package source,
you will need to adjust that package source.

### APT-based systems (Debian, Ubuntu)

 - Update the reference to `stable/6` in `/etc/apt/sources.list.d/openproject.list` to `stable/7`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

### YUM-based systems (CentOS, RHEL)

 - Update the reference to `stable/6` in `/etc/yum.repos.d/openproject.repo` to `stable/7`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*

### SUSE Linux Enterprise Server 12

 - Update the reference to `stable/6` in `/etc/zypp/repos.d/openproject.repo` to `stable/7`.
 - Perform the Upgrade steps as mentioned above in *Upgrading your OpenProject installation*
