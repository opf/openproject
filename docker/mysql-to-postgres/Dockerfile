FROM ruby:2.6-stretch
MAINTAINER operations@openproject.com

ENV PGLOADER_DEPENDENCIES "libsqlite3-dev make curl gawk freetds-dev libzip-dev"

# Install
#
#  1) mysql and postgres clients
#  2) pgloader dependencies minus SBCL since we use CCL
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-client postgresql-client \
    $PGLOADER_DEPENDENCIES && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# pgloader
ENV CCL_DEFAULT_DIRECTORY /opt/ccl
COPY docker/mysql-to-postgres/bin/build /tmp/build-pgloader
RUN /tmp/build-pgloader && rm /tmp/build-pgloader
COPY docker/mysql-to-postgres/bin/migrate-mysql-to-postgres /usr/local/bin/

CMD ["migrate-mysql-to-postgres"]
