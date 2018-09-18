# Upgrade your pre-5.0 OpenProject installation (DEB/RPM Packages)

Starting with OpenProject 4.1 stable releases will have their own branch on github. According to this the OpenProject release 6.0 is tracked via the stable/6 branch. We provide a stable branch `stable/<VERSION>` to contain all minor upgrades to OpenProject <VERSION>.x.

For OpenProject 4.2, two packages existed: The OpenProject Core and Community Edition.
Starting with OpenProject 5.0, both editions have been integrated into the single OpenProject package, which now contains a standard set of the most-used plugins previously contained in the Community Edition.

This guide contains two guides:

* The upgrade guide for OpenProject Core 4.2. to OpenProject 6.0
* The migration guide to OpenProject 6.0 from OpenProject Community Edition 4.2.

Please jump directly to the part of this guide depending on your OpenProject version (Core Edition or Community Edition) and operating system.

## Upgrading from OpenProject Core Edition 4.2

### Preliminary step: Remove the sources.list that defines the OpenProject Core Edition 4.2

To avoid trying to update the deprecated 4.2 package, remove the following entry:

    sudo rm -i /etc/apt/sources.list.d/openproject.list


### Debian 7.6 Wheezy 64bits server

    echo "deb https://deb.packager.io/gh/opf/openproject-ce wheezy stable/6" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject
    sudo openproject configure

### Ubuntu 14.04 Trusty 64bits server

    echo "deb https://deb.packager.io/gh/opf/openproject-ce trusty stable/6" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject
    sudo openproject configure

### Fedora 20 64bits server

    echo "[openproject]
    name=Repository for opf/openproject-ce application.
    baseurl=https://rpm.packager.io/gh/opf/openproject-ce/fedora20/stable/6
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject
    sudo openproject configure

### CentOS / RHEL 6 64 bits server

    echo "[openproject]
    name=Repository for opf/openproject-ce application.
    baseurl=https://rpm.packager.io/gh/opf/openproject-ce/centos6/stable/6
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject
    sudo openproject configure

### SUSE Linux Enterprise Server 12

    sudo zypper addrepo "https://rpm.packager.io/gh/opf/openproject-ce/sles12/stable/6" "openproject"
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

### Step 3: Confirm database connection details

If you used autoinstall, the database name and database user name should equal `openproject_ce`. You can confirm this by running:

    sudo openproject-ce config:get DATABASE_URL
   
Which should output something of the form

    mysql2://<username>:<password>@127.0.0.1:3306/<dbname>

If the URI contains `openproject_ce` as the username and database name as the example above, we can simply continue.
Otherwise, note user-, database name and password just to be sure.

### Step 4: Remove the openproject-ce package

Remove the `openproject-ce` package from your system. For Debian/Ubuntu, run:

    sudo apt-get remove openproject-ce

### Step 5: Remove the sources.list that defines the Community Edition package

To avoid installing the deprecated 4.2 package, remove the following entry:

    sudo rm -i /etc/apt/sources.list.d/pkgr-openproject-community.list


### Step 6: Move the existing application and configuration files

As the OpenProject 6.0 package is identitical to the core in regards to paths, you'll need to reference the configuration and application (e.g., attachments, SVN repositories) files to the path that is expected from the new package.

    # Move openproject-ce configuration
    sudo mv /etc/openproject-ce /etc/openproject

For repositories, there are references in the database to the old `/var/db/openproject-ce/svn/<repository>` locations, so we suggest to symlink them instead:

    # Symlink existing attachments and
    sudo ln -s /var/db/openproject-ce /var/db/openproject

### Step 7: Disable the Community Edition Apache2 configuration

As a final step, disable the `openproject-ce` configuration.

    sudo a2dissite openproject-ce
    
Optionally, remove the disabled site. The following path applies to Debian/Ubuntu.

    sudo rm -i /etc/apache2/sites-available/openproject-ce.conf

Note:

* For RedHat, the path should be changed to `/etc/httpd/conf.d/openproject-ce.conf`.
* For SLES, the path should be changed to `/etc/apache2/vhosts.d/openproject-ce.conf`.

### Step 8: Install the OpenProject 6.0 package and select database

The rest of the installation is mostly identical to the installation guide of the OpenProject 5.0 package:
https://www.openproject.org/open-source/packaged-installation/packaged-installation-guide/

Add the package source to your package manager, update the sources, and install the `openproject` package. (See the installation guide linked above for the detailed steps for the various distributions).

**Important:** Instead of running `openproject configure`, run `openproject reconfigure`, which will lead you through the complete wizard.

In the first step *mysql/autoinstall*, select the **reuse**  option (Use an existing database).

![](https://dl.dropboxusercontent.com/u/270758/op/mysql-reuse.png)

Press OK for the following steps, which will simply take the existing values from your old configuration

 * MySQL IP or hostname
 * MySQL port
 
In the dialog `mysql/username`, enter `openproject_ce` if the Database URI from Step 4 contained it. If you chose a different user name in the original CE installation, it should already be set to this value.

![](https://dl.dropboxusercontent.com/u/270758/op/mysql-username.png)

In the dialog `mysql/password`, **leave the password empty**. It will use the value from your original installation. You can optionally enter the password you retrieved from the database URI from Step 4, but that should be identical.

![](https://dl.dropboxusercontent.com/u/270758/op/mysql-password.png)

And again, in the `mysql/db_name` step,  enter `openproject_ce` if the Database URI from Step 4 contained it. If you chose a different database name in the original CE installation, it should already be set to this value.

The other installation steps (mysql/db_source_host, mysql/ssl) may again be skipped by pressing OK, as they should still contain the old values from the Community Edition.

There will be other new steps in the installation wizard for which we will provide additional information in the packager installation guide.

Once the wizard has completed, the OpenProject instance should be updated to 6.0.x while re-using your existing database.

**Note:** This last step is a workaround for the package upgrading process. We are working on making this step optional.
The workaround is necessary since since the package appname changed from `openproject-ce` to `openproject`, and the installer wizard automatically sets the database to the app name when selecting an automatic installation of MySQL. Instead, the updater should respect an existing database (user-) name in its configuration.
