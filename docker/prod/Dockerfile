FROM ruby:3.2.1-alpine AS build-env
MAINTAINER operations@openproject.com

# Allow platform-specific additions. Valid values are: on-prem,saas,bahn
ARG PLATFORM=on-prem
# Use OAuth token in case private gems need to be fetched
ARG GITHUB_OAUTH_TOKEN
ARG DEBIAN_FRONTEND=noninteractive


ARG BUILD_PACKAGES="build-base curl curl-dev git bash"
ARG DEV_PACKAGES="postgresql-dev yaml-dev zlib-dev nodejs yarn"
ARG RUBY_PACKAGES="tzdata"

ENV BUNDLE_PATH__SYSTEM=false
ENV APP_USER=app
ENV APP_PATH=/app
ENV APP_DATA_PATH=/var/openproject/assets

ENV RAILS_ENV=production
ENV RAILS_GROUPS=production
ENV RAILS_LOG_TO_STDOUT=1
ENV RAILS_SERVE_STATIC_FILES=1
ENV OPENPROJECT_ATTACHMENTS__STORAGE__PATH=$APP_DATA_PATH/files
# Valid values are: standard,bim
ENV OPENPROJECT_EDITION=standard
ENV OPENPROJECT_INSTALLATION__TYPE=docker
ENV OPENPROJECT_RAILS__CACHE__STORE=memcache
# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE=OVERWRITE_ME
ENV NODE_VERSION="16.17.0"
ENV BUNDLER_VERSION="2.4.7"
ARG ARCHITECTURE="x64"
ENV BUNDLE_APP_CONFIG="$APP_PATH/.bundle"


WORKDIR $APP_PATH

RUN apk update && apk upgrade --no-cache && apk add $BUILD_PACKAGES $DEV_PACKAGES $RUBY_PACKAGES
# install node + npm
RUN curl -s https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCHITECTURE}.tar.gz | tar xzf - -C /usr/local --strip-components=1

# https://learn.microsoft.com/fr-fr/dotnet/core/install/linux-debian#debian-10-
#RUN wget --quiet https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
#	dpkg -i /tmp/packages-microsoft-prod.deb && rm /tmp/packages-microsoft-prod.deb


#RUN apt-get update -qq
#RUN apt-get install -y --no-install-recommends \
#	apt-transport-https \
#	pandoc \
#	poppler-utils \
#	unrtf \
#	tesseract-ocr \
#	catdoc \
#	imagemagick \
#	dotnet-runtime-6.0 # required for BIM edition

# Specifics for BIM edition

# Install XKT converter
# Install COLLADA2GLTF
ENV tmpdir=/tmp/build_dir
RUN mkdir $tmpdir
WORKDIR  $tmpdir
RUN npm install @xeokit/xeokit-gltf-to-xkt@1.3.1 -g 
RUN npm install @angular/cli -g

RUN wget --quiet https://github.com/KhronosGroup/COLLADA2GLTF/releases/download/v2.1.5/COLLADA2GLTF-v2.1.5-linux.zip
RUN unzip -q COLLADA2GLTF-v2.1.5-linux.zip
RUN mv COLLADA2GLTF-bin "/usr/local/bin/COLLADA2GLTF"

# IFCconvert
RUN wget --quiet https://s3.amazonaws.com/ifcopenshell-builds/IfcConvert-v0.6.0-517b819-linux64.zip
RUN unzip -q IfcConvert-v0.6.0-517b819-linux64.zip
RUN mv IfcConvert "/usr/local/bin/IfcConvert"

RUN wget --quiet https://github.com/bimspot/xeokit-metadata/releases/download/1.0.1/xeokit-metadata-linux-x64.tar.gz
RUN tar -zxvf xeokit-metadata-linux-x64.tar.gz
RUN chmod +x xeokit-metadata-linux-x64/xeokit-metadata
RUN cp -r xeokit-metadata-linux-x64/ "/usr/lib/xeokit-metadata"
RUN ln -s /usr/lib/xeokit-metadata/xeokit-metadata /usr/local/bin/xeokit-metadata

WORKDIR /
RUN rm -rf $tmpdir

RUN gem install bundler --version "$BUNDLER_VERSION" --no-document

#RUN useradd -d /home/$APP_USER -m $APP_USER
RUN addgroup -S $APP_USER && adduser -S $APP_USER -G $APP_USER

# set irb default config for app (docker run -it ...) and root (docker exec -it ...) users
RUN ln -s /app/docker/prod/setup/.irbrc /home/$APP_USER/
RUN ln -s /app/docker/prod/setup/.irbrc /root/

WORKDIR $APP_PATH

COPY Gemfile ./Gemfile
COPY Gemfile.* ./
COPY modules ./modules
COPY vendor ./vendor
# some gemspec files of plugins require files in there, notably OpenProject::Version
COPY lib ./lib

RUN bundle install --quiet --deployment --path vendor/bundle --no-cache \
  --with="$RAILS_GROUPS" --without="test development" --jobs=8 --retry=3 && \
  rm -rf vendor/bundle/ruby/*/cache && rm -rf vendor/bundle/ruby/*/gems/*/spec && rm -rf vendor/bundle/ruby/*/gems/*/test

COPY . .
#RUN bin/rails --tasks
#RUN bin/rails assets:precompile

# Finally, copy over the whole thing

RUN rm -f ./config/database.yml
WORKDIR ${APP_PATH}/frontend
ENV NG_CLI_ANALYTICS=ci
# Installing frontend dependencies
RUN npm install
#RUN npm run build
WORKDIR ${APP_PATH}

#RUN bin/rails webpacker:compile
RUN bin/rails DATABASE_URL=nulldb://user:pass@127.0.0.1/dbname assets:precompile --trace

# Remove sprockets cache
RUN rm -rf "$APP_PATH/tmp/cache/assets"
# Remove node_modules and entire frontend
RUN rm -rf "$APP_PATH/node_modules/" "$APP_PATH/frontend/node_modules/"
# Remove angular cache
RUN rm -rf "$APP_PATH/frontend/.angular"
# Clean cache in root
RUN rm -rf /root/.npm
RUN rm -f "$APP_PATH/log/production.log"

########  TARGET IMAGE

FROM ruby:3.2.1-alpine

ENV BUNDLE_PATH__SYSTEM=false
ENV APP_USER=app
ENV APP_PATH=/app
ENV APP_DATA_PATH=/var/openproject/assets

ENV RAILS_ENV=production
ENV RAILS_GROUPS=production
ENV RAILS_LOG_TO_STDOUT=1
ENV RAILS_SERVE_STATIC_FILES=1
ENV OPENPROJECT_ATTACHMENTS__STORAGE__PATH=$APP_DATA_PATH/files
# Valid values are: standard,bim
ENV OPENPROJECT_EDITION=standard
ENV OPENPROJECT_INSTALLATION__TYPE=docker
ENV OPENPROJECT_RAILS__CACHE__STORE=memcache
# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE=OVERWRITE_ME

ENV NODE_VERSION="16.17.0"
ENV BUNDLER_VERSION="2.4.7"
ARG ARCHITECTURE="x64"
ENV BUNDLE_APP_CONFIG="$APP_PATH/.bundle"

ENV PACKAGES="nodejs postgresql-client"

WORKDIR $APP_PATH

RUN addgroup -S $APP_USER && adduser -S $APP_USER -G $APP_USER

COPY --from=build-env $APP_PATH $APP_PATH

COPY --from=build-env /usr/local/bin/COLLADA2GLTF /usr/local/bin/COLLADA2GLTF
COPY --from=build-env /usr/local/bin/IfcConvert /usr/local/bin/IfcConvert
COPY --from=build-env /usr/lib/xeokit-metadata/xeokit-metadata /usr/local/bin/xeokit-metadata
RUN apk update && apk upgrade --no-cache && apk add $PACKAGES
#RUN /bin/bash -c "curl -s https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCHITECTURE}.tar.gz | tar xzf - -C /usr/local --strip-components=1"
#RUN ./docker/prod/setup/postinstall.sh

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
RUN mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/


# Set a custom entrypoint to allow for privilege dropping and one-off commands
#ENTRYPOINT ["./docker/prod/entrypoint.sh"]

# Set default command to launch the all-in-one configuration supervised by supervisord
#CMD ["./docker/prod/supervisord"]
CMD ["bundle","exec","rails","server","-u","puma","-b","0.0.0.0","-p","80"]
