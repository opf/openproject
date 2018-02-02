### Steps to install OpenProject on Ubuntu 14.04 Trusty

All steps are prepended with `sudo` to ensure execution as the root user.

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the _packager.io_ platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject-ce/key | sudo apt-key add -
```

**2. Ensure that apt-transport-https is installed**

Our repository requires apt to have https support. Install this transport method with `sudo apt-get install apt-transport-https` if you did not already.

**3. Add the OpenProject package source**

```
sudo wget -O /etc/apt/sources.list.d/openproject-ce.list \
  https://dl.packager.io/srv/opf/openproject-ce/stable/7/installer/ubuntu/14.04.repo
```

**4. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```
