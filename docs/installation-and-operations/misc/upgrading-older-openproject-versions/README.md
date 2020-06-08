# Migrating from an old MySQL database

The script described above requires at least OpenProject 8 to work properly. If you are still on an older OpenProject version you have to migrate to OpenProject 8 first.

To make this easier there is a script which automates that too. It's included in the docker image itself but will want to run it directly on the docker host. To do that you can either copy it onto your system from `/app/script/migration/migrate-from-pre-8.sh` or simply download it [here](https://github.com/opf/openproject/tree/dev/script/migration/migrate-from-pre-8.sh).

All the script needs is a docker installation. It will start containers as required for the migration and clean them up afterwards. The result of the migration will be a SQL dump of OpenProject in the current version (10.3). This can then be imported into the actual OpenProject setup.

## Usage

With docker installed, use the following command to start the upgrade process on your MySQL dump.

```bash
bash migrate-from-pre-8.sh <docker host IP> <MySQL dump>"
```
