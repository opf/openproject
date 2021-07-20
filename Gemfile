#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

source 'https://rubygems.org'

ruby '~> 2.7.4'

gem 'actionpack-xml_parser', '~> 2.0.0'
gem 'activemodel-serializers-xml', '~> 1.0.1'
gem 'activerecord-import', '~> 1.1.0'
gem 'activerecord-session_store', '~> 2.0.0'
gem 'rails', '~> 6.1.3'
gem 'responders', '~> 3.0'

gem 'rdoc', '>= 2.4.2'

gem 'doorkeeper', '~> 5.5.0'
# Maintain our own omniauth due to relative URL root issues
# see upstream PR: https://github.com/omniauth/omniauth/pull/903
gem 'omniauth', git: 'https://github.com/opf/omniauth', ref: 'fe862f986b2e846e291784d2caa3d90a658c67f0'
gem 'request_store', '~> 1.5.0'

gem 'warden', '~> 1.2'
gem 'warden-basic_auth', '~> 0.2.1'

gem 'will_paginate', '~> 3.3.0'

gem 'friendly_id', '~> 5.4.0'

gem 'acts_as_list', '~> 1.0.1'
gem 'acts_as_tree', '~> 2.9.0'
gem 'awesome_nested_set', '~> 3.4.0'
gem 'rubytree', '~> 1.0.0'
gem 'typed_dag', '~> 2.0.2'

gem 'addressable', '~> 2.8.0'

# Remove whitespace from model input
gem "auto_strip_attributes", "~> 2.5"

# Provide timezone info for TZInfo used by AR
gem 'tzinfo-data', '~> 1.2021.1'

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

# Generate url slugs with #to_url and other string niceties
gem 'stringex', '~> 2.8.5'

# CommonMark markdown parser with GFM extension
gem 'commonmarker', '~> 0.22.0'

# HTML pipeline for transformations on text formatter output
# such as sanitization or additional features
gem 'html-pipeline', '~> 2.14.0'
# Tasklist parsing and renderer
gem 'deckar01-task_list', '~> 2.3.1'
# Requires escape-utils for faster escaping
gem 'escape_utils', '~> 1.0'
# Syntax highlighting used in html-pipeline with rouge
gem 'rouge', '~> 3.26.0'
# HTML sanitization used for html-pipeline
gem 'sanitize', '~> 5.2.1'
# HTML autolinking for mails and urls (replaces autolink)
gem 'rinku', '~> 2.0.4'
# Version parsing with semver
gem 'semantic', '~> 1.6.1'

# generates SVG Graphs
# used for statistics on svn repositories
gem 'svg-graph', '~> 2.2.0'

gem 'date_validator', '~> 0.11.0'
gem 'ruby-duration', '~> 3.2.0'

# provide compatible filesystem information for available storage
gem 'sys-filesystem', '~> 1.4.0', require: false

# Faster posix-compliant spawns for 8.0. conversions with pandoc
gem 'posix-spawn', '~> 0.3.13', require: false

gem 'bcrypt', '~> 3.1.6'

gem 'multi_json', '~> 1.15.0'
gem 'oj', '~> 3.12.0'

gem 'daemons'
gem 'delayed_cron_job', '~> 0.7.4'
gem 'delayed_job_active_record', '~> 4.1.5'

gem 'rack-protection', '~> 2.1.0'

# Rack::Attack is a rack middleware to protect your web app from bad clients.
# It allows whitelisting, blacklisting, throttling, and tracking based
# on arbitrary properties of the request.
# https://github.com/kickstarter/rack-attack
gem 'rack-attack', '~> 6.5.0'

# CSP headers
gem 'secure_headers', '~> 6.3.0'

# Browser detection for incompatibility checks
gem 'browser', '~> 5.3.0'

# Providing health checks
gem 'okcomputer', '~> 1.18.1'

gem 'gon', '~> 6.4.0'

# Lograge to provide sane and non-verbose logging
gem 'lograge', '~> 0.11.0'

# Structured warnings to selectively disable them in production
gem 'structured_warnings', '~> 0.4.0'

# catch exceptions and send them to any airbrake compatible backend
# don't require by default, instead load on-demand when actually configured
gem 'airbrake', '~> 11.0.0', require: false

gem 'prawn', '~> 2.2'
gem 'prawn-markup', '~> 0.3.0'

gem 'cells-erb', '~> 0.1.0'
gem 'cells-rails', '~> 0.0.9'

gem 'meta-tags', '~> 2.14.0'

group :production do
  # we use dalli as standard memcache client
  # requires memcached 1.4+
  gem 'dalli', '~> 2.7.10'

  # Unicorn worker killer to restart unicorn child workers
  gem 'unicorn-worker-killer', require: false
end

gem 'i18n-js', '~> 3.8.0'
gem 'rails-i18n', '~> 6.0.0'
gem 'sprockets', '~> 3.7.0'

# required by Procfile, for deployment on heroku or packaging with packager.io.
# also, better than thin since we can control worker concurrency.
gem 'unicorn'

gem 'puma', '~> 5.3.0' # used for development and optionally for production

gem 'nokogiri', '~> 1.11.0'

gem 'carrierwave', '~> 1.3.1'
gem 'carrierwave_direct', '~> 2.1.0'
gem 'fog-aws'

gem 'aws-sdk-core', '~> 3.107'
# File upload via fog + screenshots on travis
gem 'aws-sdk-s3', '~> 1.91'

gem 'openproject-token', '~> 2.1.1'

gem 'plaintext', '~> 0.3.2'

gem 'rest-client', '~> 2.0'

gem 'ruby-progressbar', '~> 1.11.0', require: false

gem 'mini_magick', '~> 4.11.0', require: false

# Sentry error reporting, loaded on demand
group :sentry do
  gem "sentry-delayed_job", '~> 4.6.0', require: false
  gem "sentry-rails", '~> 4.6.0', require: false
  gem "sentry-ruby", '~> 4.6.0',  require: false
end

group :test do
  gem 'launchy', '~> 2.5.0'
  gem 'rack-test', '~> 1.1.0'
  gem 'shoulda-context', '~> 2.0'

  # Test prof provides factories from code
  # and other niceties
  gem 'test-prof', '~> 1.0.0'

  gem 'database_cleaner', '~> 2.0'
  gem 'rack_session_access'
  gem 'rspec', '~> 3.10.0'
  # also add to development group, so "spec" rake task gets loaded
  gem 'rspec-rails', '~> 5.0.0', group: :development

  # Retry failures within the same environment
  gem 'retriable', '~> 3.1.1'
  gem 'rspec-retry', '~> 0.6.1'

  # XML comparison tests
  gem 'compare-xml', '~> 0.66', require: false

  # brings back testing for 'assigns' and 'assert_template' extracted in rails 5
  gem 'rails-controller-testing', '~> 1.0.2'

  gem 'capybara', '~> 3.35.0'
  gem 'capybara-screenshot', '~> 1.0.17'
  gem 'selenium-webdriver', '~> 3.14'
  gem 'webdrivers', '~> 4.6.0'

  gem 'fuubar', '~> 2.5.0'
  gem 'timecop', '~> 0.9.0'

  # Mock backend requests (for ruby tests)
  gem 'webmock', '~> 3.12', require: false

  # Mock selenium requests through proxy (for feature tests)
  gem 'puffing-billy', '~> 2.4.0'
  gem 'table_print', '~> 1.5.6'

  gem 'equivalent-xml', '~> 0.6'
  gem 'json_spec', '~> 1.1.4'
  gem 'shoulda-matchers', '~> 4.5', require: nil

  gem 'parallel_tests', '~> 3.1'
end

group :ldap do
  gem 'net-ldap', '~> 0.17.0'
end

group :development do
  gem 'listen', '~> 3.5.1' # Use for event-based reloaders

  gem 'faker'
  gem 'letter_opener'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'

  # Gems for living styleguide
  gem 'livingstyleguide', '~> 2.1.0'
  gem 'sassc-rails'
end

group :development, :test do
  # Require factory_bot for usage with openproject plugins testing
  gem 'factory_bot', '~> 6.2.0'
  # require factory_bot_rails for convenience in core development
  gem 'factory_bot_rails', '~> 6.2.0'

  # Tracing and profiling gems
  gem 'flamegraph', require: false
  gem 'rack-mini-profiler', require: false
  gem 'ruby-prof', require: false
  gem 'stackprof', require: false

  gem 'pry-byebug', '~> 3.9.0', platforms: [:mri]
  gem 'pry-rails', '~> 0.3.6'
  gem 'pry-rescue', '~> 1.5.2'
  gem 'pry-stack_explorer', '~> 0.6.0'

  # Brakeman scanner
  gem 'brakeman', '~> 5.0.0'
  gem 'danger-brakeman'
end

gem 'bootsnap', '~> 1.7.0', require: false

# API gems
gem 'grape', '~> 1.5.0'
gem 'roar', '~> 1.1.0'

# CORS for API
gem 'rack-cors', '~> 1.1.1'

# Required for contracts
gem 'disposable', '~> 0.4.7'

platforms :mri, :mingw, :x64_mingw do
  group :postgres do
    gem 'pg', '~> 1.2.2'
  end

  # Support application loading when no database exists yet.
  gem 'activerecord-nulldb-adapter', '~> 0.7.0'

  # Have application level locks on the database to have a mutex shared between workers/hosts.
  # We e.g. employ this to safeguard the creation of journals.
  gem 'with_advisory_lock', '~> 4.6.0'
end

gem 'openproject-translations',
    git: 'https://github.com/opf/openproject-translations.git',
    branch: 'dev'

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob File.expand_path('{Gemfile.plugins,Gemfile.modules,Gemfile.local,lib/plugins/*/Gemfile}',
                                     __dir__)
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)

  eval_gemfile(file)
end
