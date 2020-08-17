FROM ruby:2.6-stretch AS pgloader
RUN apt-get update -qq && apt-get install -y libsqlite3-dev make curl gawk freetds-dev libzip-dev
COPY docker/mysql-to-postgres/bin/build /tmp/build-pgloader
RUN /tmp/build-pgloader && rm /tmp/build-pgloader

FROM ruby:2.6-stretch
MAINTAINER operations@openproject.com

# Allow platform-specific additions. Valid values are: on-premise,cloud
ARG PLATFORM=on-premise
# Use OAuth token in case private gems need to be fetched
ARG GITHUB_OAUTH_TOKEN
ARG DEBIAN_FRONTEND=noninteractive

ENV NODE_VERSION="12.18.3"
ENV BUNDLER_VERSION="2.0.2"
ENV BUNDLE_PATH__SYSTEM=false
ENV APP_USER=app
ENV APP_PATH=/app
ENV APP_DATA_PATH=/var/openproject/assets
ENV APP_DATA_PATH_LEGACY=/var/db/openproject
ENV PGBIN="/usr/lib/postgresql/9.6/bin"
ENV PGDATA=/var/openproject/pgdata
ENV PGDATA_LEGACY=/var/lib/postgresql/9.6/main

ENV DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
ENV HEROKU=true
ENV RAILS_ENV=production
ENV RAILS_CACHE_STORE=memcache
ENV BUNDLER_GROUPS="production docker opf_plugins"
ENV OPENPROJECT_INSTALLATION__TYPE=docker
# Valid values are: standard,bim
ENV OPENPROJECT_EDITION=standard
ENV NEW_RELIC_AGENT_ENABLED=false
ENV ATTACHMENTS_STORAGE_PATH=$APP_DATA_PATH/files
# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE=OVERWRITE_ME

COPY --from=pgloader /usr/local/bin/pgloader-ccl /usr/local/bin/

WORKDIR $APP_PATH

COPY docker/setup ./docker/setup
RUN ./docker/setup/preinstall.sh

COPY Gemfile ./Gemfile
COPY Gemfile.* ./
COPY modules ./modules
COPY vendor ./vendor
# some gemspec files of plugins require files in there, notably OpenProject::Version
COPY lib ./lib

RUN bundle install --deployment --path vendor/bundle --no-cache \
  --with="$BUNDLER_GROUPS" --without="test development" --jobs=8 --retry=3 && \
  rm -rf vendor/bundle/ruby/*/cache && rm -rf vendor/bundle/ruby/*/gems/*/spec && rm -rf vendor/bundle/ruby/*/gems/*/test

# Finally, copy over the whole thing
COPY . .

RUN ./docker/setup/postinstall.sh

# Expose ports for apache and postgres
EXPOSE 80 5432

# Expose the postgres data directory and OpenProject data directory as volumes
VOLUME ["$PGDATA", "$APP_DATA_PATH"]

# Set a custom entrypoint to allow for privilege dropping and one-off commands
ENTRYPOINT ["./docker/entrypoint.sh"]

# Set default command to launch the all-in-one configuration supervised by supervisord
CMD ["./docker/supervisord"]
