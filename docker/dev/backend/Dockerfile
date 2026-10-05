# syntax=docker/dockerfile:1
FROM ruby:4.0.7-trixie AS develop
LABEL org.opencontainers.image.authors="operations@openproject.com"

ARG DEV_UID=1000
ARG DEV_GID=1001
ARG NODE_MAJOR=24

ENV USER=dev
ENV RAILS_ENV=development

# `--no-log-init` is required as a workaround to avoid disk exhaustion.
#
# Read more at:
# * https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
# * https://github.com/golang/go/issues/13548
RUN useradd --no-log-init -d /home/$USER -m -u $DEV_UID $USER && \
  (groupmod -g $DEV_GID $USER || true)

# System packages in a single layer that only depends on the arguments above:
# * postgresql-client-17 from PGDG
# * nodejs, needed by scripts such as `./script/api/validate_spec`
# * openjdk, needed by https://github.com/NUARIG/ladle for LDAP specs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  wget gnupg lsb-release curl ca-certificates && \
  mkdir -p /etc/apt/keyrings && \
  wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
  apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  postgresql-client-17 libffi8 libffi-dev nodejs openjdk-21-jdk

RUN mkdir -p /usr/local/bundle /home/$USER/openproject/tmp && \
  chown $USER:$USER /usr/local/bundle /home/$USER/openproject/tmp

# Scripts change most often, so they come last to keep the layers above cached.
COPY ./docker/dev/backend/scripts/setup /usr/sbin/setup
COPY ./docker/dev/backend/scripts/setup-bim /usr/sbin/setup-bim
COPY ./docker/dev/backend/scripts/run-app /usr/sbin/run-app

EXPOSE 3000

VOLUME [ "/usr/local/bundle", "/home/$USER/openproject", "/home/$USER/openproject/tmp" ]

WORKDIR /home/$USER/openproject

USER $USER

RUN gem install bundler --no-document

####### Testing image below #########

FROM develop AS test

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends jq

COPY ./docker/dev/backend/scripts/run-test /usr/bin/run-test
COPY ./docker/dev/backend/scripts/setup-tests /usr/bin/setup-tests

ENTRYPOINT [ "run-test" ]
