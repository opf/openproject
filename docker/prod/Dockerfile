ARG RUBY_VERSION="3.3.4"
FROM ruby:${RUBY_VERSION}-bookworm as base
LABEL maintainer="operations@openproject.com"

ARG BUNDLER_VERSION="2.5.13"
ARG NODE_VERSION="20.9.0"
ARG BIM_SUPPORT=true
ENV DEBIAN_FRONTEND=noninteractive
ENV BUNDLE_JOBS=8
ENV BUNDLE_RETRY=3
ENV BUNDLE_WITHOUT="development:test"

# SYSTEM
ENV DOCKER=1
ENV APP_USER=app
ENV APP_PATH=/app
ENV APP_DATA_PATH=/var/openproject/assets
ENV PGVERSION="13"
ENV CURRENT_PGVERSION="13"
ENV NEXT_PGVERSION="15"
ENV PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
ENV BUNDLE_WITHOUT="development:test"

# RAILS
# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE=OVERWRITE_ME
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1
ENV RAILS_SERVE_STATIC_FILES=1

# OPENPROJECT
# Valid values are: standard,bim
ENV OPENPROJECT_EDITION=standard
ENV OPENPROJECT_INSTALLATION__TYPE=docker
ENV OPENPROJECT_ATTACHMENTS__STORAGE__PATH=$APP_DATA_PATH/files
ENV OPENPROJECT_RAILS__CACHE__STORE=file_store
ENV OPENPROJECT_ANGULAR_UGLIFY=true

RUN useradd -d /home/$APP_USER -m $APP_USER && \
    mkdir -p $APP_PATH && chown $APP_USER:$APP_USER $APP_PATH && \
    mkdir -p $APP_DATA_PATH && chown $APP_USER:$APP_USER $APP_DATA_PATH && chmod g+rwx $APP_DATA_PATH

WORKDIR $APP_PATH

# upgrade bundler
RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

# system dependencies, nodejs
COPY ./docker/prod/setup/preinstall-common.sh ./docker/prod/setup/preinstall-common.sh
RUN ./docker/prod/setup/preinstall-common.sh

# stuff required for gems
COPY Gemfile Gemfile.* .ruby-version ./
COPY modules ./modules
# Add vendor for saas-openproject plugins
COPY vendor ./vendor
# Add lib in case a plugin tries to load VERSION file under lib
COPY lib ./lib

RUN \
  bundle config set --local path 'vendor/bundle' && \
  bundle config set --local without 'test development' && \
  bundle install --quiet --no-cache --jobs=8 --retry=3 && \
  bundle config set deployment 'true' && \
  cp Gemfile.lock Gemfile.lock.bak && \
  rm -rf vendor/bundle/ruby/*/cache && \
  rm -rf vendor/bundle/ruby/*/gems/*/spec && \
  rm -rf vendor/bundle/ruby/*/gems/*/test

COPY . .

# Copy lock file again as the updated version was overriden by COPY just now
RUN cp Gemfile.lock.bak Gemfile.lock && rm Gemfile.lock.bak && \
    ./docker/prod/setup/precompile-assets.sh && \
    ./docker/prod/setup/postinstall-common.sh && \
    cp ./config/database.production.yml config/database.yml && \
    ln -s $APP_PATH/docker/prod/setup/.irbrc /home/$APP_USER/

# -------------------------------------
# slim (public)
# -------------------------------------
FROM base as slim

USER $APP_USER
EXPOSE 8080
CMD ["./docker/prod/web"]
VOLUME ["$APP_DATA_PATH"]

# -------------------------------------
# all-in-one (public)
# -------------------------------------
FROM base as all-in-one

ENV OPENPROJECT_RAILS__CACHE__STORE=memcache
ENV DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
ENV PGDATA=/var/openproject/pgdata
ENV GOSU_VERSION="1.17"

RUN ./docker/prod/setup/postinstall-onprem.sh && \
    ln -s /app/docker/prod/setup/.irbrc /root/

# Expose ports for apache and postgres
EXPOSE 80

# Expose the postgres data directory and OpenProject data directory as volumes
VOLUME ["$PGDATA", "$APP_DATA_PATH"]

# Set a custom entrypoint to allow for privilege dropping and one-off commands
ENTRYPOINT ["./docker/prod/entrypoint.sh"]

# Set default command to launch the all-in-one configuration supervised by supervisord
CMD ["./docker/prod/supervisord"]
