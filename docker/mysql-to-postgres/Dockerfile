FROM ruby:2.6-stretch
MAINTAINER operations@openproject.com

# Install
#
#  1) mysql and postgres clients
#  2) pgloader dependencies minus SBCL since we use CCL
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-client postgresql-client \
    libsqlite3-dev make curl gawk freetds-dev libzip-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# install Clozure CL to avoid memory issues with the standard SBCL
RUN cd /opt && \
  wget https://github.com/Clozure/ccl/releases/download/v1.11.5/ccl-1.11.5-linuxx86.tar.gz && \
  tar -xzf ccl-1.11.5-linuxx86.tar.gz && \
  rm ccl-1.11.5-linuxx86.tar.gz && \
  ln -s /opt/ccl/scripts/ccl64 /usr/local/bin/ccl

ENV CCL_DEFAULT_DIRECTORY /opt/ccl

# build pgloader from source using CCL as the lisp runtime
RUN cd /opt && \
  git clone https://github.com/dimitri/pgloader.git && \
  cd pgloader && \
  make CL=ccl pgloader && \
  mv /opt/pgloader/build/bin/pgloader /usr/local/bin/pgloader && \
  rm -rf /opt/pgloader

COPY bin/migrate-mysql-to-postgres /usr/local/bin/

CMD ["migrate-mysql-to-postgres"]
