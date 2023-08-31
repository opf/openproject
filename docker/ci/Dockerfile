# syntax=docker/dockerfile:1.4
FROM ruby:3.2.1-buster as gems

ENV BUNDLER_VERSION="2.4.7"
ENV BUNDLE_WITHOUT="development:production:docker"
ENV BUNDLE_JOBS=8

WORKDIR /app

RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

COPY Gemfile Gemfile.modules Gemfile.lock ./
COPY modules ./modules
RUN \
  --mount=type=cache,target=/usr/local/bundle/cache \
  bundle install

FROM node:16.17 as nodejs

WORKDIR /app

COPY package.json ./
COPY frontend/package.json frontend/package-lock.json frontend/.npmrc ./frontend/
RUN \
  --mount=type=cache,target=/app/.npm \
  JOBS=$(nproc) npm install

FROM ruby:3.2.1-buster as final

RUN wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update -qq && apt-get install -y \
    postgresql-13 postgresql-client-13 time imagemagick default-jre-headless firefox-esr

ENV CHROME_SOURCE_URL="https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb"
RUN f="/tmp/chrome.deb"; wget --no-verbose -O $f $CHROME_SOURCE_URL && apt install -y $f && rm -f $f

ENV APP_USER=dev
ENV APP_PATH=/app
RUN useradd -d $APP_PATH -m $APP_USER -s /bin/bash

ENV CI=true
ENV RAILS_ENV=test
ENV OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
ENV CAPYBARA_DYNAMIC_BIND_IP=1
ENV CAPYBARA_DOWNLOADED_FILE_DIR=/tmp
# disable deprecations and other warnings in output
ENV RUBYOPT="-W0"
ENV PGVERSION=13

WORKDIR $APP_PATH

RUN mkdir -p /cache && chown $APP_USER:$APP_USER /cache

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --from=nodejs /usr/local/bin/node /usr/local/bin/node
COPY --from=nodejs /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=nodejs /usr/local/include/node /usr/local/include/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

COPY --from=nodejs /app/node_modules ./node_modules
COPY --from=nodejs /app/frontend/node_modules ./frontend/node_modules
COPY --chown=$APP_USER:$APP_USER . .

USER $APP_USER
ENV DATABASE_URL="postgres://appuser:p4ssw0rd@127.0.0.1/appdb"
ENV BUNDLE_WITHOUT="development:production:docker"

RUN --mount=type=cache,target=/app/frontend/.angular/cache,uid=1000,gid=1000 DATABASE_URL=nulldb://db bin/rails openproject:plugins:register_frontend assets:precompile && \
	# only keep most current angular cache since webpack is unable to cleanup after itself
	find frontend/.angular/cache -type d -exec sh -c 'ls -dt "$1"/*/ | tail -n +2 | xargs rm -r' sh {} \;
RUN cp -rp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json
RUN cp docker/ci/database.yml config/

COPY ./docker/ci/entrypoint.sh /usr/sbin/entrypoint.sh

ENTRYPOINT [ "/usr/sbin/entrypoint.sh" ]
CMD ["setup-tests", "bash"]
