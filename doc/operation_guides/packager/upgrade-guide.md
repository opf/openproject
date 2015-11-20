# OpenProject upgrade guide

Starting with OpenProject 4.1 stable releases will have their own branch on github. According to this the OpenProject release 5.0 is tracked via the release/5.0 branch. We provide a stable branch
`stable/5` to contain all minor upgrades to OpenProject 5.x.

For OpenProject 4.2, two packages existed: The OpenProject Core and Community Edition.
Starting with OpenProject 5.0, both editions have been integrated into the single OpenProject package, which now contains a standard set of the most-used plugins previously contained in the Community Edition.

This guide contains two guides:

* The upgrade guide for OpenProject Core 4.2. to OpenProject 5.0
* The migration guide to OpenProject 5.0 from OpenProject Community Edition 4.2.

Please jump directly to the part of this guide depending on your OpenProject version (Core Edition or Community Edition) and operating system.

## Upgrading from OpenProject Core Edition 4.2

### Debian 7.6 Wheezy 64bits server

    echo "deb https://deb.packager.io/gh/opf/openproject wheezy stable/5" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject
    sudo openproject configure

### Ubuntu 14.04 Trusty 64bits server

    echo "deb https://deb.packager.io/gh/opf/openproject trusty stable/5" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject
    sudo openproject configure

### Fedora 20 64bits server

    echo "[openproject]
    name=Repository for opf/openproject application.
    baseurl=https://rpm.packager.io/gh/opf/openproject/fedora20/stable/5
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject
    sudo openproject configure

### CentOS / RHEL 6 64 bits server

    echo "[openproject]
    name=Repository for opf/openproject application.
    baseurl=https://rpm.packager.io/gh/opf/openproject/centos6/stable/5
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject
    sudo openproject configure

### SUSE Linux Enterprise Server 12

    sudo zypper addrepo "https://rpm.packager.io/gh/opf/openproject/sles12/stable/5" "openproject"
    sudo zypper install openproject
    sudo openproject configure

## Migrating from OpenProject Community Edition 4.2

The `openproject-ce` package no longer exists, but you can migrate to the new OpenProject package, which contains all functionality that was previously contained in the Community Edition.

The following steps were tested on Ubuntu and Debian machines with OpenProject Community Edition 4.2 installed. There may be variations for other distributions, please let us know If you can provide additional information to the migration path.

### Step 1: Backup existing installation

Before performing the migration, please backup your existing installation. While we will continue to use it and database migrations should run smoothly, please keep a backup at hand.

To backup attachments, database and repository, use the following command:

    sudo openproject-ce run backup

### Step 2: Shut down openproject-ce instance

To avoid any further changes to the application, stop the web and worker processes:

    sudo openproject-ce scale web=0 worker=0

### Step 3: Remove the openproject-ce package

Remove the `openproject-ce` package from your system. For Debian/Ubuntu, run:

    sudo apt-get remove openproject-ce

### Step 4: Remove the sources.list that defines the Community Edition package

To avoid installing the deprecated 4.2 package, remove the following entry:

    sudo rm -i /etc/apt/sources.list.d/pkgr-openproject-community.list


### Step 5: Move the existing application and configuration files

As the OpenProject 5.0 package is identitical to the core in regards to paths, you'll need to reference the configuration and application (e.g., attachments, SVN repositories) files to the path that is expected from the new package.

    # Move openproject-ce configuration
    sudo mv /etc/openproject-ce /etc/openproject

For repositories, there are references in the database to the old `/var/db/openproject-ce/svn/<repository>` locations, so we suggest to symlink them instead:

    # Symlink existing attachments and
    sudo ln -s /var/db/openproject-ce /var/db/openproject

### Step 6: Disable the Community Edition Apache2 configuration

As a final step, disable the `openproject-ce` configuration.

    sudo a2dissite openproject-ce

Optionally, remove the disabled site. The following path applies to Debian/Ubuntu.

    sudo rm -i /etc/apache2/sites-available/openproject-ce

Note:

* For RedHat, the path should be changed to `/etc/httpd/conf.d/openproject-ce.conf`.
* For SLES, the path should be changed to `/etc/apache2/vhosts.d/openproject-ce.conf`.
