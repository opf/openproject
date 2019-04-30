FROM ruby:2.6-stretch
MAINTAINER operations@openproject.com

ENV NODE_VERSION "10.15.0"
ENV BUNDLER_VERSION "2.0.1"
ENV APP_USER app
ENV APP_PATH /app
ENV APP_DATA_PATH /var/openproject/assets
ENV APP_DATA_PATH_LEGACY /var/db/openproject
ENV PGDATA /var/openproject/pgdata
ENV PGDATA_LEGACY /var/lib/postgresql/9.6/main

ENV DATABASE_URL postgres://openproject:openproject@127.0.0.1/openproject
ENV RAILS_ENV production
ENV HEROKU true
ENV RAILS_CACHE_STORE memcache
ENV OPENPROJECT_INSTALLATION__TYPE docker
ENV NEW_RELIC_AGENT_ENABLED false
ENV ATTACHMENTS_STORAGE_PATH $APP_DATA_PATH/files

# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE OVERWRITE_ME

# install node + npm
RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xzf - -C /usr/local --strip-components=1

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  \
    postgresql-client \
    poppler-utils \
    unrtf \
    tesseract-ocr \
    catdoc \
    memcached \
    postfix \
    postgresql \
    apache2 \
    supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up pg defaults
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf
RUN echo "data_directory='$PGDATA'" >> /etc/postgresql/9.6/main/postgresql.conf
RUN rm -rf "$PGDATA_LEGACY" && rm -rf "$PGDATA" && mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA"
RUN a2enmod proxy proxy_http && rm -f /etc/apache2/sites-enabled/000-default.conf

# using /home/app since npm cache and other stuff will be put there when running npm install
# we don't want to pollute any locally-mounted directory
RUN useradd -d /home/$APP_USER -m $APP_USER

WORKDIR $APP_PATH
RUN gem install bundler --version "${bundler_version}" --no-document

COPY Gemfile ./Gemfile
COPY Gemfile.* ./
COPY modules ./modules
# OpenProject::Version is required by module versions in gemspecs
RUN mkdir -p lib/open_project
COPY lib/open_project/version.rb ./lib/open_project/
RUN bundle install --deployment --with="docker opf_plugins" --without="test development mysql2" --jobs=8 --retry=3

# Finally, copy over the whole thing
COPY . $APP_PATH

RUN sed -i "s|Rails.groups(:opf_plugins)|Rails.groups(:opf_plugins, :docker)|" config/application.rb

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
RUN mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

# Re-use packager database.yml
COPY packaging/conf/database.yml ./config/database.yml

# Run the npm postinstall manually after it was copied
# Then, npm install node modules
RUN bash docker/precompile-assets.sh

# ports
EXPOSE 80 5432

# volumes to export
VOLUME ["$PGDATA", "$APP_DATA_PATH"]
ENTRYPOINT ["./docker/entrypoint.sh"]
CMD ["./docker/supervisord"]
