FROM ruby:3.2.1-buster
MAINTAINER operations@openproject.com

ENV NODE_VERSION="16.17.0"
ENV CHROME_SOURCE_URL="https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb https://openproject-public.s3.eu-central-1.amazonaws.com/binaries/google-chrome-stable_current_amd64.deb"
ENV USER=dev

RUN useradd -d /home/$USER -m $USER -s /bin/bash
WORKDIR /home/$USER

# Download nodejs with retries and basic throttling
RUN for i in 1 2 3 4 5; do \
    if [ $i -gt 1 ]; then sleep $i; fi \
    && curl --retry 10 --output /tmp/node.tar.gz --silent --show-error https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz \
      && ret=$? && break \
      || ret=$? && echo "Download attempt #$i failed"; \
  done \
  && [ $ret -ne 0 ] \
    && echo "All download attempts failed" && exit $ret \
    || echo "Download successful" \
  && tar xzf /tmp/node.tar.gz --directory /usr/local --strip-components=1 \
  && rm -f /tmp/node.tar.gz

RUN wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql-10 postgresql-client-10 postgresql-13 postgresql-client-13 time pandoc imagemagick libpq-dev default-jre-headless firefox-esr

# Try Downloading binary from fallback source if first one fails
RUN for url in $CHROME_SOURCE_URL; do \
      file_name="/tmp/`basename $url`"; \
      wget --no-verbose -O $file_name $url && \
        apt install -y $file_name && rm -f $file_name && \
        break; \
    done

ENV CI=true
ENV RAILS_ENV=test
ENV BUNDLER_VERSION="2.4.7"
ENV BUNDLE_WITHOUT="development:production:docker"
ENV OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
ENV CAPYBARA_DYNAMIC_BIND_IP=1
ENV CAPYBARA_DOWNLOADED_FILE_DIR=/tmp
# disable deprecations and other warnings in output
ENV RUBYOPT="-W0"
ENV DATABASE_URL=postgres://appuser:p4ssw0rd@127.0.0.1/appdb
ENV PGVERSION=13
ENV DISABLE_DATABASE_ENVIRONMENT_CHECK=1

RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

COPY ./entrypoint.sh /usr/sbin/entrypoint.sh

VOLUME [ "/usr/local/bundle", "/home/$USER/openproject" ]

WORKDIR /home/$USER/openproject

ENTRYPOINT [ "/usr/sbin/entrypoint.sh" ]
CMD ["setup-tests", "bash"]
