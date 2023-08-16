ARG RUBY_VERSION="3.2.2"
ARG NODE_VERSION="16.17.0"
ARG BUNDLER_VERSION="2.4.7"
ARG DEBIAN_FRONTEND=noninteractive

# -------------------------------------
# rubygems (private)
# -------------------------------------
FROM ruby:${RUBY_VERSION}-bullseye as rubygems
ENV BUNDLE_JOBS=8
ENV BUNDLE_RETRY=3
ENV BUNDLE_WITHOUT="development:test"

WORKDIR /app

RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

COPY Gemfile Gemfile.modules Gemfile.lock ./
COPY modules ./modules
RUN bundle install

# -------------------------------------
# nodejs (private)
# -------------------------------------
# Using docker image for node so that multi-arch is automatically taken care of
FROM node:${NODE_VERSION} as nodejs

WORKDIR /app

COPY package.json ./
COPY frontend/package.json frontend/package-lock.json frontend/.npmrc ./frontend/
RUN JOBS=8 npm install

# -------------------------------------
# assets (private)
# -------------------------------------
FROM rubygems as assets

COPY --from=nodejs /usr/local/bin/node /usr/local/bin/node
COPY --from=nodejs /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=nodejs /usr/local/include/node /usr/local/include/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

WORKDIR /app

COPY --from=nodejs /app/node_modules ./node_modules
COPY --from=nodejs /app/frontend/node_modules ./frontend/node_modules
COPY Rakefile .
COPY bin ./bin
COPY app ./app
COPY config ./config
COPY lib ./lib
COPY lib_static ./lib_static
COPY frontend ./frontend
COPY modules ./modules
COPY vendor ./vendor
COPY lookbook ./lookbook

RUN --mount=type=cache,target=/app/frontend/.angular/cache,uid=1000,gid=1000 \
  SECRET_KEY_BASE=1 RAILS_ENV=production DATABASE_URL=nulldb://db \
  bin/rails openproject:plugins:register_frontend assets:precompile && \
  # only keep most current angular cache since webpack is unable to cleanup after itself
	find frontend/.angular/cache -type d -exec sh -c 'ls -dt "$1"/*/ | tail -n +2 | xargs rm -r' sh {} \;

# -------------------------------------
# base (private)
# -------------------------------------
FROM ruby:${RUBY_VERSION}-slim-bullseye as base
LABEL maintainer="operations@openproject.com"

# SYSTEM
ENV APP_USER=app
ENV APP_PATH=/app
ENV APP_DATA_PATH=/var/openproject/assets
ENV PGVERSION="13"
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

RUN useradd -d /home/$APP_USER -m $APP_USER
RUN mkdir -p $APP_PATH && chown $APP_USER:$APP_USER $APP_PATH
RUN mkdir -p $APP_DATA_PATH && chown $APP_USER:$APP_USER $APP_DATA_PATH

WORKDIR $APP_PATH

RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
  file \
  curl \
  gnupg2 \
  && curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' $PGVERSION > /etc/apt/sources.list.d/pgdg.list \
  && apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
  libpq5 \
  postgresql-client-$PGVERSION \
  libffi7 \
  unrtf tesseract-ocr poppler-utils catdoc imagemagick \
  && apt-get purge -y curl gnupg2 \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# -------------------------------------
# slim (public)
# -------------------------------------
FROM base as slim
COPY --chown=$APP_USER:$APP_USER --from=rubygems /usr/local/bundle /usr/local/bundle
COPY --chown=$APP_USER:$APP_USER --from=assets /app/public/assets /app/public/assets
COPY --chown=$APP_USER:$APP_USER --from=assets /app/config/frontend_assets.manifest.json /app/config/frontend_assets.manifest.json
COPY --chown=$APP_USER:$APP_USER . .

USER $APP_USER
RUN ln -s $APP_PATH/docker/prod/setup/.irbrc /home/$APP_USER/

EXPOSE 8080
CMD ["./docker/prod/web"]
VOLUME ["$APP_DATA_PATH"]

# -------------------------------------
# all-in-one (public)
# -------------------------------------
FROM base as all-in-one
ARG DEBIAN_FRONTEND
ARG NODE_VERSION
ARG BUNDLER_VERSION
# Allow platform-specific additions. Valid values are: on-prem,saas,bahn
ARG PLATFORM=on-prem
# Use OAuth token in case private gems need to be fetched
ARG GITHUB_OAUTH_TOKEN
ARG BIM_SUPPORT=true
ARG GOSU_VERSION="1.16"
ARG OPENPROJECT_ANGULAR_UGLIFY=true

ENV OPENPROJECT_RAILS__CACHE__STORE=memcache
ENV DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
ENV PGDATA=/var/openproject/pgdata
ENV PGBIN="/usr/lib/postgresql/$PGVERSION/bin"

COPY docker/prod/setup ./docker/prod/setup
RUN ./docker/prod/setup/preinstall.sh

RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
 && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true

# set irb default config for app (docker run -it ...) and root (docker exec -it ...) users
RUN ln -s /app/docker/prod/setup/.irbrc /home/$APP_USER/
RUN ln -s /app/docker/prod/setup/.irbrc /root/

COPY Gemfile ./Gemfile
COPY Gemfile.* ./
COPY modules ./modules
COPY vendor ./vendor
# some gemspec files of plugins require files in there, notably OpenProject::Version
COPY lib ./lib

RUN bundle install --quiet --deployment --path vendor/bundle --no-cache \
  --with="$RAILS_GROUPS" --without="test development" --jobs=8 --retry=3 && \
  rm -rf vendor/bundle/ruby/*/cache && rm -rf vendor/bundle/ruby/*/gems/*/spec && rm -rf vendor/bundle/ruby/*/gems/*/test

# Finally, copy over the whole thing
COPY . .

RUN ./docker/prod/setup/postinstall.sh

# Expose ports for apache and postgres
EXPOSE 80 5432

# Expose the postgres data directory and OpenProject data directory as volumes
VOLUME ["$PGDATA", "$APP_DATA_PATH"]

# Set a custom entrypoint to allow for privilege dropping and one-off commands
ENTRYPOINT ["./docker/prod/entrypoint.sh"]

# Set default command to launch the all-in-one configuration supervised by supervisord
CMD ["./docker/prod/supervisord"]
