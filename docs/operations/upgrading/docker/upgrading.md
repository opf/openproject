# Upgrade your OpenProject installation (Docker)

Upgrading a Docker container is easy. First, pull the latest version of the image:

    docker pull openproject/community:latest

Then stop and remove your existing container:

    docker stop openproject
    docker rm openproject

Finally, re-launch the container in the same way you launched it previously.
This time, it will use the new image:

    docker run -d ... openproject/community:latest


# Upgrade Notes

## OpenProject 9.x

### MySQL is being deprecated

OpenProject 9.0 is deprecating MySQL support. You can expect full MySQL support for the course of 9.0 releases, but we
are likely going to be dropping MySQL completely in one of the following releases.

For more information regarding motivation behind this and migration steps, please see https://www.openproject.org/deprecating-mysql-support/
In this post, you will find documentation for a mostly-automated migration script to PostgreSQL to help you get up and running with PostgreSQL.
