#!/bin/bash

# Dump missing data from backup.
# This assumes you restored the correct backup into a database called `openproject_backup`.
cat dump.sql | psql -d openproject_backup
pg_dump -d openproject_backup -t 'missing_*' -f missing_data.sql

# Restore missing data in current database.
# This assumes your current OpenProject database is called `openproject`.
cat missing_data.sql | psql -d openproject
cat restore.sql | psql -d openproject
