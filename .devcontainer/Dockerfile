FROM ruby:4.0.7-trixie
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
RUN useradd --no-log-init -d "/home/${USER}" -m "${USER}"

RUN usermod -u "${DEV_UID}" "${USER}"
RUN groupmod -g "${DEV_GID}" "${USER}" || true
RUN gpasswd -a "${USER}" sudo

WORKDIR "/home/${USER}"

RUN apt update -qq
RUN apt upgrade
RUN apt install -y wget gnupg lsb-release curl sudo screen
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt update
RUN apt install -y nodejs openjdk-21-jdk chromium postgresql-client libffi8 libffi-dev

RUN <<EOT
cat >/etc/sudoers <<EOF
Defaults	env_reset
Defaults	mail_badpass
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

%sudo	ALL=(ALL:ALL) NOPASSWD: ALL
EOF
EOT

ENV CHROME_BIN=/usr/bin/chromium

RUN mkdir -p /usr/local/bundle
RUN chown "${USER}:${USER}" /usr/local/bundle

EXPOSE 3000
EXPOSE 4200

VOLUME [ "/usr/local/bundle", "/home/${USER}/openproject", "/home/${USER}/openproject/tmp" ]

WORKDIR "/home/${USER}/openproject"

