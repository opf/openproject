---
sidebar_navigation:
  title: Installation
  priority: 200
---

# Installation of OpenProject with DEB/RPM packages

The packaged installation of OpenProject is the recommended way to install and maintain OpenProject using DEB or RPM packages.

The package will:

- guide you through all the required steps

- install all the required libraries and dependencies

- install a local PostgreSQL database or allow you to connect to an existing PostgreSQL database

- allow you to install and configure an outer Apache web server (recommended)

- setup SSL/TLS encryption for the Apache server (optional)

- configure repositories (Git/SVN) (optional)

- configure email settings

The package is available for the following Linux distributions:

| Distribution (**64 bits only**)     | Identifier   | init system |
| ------------------------------- | ------------ | ----------- |
| CentOS/RHEL 7.x                 | centos-7     | systemd     |
| Debian 9 Stretch                | debian-9     | systemd     |
| Debian 10 Stretch               | debian-10    | systemd     |
| Suse Linux Enterprise Server 12 | sles-12      | sysvinit    |
| Ubuntu 16.04 Xenial Xerus       | ubuntu-16.04 | upstart     |
| Ubuntu 18.04 Bionic Beaver      | ubuntu-18.04 | systemd     |

Please ensure that you are running on a 64bit system before proceeding with the installation. You can check by running the `uname -i` command on the target server and verifying that it outputs `x86_64`:

```
$ uname -i
x86_64
```

Also, please note that the packaged installation works best when running on a dedicated server or virtual machine, as we cannot ensure that the components installed and configured by the OpenProject installer will work on systems that have been already customized.

## Installation

The first step of the installation is to add the OpenProject package source to the package manager of your distribution (`apt`, `yum`, or `zypper`).

### Ubuntu 18.04

Import the PGP key used to sign our packages:

```
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/ubuntu/18.04.repo
```

Download the OpenProject package:

```
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### Ubuntu 16.04

Import the PGP key used to sign our packages:

```
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/ubuntu/16.04.repo
```

Download the OpenProject package:

```
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### Debian 10

Import the PGP key used to sign our packages:

```
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/debian/10.repo
```

Download the OpenProject package:

```
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### Debian 9

Import the PGP key used to sign our packages:

```
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/debian/9.repo
```

Download the OpenProject package:

```
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### CentOS 7 / RHEL 7

Add the OpenProject package source:

```
sudo wget -O /etc/yum.repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/el/7.repo
```

Download the OpenProject package:

```
sudo yum install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### SLES 12

Add the OpenProject package source:

```
wget -O /etc/zypp/repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/sles/12.repo
```

Download the OpenProject package:

```
sudo zypper install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

[initial-config]: ../configuration


