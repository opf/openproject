# Migrating your Docker OpenProject database to PostgreSQL

This guide will migrate your all-in-one docker-based MySQL installation to a PostgreSQL installation using [pgloader](https://github.com/dimitri/pgloader). 

## Backing up

Before beginning the migration, please ensure you have created a backup of your current installation. Please follow our [backup and restore guides](../../operation) for Docker-based installations.

## Built-in migration script

The Dockerfile comes with a built-in PostgreSQL migration script that will auto-run and inform you what to do.

### Set up a PostgreSQL database

Depending on your usage, you may want to set up an external PostgreSQL database to provide the container with connection details just like you did for MySQL.

In any case, you may also use the internally configured PostgreSQL instance of the docker container by using the DATABASE_URL ` postgres://openproject:openproject@127.0.0.1/openproject`

**Installing a PostgreSQL database outside docker**

If you want to set up a PostgreSQL installation database outside the container and not use the built-in database, please set up a PostgreSQL database now. These are generic apt-based installation steps, please adapt them appropriately for your distribution.

OpenProject requires at least PostgreSQL 9.5 installed. Please check <https://www.postgresql.org/download/> if your distributed package is too old.

```bash
[root@host] apt-get install postgresql postgresql-contrib libpq-dev
```

Once installed, switch to the PostgreSQL system user.

```bash
[root@host] su - postgres
```

Then, as the PostgreSQL user, create the system user for OpenProject. This will prompt you for a password. We are going to assume in the following guide that password were 'openproject'. Of course, please choose a strong password and replace the values in the following guide with it!

```bash
[postgres@host] createuser -W openproject
```

Next, create the database owned by the new user

```bash
[postgres@host] createdb -O openproject openproject
```

Lastly, exit the system user

```bash
[postgres@host] exit
# You will be root again now.
```



### Setting environment variables

To run the migration part of the image, you will have to provide two environment files:



### The MYSQL_DATABASE_URL

Note down or copy the current MySQL `DATABASE_URL`

```bash
# Will look something of the kind
# mysql2://user:password@localhost:3306/dbname

# Pass into the container but replace mysql2 with mysql!
MYSQL_DATABSAE_URL="mysql://user:password@localhost:3306/dbname"
```



**Please note:** Ensure that the URL starts with `mysql://` , not with ` mysql2://` !


### The PostgreSQL DATABASE_URL

Pass in `DATABASE_URL` pointing to your new PostgreSQL database. This is either the default `postgres://openproject:openproject@127.0.0.1/openproject` or if you set up a PostgreSQL installation above, use credentials for your installation you set up above.

```bash
POSTGRES_DATABASE_URL="postgresql://<USER>:<PASSWORD>@<HOST>/<Database name>"
```


### Adapting the hostname

**Note:** Depending on your docker installation and networking, you may need to replace the hostname `localhost` in the database URLs
with `host.docker.internal` to access the docker host. On Mac for example, localhost will refer to the docker client.


### Running the migration

To run the migration script within the container, now simply run the following command, replacing the content of the environment variables with your actual values.


```bash
docker run -it \
  -e MYSQL_DATABASE_URL="mysql://user:password@localhost:3306/dbname" \
  -e DATABASE_URL="postgresql://openproject:<PASSWORD>@localhost:5432/openproject" \
  openproject/community:latest
```


This will perform all necessary steps to perform the migration. Afterwards, simply remove the `MYSQL_DATABASE_URL`environment variable again and start your container as usual.
