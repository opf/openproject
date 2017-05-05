# System requirements

__Note__: The configurations described below are what we use and test against.
This means that other configurations might also work but we do not
provide any official support for them.

## Server

### Hardware

* __Memory:__ 512 MB (1024 recommended)
* __Free disc space:__ 300 MB (4096 recommended)

### Operating system

| Distribution (64 bits only)     | Identifier   | init system |
| :------------------------------ | :----------- | :---------- |
| CentOS/RHEL 7.x                 | centos-7     | systemd     |
| Debian 7 Wheezy                 | debian-7     | sysvinit    |
| Debian 8 Jessie                 | debian-8     | systemd     |
| Suse Linux Enterprise Server 11 | sles-11      | sysvinit    |
| Suse Linux Enterprise Server 12 | sles-12      | sysvinit    |
| Ubuntu 14.04 Trusty Tahr        | ubuntu-14.04 | upstart     |
| Ubuntu 16.04 Xenial Xerus       | ubuntu-16.04 | upstart     |


### Dependencies

* __Runtime:__ [Ruby](https://www.ruby-lang.org/en/) Version >= 2.4.1
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

* [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/products/) (Version >= 45 ESR)
* [Microsoft Egde](https://www.microsoft.com/de-de/windows/microsoft-edge)
* [Google Chrome](https://www.google.com/chrome/browser/desktop/)

## Screen reader support (accessibility)

* [JAWS](http://www.freedomscientific.com/Products/Blindness/JAWS) >= 17.0
