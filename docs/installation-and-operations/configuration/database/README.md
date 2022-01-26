---
sidebar_navigation:
  title: Configuring a custom database server
  priority: 6
---

# Configuring a custom database server

## Package-based installation

Simply run `sudo openproject reconfigure`, and when the database wizard is displayed, select the **Use an existing PostgreSQL database** option and fill in the required details ([cf the initial configuration section](../../installation/packaged/#step-2-postgresql-database-configuration))

## Docker-based installation

If you run the all-in-one container, you can simply pass a custom
`DATABASE_URL` environment variable on the docker command-line, which could
point to an external database.

Example:

```bash
docker run -d ... -e DATABASE_URL=postgres://user:pass@host:port/dbname openproject/community:11
```

If you run the Compose based docker stack, you can simply override the `DATABASE_URL` environment variable, and remove the `db` service from the `docker-compose.yml` file. Then you can restart the stack with:

```
docker-compose down
docker-compose up -d
```

In both cases the seeder will be run when you (re)launch OpenProject to make sure that the database gets the migrations and demo data as well.
