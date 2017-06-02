### Steps to install OpenProject on CentOS 7

All steps are run with `sudo` to execute as the root user.

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the _packager.io_ platform to distribute our packages, both package source and signing key are tied to their service.

```bash
sudo rpm --import https://rpm.packager.io/key
```

**2. Add the OpenProject package source**

Create the file `/etc/yum.repos.d/openproject.repo` with the following contents


```
[openproject]
name=Repository for opf/openproject-ce application.
baseurl=https://rpm.packager.io/gh/opf/openproject-ce/centos7/stable/7
enabled=1
```


**3. Install the OpenProject Community Edition package**

Using the following command, yum will install the package and all required dependencies.

```bash
sudo yum install openproject
```
