# System Requirements

__Note__: The configurations described below are what we use and test against.
This means that other configurations might also work but we do not
provide any official support for them.

## Server

### Hardware

* __Memory:__ 512 MB (1024 recommended)
* __Free disc space:__ 300 MB (4096 recommended)

### Operating System

| Distribution (64 bits only)     | Identifier   | init system |
| :------------------------------ | :----------- | :---------- |
| Ubuntu 14.04 Trusty             | ubuntu-14.04 | upstart     |
| Debian 8 Jessie                 | debian-8     | systemd     |
| Debian 7 Wheezy                 | debian-7     | sysvinit    |
| CentOS/RHEL 7.x                 | centos-7     | systemd     |
| CentOS/RHEL 6.x                 | centos-6     | upstart     |
| Fedora 20                       | fedora-20    | sysvinit    |
| Suse Linux Enterprise Server 12 | sles-12      | sysvinit    |

### Dependencies

* __Runtime:__ [Ruby](https://www.ruby-lang.org/en/) Version 2.1.6
* __Webserver:__ [Apache](http://httpd.apache.org/)
  or [nginx](http://nginx.org/en/docs/)
* __Application server:__ [Phusion Passenger](https://www.phusionpassenger.com/)
  or [Unicorn](http://unicorn.bogomips.org/)
* __Database:__ [MySQL](https://www.mysql.com/) Version >= 5.6
  or [PostgreSQL](http://www.postgresql.org/) Version >= 9.1

Please be aware that the dependencies listed above also have a lot of
dependencies themselves.

## Client

OpenProject supports the latest versions of the major browsers. In our
strive to make OpenProject easy and fun to use we had to drop support
for some older browsers.

* [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/products/) (Version >= 31 ESR)
* [Microsoft Internet
  Explorer](http://windows.microsoft.com/en-us/internet-explorer/download-ie) (Version >= 10)
* [Google Chrome](https://www.google.com/chrome/browser/desktop/)

## Screen reader support (accessibility)

* [JAWS](http://www.freedomscientific.com/Products/Blindness/JAWS) >= 14.0
