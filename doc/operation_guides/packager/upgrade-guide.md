# OpenProject upgrade guide

Starting with OpenProject 4.1 stable releases will have their own branch on github. According to this the OpenProject release 4.2 is tracked via the stable/4.2 branch. But why is this important to how the OpenProject packages are provided:

The OpenProject Core and OpenProject Community Edition release 4.0 packages are derived from the stable branch of the respective repositories. Due to the fact that the branch for the OpenProject releasse 4.2 is tracked via the stable/4.2 branch packages has to be derived from the stable/4.2 branch instead of stable. This change makes it necessary to update the source file for the package management system of the machine OpenProject is currently installed on. A typical `apt-get install openproject` e.g. for debian like systems will not work.

The following upgrade instructions describe in detail what has to be done to upgrade existing 4.0 installations of the OpenProject Core and the OpenProject Community Edition to 4.2 via the package management system. Therefore the guide is split into two parts:

* The upgrade guide for OpenProject Core
* The upgrade guide for OpenProject Community Edition

Please jump directly to the part of this guide depending on your OpenProject version (Core Edition or Community Edition) and operating system.

## OpenProject Core Edition

### Debian 7.6 Wheezy 64bits server

    echo "deb https://deb.packager.io/gh/opf/openproject wheezy stable/4.2" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject
    sudo openproject configure

### Ubuntu 14.04 Trusty 64bits server

    echo "deb https://deb.packager.io/gh/opf/openproject trusty stable/4.2" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject
    sudo openproject configure

### Fedora 20 64bits server

    echo "[openproject]
    name=Repository for opf/openproject application.
    baseurl=https://rpm.packager.io/gh/opf/openproject/fedora20/stable/4.2
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject
    sudo openproject configure

### CentOS / RHEL 6 64 bits server

    echo "[openproject]
    name=Repository for opf/openproject application.
    baseurl=https://rpm.packager.io/gh/opf/openproject/centos6/stable/4.2
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject
    sudo openproject configure

### SUSE Linux Enterprise Server 12

    sudo zypper addrepo "https://rpm.packager.io/gh/opf/openproject/sles12/stable/4.2" "openproject"
    sudo zypper install openproject
    sudo openproject configure

## OpenProject Community Edition

### Debian 7.6 Wheezy 64bits server

    echo "deb https://deb.packager.io/gh/finnlabs/pkgr-openproject-community wheezy stable/4.2" | sudo tee /etc/apt/sources.list.d/pkgr-openproject-community.list
    sudo apt-get update
    sudo apt-get install openproject-ce
    sudo openproject-ce configure

### Ubuntu 14.04 Trusty 64bits server

    echo "deb https://deb.packager.io/gh/finnlabs/pkgr-openproject-community trusty stable/4.2" | sudo tee /etc/apt/sources.list.d/pkgr-openproject-community.list
    sudo apt-get update
    sudo apt-get install openproject-ce
    sudo openproject-ce configure

### Fedora 20 64bits server

    echo "[pkgr-openproject-community]
    name=Repository for finnlabs/pkgr-openproject-community application.
    baseurl=https://rpm.packager.io/gh/finnlabs/pkgr-openproject-community/fedora20/stable/4.2
    enabled=1" | sudo tee /etc/yum.repos.d/pkgr-openproject-community.repo
    sudo yum install openproject-ce
    sudo openproject-ce configure

### CentOS / RHEL 6 64 bits server

    echo "[pkgr-openproject-community]
    name=Repository for finnlabs/pkgr-openproject-community application.
    baseurl=https://rpm.packager.io/gh/finnlabs/pkgr-openproject-community/centos6/stable/4.2
    enabled=1" | sudo tee /etc/yum.repos.d/pkgr-openproject-community.repo
    sudo yum install openproject-ce
    sudo openproject-ce configure

### SUSE Linux Enterprise Server 12

    sudo zypper addrepo "https://rpm.packager.io/gh/finnlabs/pkgr-openproject-community/sles12/stable/4.2" "pkgr-openproject-community"
    sudo zypper install openproject-ce
    sudo openproject-ce configure

