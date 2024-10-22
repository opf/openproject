FROM ruby:3.3.4-bullseye AS develop
MAINTAINER operations@openproject.com

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=dev
ENV RAILS_ENV=development
ENV NODE_MAJOR=20

ENV BUNDLER_VERSION "2.5.13"

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
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql-client libffi7 libffi-dev curl

# Setup node source and install nodejs. Needed for running certain scripts in backend container,
# as the `./scripts/api/validate_spec`.
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update
RUN apt-get install -y nodejs

# Install watchexec for continuous test execution.
# Usage:
# - Add the following line to your ~/.bashrc ("dcrw" stands for "Docker Compose Rspec Watch"):
# dcrw() { docker compose exec backend-test watchexec --exts rb,erb -- bin/rspec --order defined --format documentation --fail-fast $1; }
# - and then use it like this:
# dcrw <path-to-your-spec-file>
RUN curl -fsSL https://apt.cli.rs/pubkey.asc | tee -a /usr/share/keyrings/rust-tools.asc
RUN curl -fsSL https://apt.cli.rs/rust-tools.list | tee /etc/apt/sources.list.d/rust-tools.list
RUN apt update
RUN apt install watchexec-cli

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

RUN gem install bundler --version "${BUNDLER_VERSION}" --no-document

####### Testing image below #########

FROM develop AS test

USER root

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    jq

COPY ./docker/dev/backend/scripts/run-test /usr/bin/run-test
COPY ./docker/dev/backend/scripts/setup-tests /usr/bin/setup-tests

ENTRYPOINT [ "run-test" ]
