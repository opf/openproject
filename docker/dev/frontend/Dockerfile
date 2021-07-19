FROM node:14.17
MAINTAINER operations@openproject.com

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=dev

RUN apt-get update && apt-get install -y chromium

RUN npm i -g npm

# `--no-log-init` is required as a workaround to avoid disk exhaustion.
#
# Read more at:
# * https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
# * https://github.com/golang/go/issues/13548
RUN useradd --no-log-init -d /home/$USER -m $USER -g node || true

RUN usermod -u $DEV_UID $USER || true
RUN groupadd $USER || true
RUN groupmod -g $DEV_GID $USER || true

EXPOSE 4200

RUN mkdir -p /home/$USER/openproject/public/assets/frontend
RUN chown $USER:$USER -R /home/$USER/openproject/public

VOLUME ["/home/$USER/openproject", "/home/$USER/openproject/public/assets/frontend"]

WORKDIR /home/$USER/openproject/frontend

USER $USER
