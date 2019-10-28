# Backup your OpenProject installation (Docker)

Note: this guide only applies if you've installed OpenProject with our Docker image.

If you've followed the steps described in the installation guide for Docker,
then you just need to make a backup of the exported volumes, at your
convenience. As a reminder, here is the recommended way to launch OpenProject
with Docker:

    sudo mkdir -p /var/lib/openproject/{pgdata,logs,static}

    docker run -d -p 8080:80 --name openproject -e SECRET_KEY_BASE=secret \
      -v /var/lib/openproject/pgdata:/var/lib/postgresql/9.6/main \
      -v /var/lib/openproject/logs:/var/log/supervisor \
      -v /var/lib/openproject/static:/var/db/openproject \
      openproject/community:8

If you're using the same local directories than the above command, then you
just need to backup your local `/var/lib/openproject` folder (for instance to
S3 or FTP).

If at any point you want to restore from a backup, just put your backup in
`/var/lib/openproject` on your local host, and re-launch the docker container.

## Dumping the database

**Note:** this only applies for the self-contained OpenProject container not using
an external database but instead a database right in the container.

If you need a SQL dump of your database straight from the container you can do the
following to dump it into the current directory:

```
docker exec $CONTAINER_ID bash -c \
  'export PGPASSWORD=openproject && pg_dump -U openproject -h 127.0.0.1' \
  > openproject.sql
```

If you don't know the container id (or name) you can find it out using `docker ps`.
