FROM ruby:2.7.1-buster as develop
MAINTAINER operations@openproject.com

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=dev
ENV RAILS_ENV=development

ENV BUNDLER_VERSION "2.0.2"

RUN useradd -d /home/$USER -m $USER
RUN usermod -u $DEV_UID $USER
RUN groupmod -g $DEV_GID $USER

WORKDIR /home/$USER

RUN gem install bundler --version "${bundler_version}" --no-document

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql-client

COPY ./backend/scripts/seed /usr/sbin/seed
COPY ./backend/scripts/run-app /usr/sbin/run-app

EXPOSE 3000

VOLUME ["/usr/local/bundle", "/home/$USER/openproject"]

WORKDIR /home/$USER/openproject

USER $USER

ENTRYPOINT ["/bin/sh", "-c"]

####### Testing image below #########

FROM develop as test

USER root

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    chromium 

USER $USER
