### Steps to install OpenProject package on Ubuntu 18.04 Bionic Beaver

All steps are prepended with `sudo` to ensure execution as the root user.

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the _packager.io_ platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

**2. Ensure that universe package source is added**

You may run into issues trying to install the `dialog` package in Ubuntu 18.04. To resolve this, please ensure you have the universe APT source

```bash
sudo add-apt-repository universe
```


**3. Add the OpenProject package source**

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/ubuntu/18.04.repo
```


**4. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```
