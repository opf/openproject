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

```shell
openproject config:set DATABASE_URL=postgres://user:pass@host:port/dbname
```

Then, you need to run `openproject reconfigure` and select "Skip" for the database wizard. Otherwise the wizard will override your DATABASE_URL environment variable again.

## Docker-based installation

If you run the all-in-one container, you can simply pass a custom `DATABASE_URL` environment variable on the docker command-line, which could
point to an external database.

Example:

```shell
docker run -d ... -e DATABASE_URL=postgres://user:pass@host:port/dbname openproject/openproject:14
```

Best practice is using the file `docker-compose.override.yml`. If you run the Compose based docker stack, you can simply override the `DATABASE_URL` environment variable, and remove the `db` service from the `docker-compose.yml` file, but because by pulling a new version `docker-compose.yml` might get replaced. Then you can restart the stack with:

```shell
docker-compose down
docker-compose up -d
```

In both cases the seeder will be run when you (re)launch OpenProject to make sure that the database gets the migrations and demo data as well.

## Setting DATABASE_URL and options separately

OpenProject will merge the settings from `DATABASE_URL` with manually specified environment options. Here are the supported options:

| Environment variable               | Default     | Description                                                           | Documentation                                                                            |
|------------------------------------|-------------|-----------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| DATABASE_URL<br>OPENPROJECT_DB_URL | *none*      | URL style passing of database options                                 | https://guides.rubyonrails.org/configuring.html#configuring-a-database                   |
| OPENPROJECT_DB_ENCODING            | unicode     | Encoding of the database                                              | Should be left at unicode unless you really know what you're doing.                      |
| OPENPROJECT_DB_POOL                | *none*      | Connection pool count                                                 | https://guides.rubyonrails.org/configuring.html#database-pooling                         |
| OPENPROJECT_DB_USERNAME            | *none*      | Database username, if not presented in URL above                      | https://guides.rubyonrails.org/configuring.html#configuring-a-database                   |
| OPENPROJECT_DB_PASSWORD            | *none*      | Database password, if not presented in URL above                      | https://guides.rubyonrails.org/configuring.html#configuring-a-database                   |
| OPENPROJECT_DB_APPLICATION_NAME    | openproject | PostgreSQL application name option                                    | https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-APPLICATION-NAME     |
| OPENPROJECT_DB_STATEMENT_TIMEOUT   | 90s         | Default statement timeout before connection statements are terminated | https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-STATEMENT-TIMEOUT |

## Using SSL/TLS with a PostgreSQL database

By default, the packaged installation installs a local database and does not use SSL encryption. If you provide a custom PostgreSQL database that supports SSL/TLS connections for servers and/or clients, you can pass the options as part of the DATABASE_URL. See the above guides on how to set this environment variable for Docker or packaged installations.

The most import option is the `sslmode` parameter. Set this to the appropriate mode as defined in the [PostgreSQL documentation](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-PARAMKEYWORDS). For example, to require a SSL connection with full verification of the server certificate, you can add it to the database URL:

```shell
DATABASE_URL=postgres://user:pass@host:port/dbname?sslmode=require-full&sslcert=/path/to/postgresql.cert
```

Alternatively, for better readability, you can set these parameters with separate environment variables:

| Environment variable          | Default                      | Description                                                  | PostgreSQL documentation                                     |
| ----------------------------- | ---------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| OPENPROJECT_DB_SSLMODE        | prefer                       | connection mode for SSL. See                                 | [sslmode](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLMODE) |
| OPENPROJECT_DB_SSLCOMPRESSION | 0                            | If set to 1, data sent over SSL connections will be compressed | [sslcompression](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLCOMPRESSION) |
| OPENPROJECT_DB_SSLCERT        | ~/.postgresql/postgresql.crt | Path to certificate                                          | [sslcert](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLCERT) |
| OPENPROJECT_DB_SSLKEY         | ~/.postgresql/postgresql.key | Path to certificate key                                      | [sslkey](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLKEY) |
| OPENPROJECT_DB_SSLPASSWORD    |                              | Password to certificate key                                  | [sslpassword](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLPASSWORD) |
| OPENPROJECT_DB_SSLROOTCERT    | ~/.postgresql/root.crt       | Path to CA                                                   | [sslrootcert](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLROOTCERT) |
| OPENPROJECT_DB_SSLCRL         | ~/.postgresql/root.crl       | Path to revocation list                                      | [sslcrl](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-CONNECT-SSLCRL) |

```text
="prefer" # disable, allow, prefer, require, verify-ca, verify-full
="0" # 0 or 1
="~/.postgresql/postgresql.crt" # Path to the certificate
="~/.postgresql/postgresql.key" # Path to the certificate private key
="" # Password for the certificate key, if any
="~/.postgresql/root.crt" # Path to CA
="~/.postgresql/root.crl" # Path to revocation list
```

PostgreSQL supports a wide variety of options in its connection string. This is not specific to OpenProject or Rails. See the following guide for more information: https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-PARAMKEYWORDS
