# Upgrade your OpenProject installation (DEB/RPM Packages)

Note: this guide only applies if you've installed OpenProject using our DEB/RPM
packages.

Upgrading OpenProject is as easy as installing a newer OpenProject package and
running the `openproject configure` command.

## Debian / Ubuntu

    sudo apt-get update
    sudo apt-get install --only-upgrade openproject
    sudo openproject configure

## Fedora / CentOS / RHEL

    sudo yum update
    sudo yum install openproject
    sudo openproject configure

## SuSE

    sudo zypper update openproject
    sudo openproject configure

