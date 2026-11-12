FROM buildpack-deps:trixie

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    RUBY_CONFIGURE_OPTS=--disable-install-doc \
    BUNDLE_JOBS=16 \
    BUNDLE_RETRY=3 \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1 \
    BROWSER_PATH=/usr/bin/chromium \
    CAPYBARA_DOWNLOADED_FILE_DIR=/tmp/capybara-downloads \
    RUBYOPT=-W0

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
      postgresql postgresql-client libpq-dev libyaml-dev libclang-dev \
      imagemagick poppler-utils unrtf tesseract-ocr catdoc \
      chromium fonts-liberation \
      psmisc time \
    && rm -rf /var/lib/apt/lists/*

COPY .ruby-version package.json /tmp/versions/

RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
    && PREFIX=/usr/local /tmp/ruby-build/install.sh \
    && MAKE_OPTS="-j$(nproc)" ruby-build "$(cat /tmp/versions/.ruby-version)" /usr/local \
    && rm -rf /tmp/ruby-build \
    && ruby --version

RUN node_major="$(sed -n 's/.*"node": *"[^0-9]*\([0-9][0-9]*\).*/\1/p' /tmp/versions/package.json)" \
    && test -n "$node_major" \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${node_major}.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && node --version

COPY . /src
WORKDIR /src

RUN gem install bundler --no-document -v "$(awk '/^BUNDLED WITH/ { getline; print $1 }' Gemfile.lock)" \
    && bundle install

RUN npm ci --no-audit --no-fund

RUN cp .oss-scanner/database.yml config/database.yml \
    && mkdir -p "$CAPYBARA_DOWNLOADED_FILE_DIR" spec/support/runtime-logs

RUN RAILS_ENV=test DATABASE_URL=nulldb://db \
      bin/rails openproject:plugins:register_frontend assets:precompile \
    && cp config/frontend_assets.manifest.json public/assets/frontend_assets.manifest.json

RUN /etc/init.d/postgresql start \
    && su postgres -c "psql -v ON_ERROR_STOP=1 -c \"CREATE ROLE openproject SUPERUSER LOGIN PASSWORD 'openproject'\"" \
    && ( (bin/rails db:create db:migrate \
          && bin/rails db:seed \
          && RAILS_ENV=test bin/rails db:create db:schema:load) > /tmp/db-setup.log 2>&1 \
        || (tail -n 200 /tmp/db-setup.log; exit 1) ) \
    && (RAILS_ENV=test timeout 900 bundle exec rspec \
          spec/models/user_spec.rb \
          spec/requests/api/v3/work_packages/show_resource_spec.rb \
          spec/features/auth/login_spec.rb \
        || echo "WARNING: smoke specs failed; inspect the output above") \
    && /etc/init.d/postgresql stop
