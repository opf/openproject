FROM ruby:2.6-stretch
MAINTAINER operations@openproject.com

ENV NODE_VERSION="10.15.0"
ENV BUNDLER_VERSION="2.0.1"
ENV APP_USER app
ENV APP_PATH /usr/src/app
ENV APP_DATA /var/db/openproject
ENV ATTACHMENTS_STORAGE_PATH /var/db/openproject/files

ENV DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
ENV RAILS_ENV=production
ENV HEROKU=true
ENV RAILS_CACHE_STORE=memcache
ENV OPENPROJECT_INSTALLATION__TYPE=docker

# Set a default key base, ensure to provide a secure value in production environments!
ENV SECRET_KEY_BASE=OVERWRITE_ME

# install node + npm
RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xzf - -C /usr/local --strip-components=1

USER root

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
RUN rm -rf /var/lib/postgresql/9.6/main && mkdir -p /var/lib/postgresql/9.6/main && chown -R postgres:postgres /var/lib/postgresql/9.6
RUN a2enmod proxy proxy_http && rm -f /etc/apache2/sites-enabled/000-default.conf

# using /home/app since npm cache and other stuff will be put there when running npm install
# we don't want to pollute any locally-mounted directory
RUN useradd -d /home/$APP_USER -m $APP_USER
RUN mkdir -p $APP_PATH $APP_DATA
RUN mkdir -p /var/db/openproject/{files,git,svn}
RUN chown -R $APP_USER:$APP_USER $APP_DATA

RUN gem install bundler --version "${bundler_version}" --no-document

WORKDIR $APP_PATH

COPY Gemfile ./Gemfile
COPY Gemfile.* ./
COPY modules ./modules
# OpenProject::Version is required by module versions in gemspecs
RUN mkdir -p lib/open_project
COPY lib/open_project/version.rb ./lib/open_project/
RUN bundle install --deployment --with="docker opf_plugins" --without="test development mysql2" --jobs=8 --retry=3

# Then, npm install node modules
COPY package.json /tmp/npm/package.json
COPY frontend/*.json /tmp/npm/frontend/
RUN cd /tmp/npm/frontend/ && RAILS_ENV=production npm install && mv /tmp/npm/frontend $APP_PATH/

# Finally, copy over the whole thing
COPY . $APP_PATH
RUN cp docker/Procfile .
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN sed -i "s|Rails.groups(:opf_plugins)|Rails.groups(:opf_plugins, :docker)|" config/application.rb

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
RUN mkdir -p /tmp/op_uploaded_files/
RUN chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

# Allow uploading avatars w/ postgres
RUN chown -R $APP_USER:$APP_USER $APP_DATA

# Re-use packager database.yml
COPY packaging/conf/database.yml ./config/database.yml

# Run the npm postinstall manually after it was copied
RUN DATABASE_URL='nulldb://nohost' RAILS_ENV=production bundle exec rake assets:precompile

# Include pandoc
RUN DATABASE_URL='nulldb://nohost' RAILS_ENV=production bundle exec rails runner "puts ::OpenProject::TextFormatting::Formats::Markdown::PandocDownloader.check_or_download!"

# Remove node_modules and entire frontend
RUN rm -rf $APP_PATH/node_modules $APP_PATH/frontend

# Re-own app dir
RUN chown -R $APP_USER:$APP_USER $APP_PATH

# ports
EXPOSE 80 5432

# volumes to export
VOLUME ["/var/lib/postgresql/9.6/main", "$APP_DATA"]
CMD ["./docker/web"]
ENTRYPOINT ["./docker/entrypoint.sh"]
