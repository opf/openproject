### Steps to install OpenProject on CentOS 7

All steps are run with `sudo` to execute as the root user.

**1. Add the OpenProject package source**

```
sudo wget -O /etc/yum.repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/9/installer/el/7.repo
```

**2. Install the OpenProject Community Edition package**

Using the following command, yum will install the package and all required dependencies.

```bash
sudo yum install openproject
```
