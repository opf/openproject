### Steps to install OpenProject on Suse Linux Enterprise Server 12

All steps need to be run as `root`.

**1. Add the OpenProject package source**

```
wget -O /etc/zypp/repos.d/openproject-ce.repo \
  https://dl.packager.io/srv/opf/openproject-ce/stable/8/installer/sles/12.repo
```

The package source is now registered as `openproject`.

**2. Install the OpenProject Community Edition package**

Using the following command, zypper will install the package and all required dependencies.

```bash
zypper install openproject
```
