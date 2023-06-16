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

COPY config ./config
COPY db ./db
RUN bundle exec rails db:migrate db:schema:dump

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
    postgresql-13 postgresql-client-13 time pandoc imagemagick default-jre-headless firefox-esr

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

USER $APP_USER

COPY ./docker/ci/entrypoint.sh /usr/sbin/entrypoint.sh
COPY --from=gems --chown=$APP_USER:$APP_USER /usr/local/bundle /usr/local/bundle
COPY --from=nodejs --chown=$APP_USER:$APP_USER /app/node_modules ./node_modules
COPY --from=nodejs --chown=$APP_USER:$APP_USER /app/frontend/node_modules ./frontend/node_modules
COPY --chown=$APP_USER:$APP_USER . .

ENV DATABASE_URL="postgres://appuser:p4ssw0rd@127.0.0.1/appdb"
ENV BUNDLE_WITHOUT="development:production:docker"

ENTRYPOINT [ "/usr/sbin/entrypoint.sh" ]
CMD ["setup-tests", "bash"]
