## OpenProject PostgreSQL migration guide to 9.6

This guide will lead you to the steps of upgrading your system PostgreSQL version to 9.6.
OpenProject 7.4.0 requires PostgreSQL 9.5+, so we're recommending to install to 9.6 directly.

If you're upgrading to 7.4.0 without a 9.5+ database, your upgrade process will be terminated with a 'Database incompatibility warning'. You should not 

Since Ubuntu 14.04 (still supported by OpenProject) is still running on PostgreSQL 9.3., we're showing the 
upgrade process for this distribution. Debian oldstable also uses PostgreSQL 9.4. as well.

### Preparations for the upgrade

Stop the current OpenProject workers

``` bash
service openproject stop
```

### Install the newer PostgreSQL version

For Ubuntu 14.04:

```bash
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.6
```


For other versions of Ubuntu, see this answer on AskUbuntu:
https://askubuntu.com/questions/831292

Or check the download for repositories from PostgreSQL:
https://www.postgresql.org/download/


### Upgrade of PostgreSQL


 Stop the old cluster:
 
 ``` bash
 pg_dropcluster 9.6 main --stop
 ```
 
 Upgrade the cluster to 9.6
 
 ``` bash 
 pg_upgradecluster -v 9.6 9.3 main
 ```
 
 Remove the old cluster
 
 ``` bash
 pg_dropcluster 9.3 main
 ```
 
 Lastly, remove the ubuntu-provided version of 9.3:
 
 ``` bash 
 apt-get remove postgres postgresql-9.3
 ```
 
 
 ### Upgrade OpenProject