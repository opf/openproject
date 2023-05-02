FROM ruby:3.2.1-buster AS slim
LABEL org.opencontainers.image.authors="operations@openproject.com"

# Allow platform-specific additions. Valid values are: on-prem,saas,bahn
ARG PLATFORM=on-prem
# Use OAuth token in case private gems need to be fetched
ARG GITHUB_OAUTH_TOKEN
ARG DEBIAN_FRONTEND=noninteractive

# Unprivileged user settings
ENV APP_USER=app
ENV APP_PATH=/app
ENV APP_DATA_PATH=/var/openproject/assets

# Package manager settings
ENV NODE_VERSION="16.17.0"
ENV BUNDLER_VERSION="2.4.10"

# Postgres settings
ENV PGDATA=/var/openproject/pgdata
ENV PGVERSION="13"
ENV PGBIN="/usr/lib/postgresql/$PGVERSION/bin"

# Rails settings
ENV RAILS_ENV=production
ENV RAILS_GROUPS=production
ENV RAILS_LOG_TO_STDOUT=1
ENV RAILS_SERVE_STATIC_FILES=1
# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE=OVERWRITE_ME

# OpenProject settings
ENV OPENPROJECT_ATTACHMENTS__STORAGE__PATH=$APP_DATA_PATH/files
# Valid values are: standard,bim
ENV OPENPROJECT_EDITION=standard
ENV OPENPROJECT_INSTALLATION__TYPE=docker

WORKDIR $APP_PATH

RUN useradd -d /home/$APP_USER -m $APP_USER

COPY . .

# setup all dependencies
RUN \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=$APP_PATH/vendor/bundle/ruby/3.2.0/cache \
  ./docker/prod/setup/deps-common.sh

# build assets, perform migrations, etc.
RUN \
  --mount=type=cache,target=/var/cache/npm \
  --mount=type=cache,target=$APP_PATH/frontend/.angular/cache \
  --mount=type=cache,target=$APP_PATH/frontend/node_modules \
  ./docker/prod/setup/postinstall.sh

# use unprivileged user
USER $APP_USER

# set irb default config for $APP_USER
RUN ln -s /app/docker/prod/setup/.irbrc /home/$APP_USER/

# Expose port for rails server
EXPOSE 8080

# Expose OpenProject data directory as volume
VOLUME ["$APP_DATA_PATH"]

# Default to launching rails server
CMD ["./docker/prod/web"]

FROM slim as all-in-one

# The all-in-one image ships with postgres, memcached and apache2 preconfigured
ENV DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
ENV OPENPROJECT_RAILS__CACHE__STORE=memcache

USER root

RUN \
  --mount=type=cache,target=/var/cache/apt \
  ./docker/prod/setup/deps-onprem.sh

# set irb default config for root user
RUN ln -s /app/docker/prod/setup/.irbrc /root/

# Expose ports for apache and postgres
EXPOSE 80 5432

# Expose the postgres data directory and OpenProject data directory as volumes
VOLUME ["$PGDATA", "$APP_DATA_PATH"]

# Set a custom entrypoint to allow for privilege dropping and one-off commands
ENTRYPOINT ["./docker/prod/entrypoint.sh"]

# Set default command to launch the all-in-one configuration supervised by supervisord
CMD ["./docker/prod/supervisord"]
