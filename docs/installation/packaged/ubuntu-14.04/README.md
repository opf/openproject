### Steps to install OpenProject on Ubuntu 14.04 Trusty

All steps are prepended with `sudo` to ensure execution as the root user.

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the _packager.io_ platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO - https://deb.packager.io/key | sudo apt-key add -
```

**2. Add the OpenProject package source**

Create the file `/etc/apt/sources.list.d/openproject.list` with the following contents


```
deb https://deb.packager.io/gh/opf/openproject-ce trusty stable/7
```


**3. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```
