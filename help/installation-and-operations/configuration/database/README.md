---
sidebar_navigation:
  title: Configuring a custom database server
  priority: 6
---

# Configuring a custom database server

## Package-based installation

Simply run `sudo openproject reconfigure`, and when the database wizard is displayed, select the **Use an existing PostgreSQL database** option and fill in the required details ([cf the initial configuration section](../../installation/packaged/#step-1-postgresql-database-configuration))

## Docker-based installation

You can simply pass a custom `DATABASE_URL` environment variable on the
docker command-line, which could point to an external database.

Example:

```bash
docker run -d ... -e DATABASE_URL=mysql2://user:pass@host:port/dbname openproject/community:10
```

The docker image will make sure that the database gets the migrations and demo
data as well.
