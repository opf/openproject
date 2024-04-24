FROM node:20.9
MAINTAINER operations@openproject.com

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=node

RUN apt-get update && apt-get install -y chromium

ENV CHROME_BIN=/usr/bin/chromium

RUN npm i -g npm

RUN groupadd $USER || true
RUN groupmod -g $DEV_GID $USER || true
RUN usermod -u $DEV_UID -d /home/dev $USER || true

EXPOSE 4200

RUN mkdir -p /home/dev/openproject/public/assets/frontend
RUN chown $USER:$USER -R /home/dev

VOLUME ["/home/dev/openproject", "/home/dev/openproject/public/assets/frontend"]

WORKDIR /home/dev/openproject/frontend

USER $USER
