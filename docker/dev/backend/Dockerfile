FROM ruby:3.2.0-bullseye as develop
MAINTAINER operations@openproject.com

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=dev
ENV RAILS_ENV=development

ENV BUNDLER_VERSION "2.4.1"

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
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

COPY ./docker/dev/backend/scripts/setup /usr/sbin/setup
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

FROM develop as test

USER root

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    jq

COPY ./docker/dev/backend/scripts/run-test /usr/bin/run-test
COPY ./docker/dev/backend/scripts/setup-tests /usr/bin/setup-tests

ENTRYPOINT [ "run-test" ]
