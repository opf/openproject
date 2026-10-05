# syntax=docker/dockerfile:1
FROM node:24.18.0
LABEL org.opencontainers.image.authors="operations@openproject.com"

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=node

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  apt-get update -qq && apt-get install -y --no-install-recommends chromium

ENV CHROME_BIN=/usr/bin/chromium

RUN --mount=type=cache,target=/root/.npm,sharing=locked \
  npm i -g npm@11.3.0

RUN (groupadd $USER || true) && \
  (groupmod -g $DEV_GID $USER || true) && \
  (usermod -u $DEV_UID -d /home/dev $USER || true)

EXPOSE 4200

RUN mkdir -p /home/dev/openproject/public/assets/frontend && \
  chown -R $USER:$USER /home/dev

VOLUME ["/home/dev/openproject", "/home/dev/openproject/public/assets/frontend"]

WORKDIR /home/dev/openproject/frontend

USER $USER
