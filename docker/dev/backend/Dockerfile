FROM ruby:4.0.2-trixie AS develop
LABEL org.opencontainers.image.authors="operations@openproject.com"

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=dev
ENV RAILS_ENV=development
ENV NODE_MAJOR=22

# `--no-log-init` is required as a workaround to avoid disk exhaustion.
#
# Read more at:
# * https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
# * https://github.com/golang/go/issues/13548
RUN useradd --no-log-init -d /home/$USER -m $USER

RUN usermod -u $DEV_UID $USER
RUN groupmod -g $DEV_GID $USER || true

WORKDIR /home/$USER

RUN apt-get update -qq && \
  apt-get install -y wget gnupg lsb-release curl && \
  echo "deb [signed-by=/usr/share/keyrings/postgrsql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgrsql.gpg - && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  postgresql-client-17 libffi8 libffi-dev curl && \
  rm -rf /var/lib/apt/lists/*

# Setup node source and install nodejs. Needed for running certain scripts in backend container,
# as the `./script/api/validate_spec`.
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update
RUN apt-get install -y nodejs

# Setup java. Needed for https://github.com/NUARIG/ladle which is used in specs to test LDAP related behavior.
RUN apt-get install -y openjdk-21-jdk

COPY ./docker/dev/backend/scripts/setup /usr/sbin/setup
COPY ./docker/dev/backend/scripts/setup-bim /usr/sbin/setup-bim
COPY ./docker/dev/backend/scripts/run-app /usr/sbin/run-app

# The following lines are needed to make sure the file permissions are setup correctly after the volumes are mounted
RUN mkdir -p /home/$USER/openproject/tmp
RUN mkdir -p /usr/local/bundle
RUN chown $USER:$USER /usr/local/bundle
RUN chown $USER:$USER /home/$USER/openproject/tmp

EXPOSE 3000

VOLUME [ "/usr/local/bundle", "/home/$USER/openproject", "/home/$USER/openproject/tmp" ]

WORKDIR /home/$USER/openproject

USER $USER

RUN gem install bundler --no-document

####### Testing image below #########

FROM develop AS test

USER root

RUN apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  jq

COPY ./docker/dev/backend/scripts/run-test /usr/bin/run-test
COPY ./docker/dev/backend/scripts/setup-tests /usr/bin/setup-tests

ENTRYPOINT [ "run-test" ]
