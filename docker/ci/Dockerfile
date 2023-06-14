FROM ruby:3.2.1-buster
MAINTAINER operations@openproject.com

ENV NODE_VERSION="16.17.0"
ENV CHROME_SOURCE_URL="https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb"

RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz \
  | tar xzf - --strip-components=1 -C /usr/local

RUN wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update -qq && apt-get install -y \
    postgresql-13 postgresql-client-13 time pandoc imagemagick libpq-dev default-jre-headless firefox-esr

RUN f="/tmp/chrome.deb"; wget --no-verbose -O $f $CHROME_SOURCE_URL && apt install -y $f && rm -f $f

ENV APP_USER=dev
ENV APP_PATH=/app
RUN useradd -d $APP_PATH -m $APP_USER -s /bin/bash

ENV CI=true
ENV RAILS_ENV=test
ENV BUNDLER_VERSION="2.4.7"
ENV BUNDLE_WITHOUT="development:production:docker"
ENV BUNDLE_JOBS=4
ENV OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
ENV CAPYBARA_DYNAMIC_BIND_IP=1
ENV CAPYBARA_DOWNLOADED_FILE_DIR=/tmp
# disable deprecations and other warnings in output
ENV RUBYOPT="-W0"
ENV PGVERSION=13

WORKDIR $APP_PATH

RUN mkdir -p /cache && chown $APP_USER:$APP_USER /cache
RUN mkdir -p /usr/local/bundle/cache && chown -R $APP_USER:$APP_USER /usr/local/bundle/cache

USER $APP_USER

RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

COPY --chown=$APP_USER:$APP_USER Gemfile Gemfile.modules Gemfile.lock ./
COPY --chown=$APP_USER:$APP_USER modules ./modules
RUN \
  --mount=type=cache,target=/usr/local/bundle/cache,uid=1000,gid=1000 \
  bundle install

COPY --chown=$APP_USER:$APP_USER package.json ./
COPY --chown=$APP_USER:$APP_USER frontend/package.json frontend/package-lock.json frontend/.npmrc ./frontend/
RUN \
  --mount=type=cache,target=/app/.npm,uid=1000,gid=1000 \
  JOBS=$(nproc) npm install

COPY ./docker/ci/entrypoint.sh /usr/sbin/entrypoint.sh
COPY --chown=$APP_USER:$APP_USER . .

ENV DATABASE_URL="postgres://appuser:p4ssw0rd@127.0.0.1/appdb"

ENTRYPOINT [ "/usr/sbin/entrypoint.sh" ]
CMD ["setup-tests", "bash"]
