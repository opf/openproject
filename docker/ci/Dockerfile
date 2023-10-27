# syntax=docker/dockerfile:1.4
ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-bullseye

ENV NODE_VERSION="20.9.0"
ENV BUNDLER_VERSION="2.4.21"
ENV DEBIAN_FRONTEND=noninteractive
ENV BUNDLE_WITHOUT="development:production:docker"

RUN apt-get update -qq && apt-get install -y postgresql-client time imagemagick default-jre-headless firefox-esr

ENV CHROME_SOURCE_URL="https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb"
RUN f="/tmp/chrome.deb"; wget --no-verbose -O $f $CHROME_SOURCE_URL && apt install -y $f && rm -f $f

RUN curl -L https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz -o - | tar xJf - -C /usr/local --strip=1 && node --version

RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

ENV APP_USER=dev
ENV APP_PATH=/app
ARG APP_USER_UID
ARG APP_USER_GID

RUN groupadd --force --gid $APP_USER_GID $APP_USER
RUN useradd -d $APP_PATH -m $APP_USER -s /bin/bash --uid $APP_USER_UID --gid $APP_USER_GID
RUN chown -R $APP_USER:$APP_USER /usr/local/bundle

ENV CI=true
ENV RAILS_ENV=test
ENV OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
ENV CAPYBARA_DYNAMIC_BIND_IP=1
ENV CAPYBARA_DOWNLOADED_FILE_DIR=/tmp
# disable deprecations and other warnings in output
ENV RUBYOPT="-W0"

WORKDIR $APP_PATH
USER $APP_USER

COPY ./docker/ci/entrypoint.sh /usr/sbin/entrypoint.sh

ENTRYPOINT [ "/usr/sbin/entrypoint.sh" ]
CMD ["setup-tests", "bash"]
