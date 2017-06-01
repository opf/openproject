
We strongly suggest installing OpenProject using our RPM/Deb packages.
The packages provide a fast and reliable method to get started with OpenProject, as well as upgrading your installation to the latest version.

The package contains an interactive wizard that will configure your environment with all necessary dependencies (Ruby, Node, database setup, Apache setup, and integrations with OpenpProject).


# OpenProject Packaged Installation Guide

The installation procedure assumes the following prerequisites:

* A server running one of the Linux distributions listed in the [system requirements](./system-requirements.md).
* A mail server that is accessible via SMTP that can be used for sending
  notification emails.
* If you intend to use SSL for OpenProject: A valid SSL certifificate along
  with the private key file. The key MUST NOT be protected by a passphrase,
otherwise the Apache server won't be able to read it when it starts.

The package will set up:

* Apache 2 (web server) – this component provides the external interface,
  handles SSL termination (if SSL is used) and distributes/forwards web
requests to the Unicorn processes.
* MySQL (database management system) – this component is used to store and
  retrieve data. We do support PostgreSQL as well, but it is not part of the automatic wizard. To configure this instead, see below.
* Unicorn (application server) – this component hosts the actual application.
  By default, there is two unicorn processes running in parallel on the app
server machine.
* Ruby 2.2 (MRI) and necessary libraries to run the OpenProject source code.

