---
sidebar_navigation:
  title: Configuring a custom database server
  priority: 6
---

# Configuring a custom database server

## Package-based installation

Simply run `sudo openproject reconfigure`, and when the database wizard is displayed, select the **Use an existing PostgreSQL database** option and fill in the required details ([cf the initial configuration section](../../installation/packaged/#step-2-postgresql-database-configuration)).



### Setting a custom database URL

In some cases, you need flexibility in how you define the URL (e.g., specifying more options specific to PostgreSQL or using SSL certificates). In that case, you can pass the database URL as an environment variable instead:

```bash
openproject config:set DATABASE_URL=postgres://user:pass@host:port/dbname
```



Then, you need to run `openproject reconfigure` and select "Skip" for the database wizard. Otherwise the wizard will override your DATABASE_URL environment variable again.



## Docker-based installation

If you run the all-in-one container, you can simply pass a custom `DATABASE_URL` environment variable on the docker command-line, which could
point to an external database.

Example:

```shell
docker run -d ... -e DATABASE_URL=postgres://user:pass@host:port/dbname openproject/community:13
```

Best practice is using the file `docker-compose.override.yml`. If you run the Compose based docker stack, you can simply override the `DATABASE_URL` environment variable, and remove the `db` service from the `docker-compose.yml` file, but because by pulling a new version `docker-compose.yml` might get replaced. Then you can restart the stack with:

```shell
docker-compose down
docker-compose up -d
```

In both cases the seeder will be run when you (re)launch OpenProject to make sure that the database gets the migrations and demo data as well.



## Using SSL/TLS with a PostgreSQL database

By default, the packaged installation installs a local database and does not use SSL encryption. If you provide a custom PostgreSQL database that supports SSL/TLS connections for servers and/or clients, you can pass the options as part of the DATABASE_URL. See the above guides on how to set this environment variable for Docker or packaged installations.

The most import option is the `sslmode` parameter. Set this to the appropriate mode as defined in the [PostgreSQL documentation](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-PARAMKEYWORDS). For example, to require a SSL connection with full verification of the server certificate, use these parameters:

```bash
DATABASE_URL=postgres://user:pass@host:port/dbname?sslmode=require-full&sslcert=/path/to/postgresql.cert
```



PostgreSQL supports a wide variety of options in its connection string. This is not specific to OpenProject or Rails. See the following guide for more information: https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-PARAMKEYWORDS
