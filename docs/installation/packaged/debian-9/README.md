### Steps to install OpenProject on Debian 9 (Stretch)

All steps need to be run as `root`.

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the _packager.io_ platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject-ce/key | sudo apt-key add -
```

**2. Install apt-https suppport**

Since we only provide https package sources, you may need to install `apt-transport-https` as a preliminary step.

```bash
apt-get install apt-transport-https
```


**3. Add the OpenProject package source**

```
wget -O /etc/apt/sources.list.d/openproject-ce.list \
  https://dl.packager.io/srv/opf/openproject-ce/stable/7/installer/debian/9.repo
```


**4. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```
