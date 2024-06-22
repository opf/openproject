# syntax=docker/dockerfile:1.4
ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-bookworm

ENV NODE_VERSION="20.9.0"
ENV BUNDLER_VERSION="2.5.13"
ENV DEBIAN_FRONTEND=noninteractive
ENV BUNDLE_WITHOUT="development:production:docker"

ENV PGVERSION=13
RUN wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list

ENV CHROME_SOURCE_URL="https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb"
RUN --mount=type=cache,target=/var/cache/apt export f="/tmp/chrome.deb" && wget --no-verbose -O $f $CHROME_SOURCE_URL && \
  apt-get update -qq && apt-get install -y "$f" postgresql-$PGVERSION postgresql-client-$PGVERSION time imagemagick default-jre-headless firefox-esr && \
  rm -f "$f" && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/postgresql && find /usr/share/locale/* -maxdepth 0 -type d ! -name 'en' -exec rm -rf {} \;

RUN curl -L https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz -o - | tar xJf - -C /usr/local --strip=1 && node --version

RUN rm -rf /usr/local/bundle && gem install bundler --version "$BUNDLER_VERSION" --no-document

ENV APP_USER=dev
ENV APP_PATH=/app
ARG APP_USER_UID
ARG APP_USER_GID

RUN groupadd --force --gid $APP_USER_GID $APP_USER && \
  useradd -d $APP_PATH -m $APP_USER -s /bin/bash --uid $APP_USER_UID --gid $APP_USER_GID && \
  chown -R $APP_USER:$APP_USER /usr/local/bundle

ENV CI=true
ENV RAILS_ENV=test
ENV OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
ENV CAPYBARA_DYNAMIC_BIND_IP=1
ENV CAPYBARA_DOWNLOADED_FILE_DIR=/tmp
# disable deprecations and other warnings in output
ENV RUBYOPT="-W0"

WORKDIR $APP_PATH
USER $APP_USER

RUN mkdir -p ./docker/ci
COPY ./docker/ci/entrypoint.sh ./docker/ci/entrypoint.sh

ENTRYPOINT [ "/app/docker/ci/entrypoint.sh" ]
CMD ["setup-tests", "bash"]
