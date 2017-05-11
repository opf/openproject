FROM ruby:2.4

ENV NODE_VERSION="7.7.2"
ENV BUNDLER_VERSION="1.11.2"

# install node + npm
RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xzf - -C /usr/local --strip-components=1

# Using /home/app since npm cache and other stuff will be put there when running npm install
# We don't want to pollute any locally-mounted directory
RUN useradd -d /home/app -m app
RUN mkdir -p /usr/src/app
RUN gem install bundler --version "${BUNDLER_VERSION}"
RUN chown -R app:app /usr/src/app /usr/local/bundle

WORKDIR /usr/src/app

# https registry breaks so often it's no longer funny
RUN echo "registry = 'http://registry.npmjs.org/'" >> /usr/local/etc/npmrc
# moar logs
RUN echo "loglevel=info" >> /usr/local/etc/npmrc

COPY Gemfile ./Gemfile
COPY Gemfile.* ./
RUN chown -R app:app /usr/src/app

USER app
RUN bundle install --jobs 8 --retry 3

USER root
# Then, npm install node modules
COPY package.json /tmp/npm/package.json
COPY frontend/*.json /tmp/npm/frontend/
RUN chown -R app:app /tmp/npm

USER app
RUN cd /tmp/npm/frontend/ && RAILS_ENV=production npm install --ignore-scripts
RUN mv /tmp/npm/frontend /usr/src/app/

# Finally, copy over the whole thing
USER root
COPY . /usr/src/app
RUN cp docker/Procfile .
RUN sed -i "s|Rails.groups(:opf_plugins)|Rails.groups(:opf_plugins, :docker)|" config/application.rb
RUN chown -R app:app /usr/src/app

USER app
# Run the npm postinstall manually after it was copied
RUN cd frontend && npm run postinstall
RUN DATABASE_URL=sqlite3:///tmp/db.sqlite3 SECRET_TOKEN=foobar RAILS_ENV=production bundle exec rake assets:precompile

CMD ["./docker/web"]
