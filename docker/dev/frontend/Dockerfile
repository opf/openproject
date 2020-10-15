FROM node:10.15
MAINTAINER operations@openproject.com

ARG DEV_UID=1000
ARG DEV_GID=1001

ENV USER=dev

RUN usermod -l $USER -d /home/$USER -m node
RUN usermod -u $DEV_UID $USER
RUN groupadd $USER
RUN groupmod -g $DEV_GID $USER

EXPOSE 4200

VOLUME ["/home/$USER/openproject"]

WORKDIR /home/$USER/openproject/frontend

USER $USER
