### Steps to install OpenProject on Suse Linux Enterprise Server 12

All steps need to be run as `root`.


**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the _packager.io_ platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget https://rpm.packager.io/key -O packager.key
rpm --import packager.key
```

**2. Add the OpenProject package source**

Add a named zypper repository source for OpenProject using the following commands:

```
zypper addrepo "https://rpm.packager.io/gh/opf/openproject-ce/sles12/stable/7" "openproject"
```

The package source is now registered as `openproject`.


**3. Install the OpenProject Community Edition package**

Using the following command, zypper will install the package and all required dependencies.

```bash
zypper install openproject
```
