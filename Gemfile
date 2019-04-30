#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

ruby '~> 2.6.1'

gem 'actionpack-xml_parser', '~> 2.0.0'
gem 'activemodel-serializers-xml', '~> 1.0.1'
gem 'activerecord-session_store', '~> 1.1.0'
gem 'rails', '~> 5.2.2.1'
gem 'responders', '~> 2.4'

gem 'rdoc', '>= 2.4.2'

# Maintain our own omniauth due to relative URL root issues
# see upstream PR: https://github.com/omniauth/omniauth/pull/903
gem 'omniauth', git: 'https://github.com/opf/omniauth', ref: 'fe862f986b2e846e291784d2caa3d90a658c67f0'
gem 'doorkeeper', git: 'https://github.com/doorkeeper-gem/doorkeeper', ref: 'ce969eee6c16aa8082b0c77ebb5968d9e9b6a57b'
gem 'request_store', '~> 1.4.1'

gem 'warden', '~> 1.2'
gem 'warden-basic_auth', '~> 0.2.1'

gem 'will_paginate', '~> 3.1.0'

gem 'friendly_id', '~> 5.2.1'

gem 'acts_as_list', '~> 0.9.9'
gem 'acts_as_tree', '~> 2.8.0'
gem 'awesome_nested_set', '~> 3.1.3'
gem 'rubytree', git: 'https://github.com/dr0verride/RubyTree.git', ref: '06f53ee'
gem 'typed_dag', '~> 2.0.2'

gem 'addressable', '~> 2.6.0'

# Provide timezone info for TZInfo used by AR
gem 'tzinfo-data', '~> 1.2018.9'

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

# Generate url slugs with #to_url and other string niceties
gem 'stringex', '~> 2.8.5'

# CommonMark markdown parser with GFM extension
gem 'commonmarker', '~> 0.17.9'

# HTML pipeline for transformations on text formatter output
# such as sanitization or additional features
gem 'html-pipeline', '~> 2.8.0'
# Requires escape-utils for faster escaping
gem 'escape_utils', '~> 1.0'
# Syntax highlighting used in html-pipeline with rouge
gem 'rouge', '~> 3.1.1'
# HTML sanitization used for html-pipeline
gem 'sanitize', '~> 5.0.0'
# HTML autolinking for mails and urls (replaces autolink)
gem 'rinku', '~> 2.0.4'
# Version parsing with semver
gem 'semantic', '~> 1.6.1'

# generates SVG Graphs
# used for statistics on svn repositories
gem 'svg-graph', '~> 2.1.0'

gem 'date_validator', '~> 0.9.0'
gem 'ruby-duration', '~> 3.2.0'

# provide compatible filesystem information for available storage
gem 'sys-filesystem', '~> 1.2.0', require: false

# Faster posix-compliant spawns for 8.0. conversions with pandoc
gem 'posix-spawn', '~> 0.3.13', require: false

gem 'bcrypt', '~> 3.1.6'

gem 'multi_json', '~> 1.13.1'
gem 'oj', '~> 3.7.0'
# We rely on this specific version, which is the latest as of now (start of 2019),
# because we have to apply to it a bugfix which could break things in other versions.
# This can be removed as soon as said bugfix is integrated into rabl itself.
# See: config/initializers/rabl_hack.rb
gem 'rabl', '~> 0.14.0'

gem 'daemons'
gem 'delayed_job_active_record', '~> 4.1.1'

gem 'rack-protection', '~> 2.0.0'

# Rack::Attack is a rack middleware to protect your web app from bad clients.
# It allows whitelisting, blacklisting, throttling, and tracking based
# on arbitrary properties of the request.
# https://github.com/kickstarter/rack-attack
gem 'rack-attack', '~> 5.4.2'

# CSP headers
gem 'secure_headers', '~> 6.0.0'

# Browser detection for incompatibility checks
gem 'browser', '~> 2.5.3'

# Providing health checks
gem 'okcomputer', '~> 1.17.3'

gem 'gon', '~> 6.2.1'

# Lograge to provide sane and non-verbose logging
gem 'lograge', '~> 0.10.0'

# catch exceptions and send them to any airbrake compatible backend
# don't require by default, instead load on-demand when actually configured
gem 'airbrake', '~> 8.0.1', require: false

gem 'transactional_lock', git: 'https://github.com/finnlabs/transactional_lock.git',
                          branch: 'master'

gem 'prawn', '~> 2.2'
gem 'prawn-table', '~> 0.2.2'

gem 'cells-erb', '~> 0.1.0'
gem 'cells-rails', '~> 0.0.9'

gem 'meta-tags', '~> 2.11.0'

group :production do
  # we use dalli as standard memcache client
  # requires memcached 1.4+
  # see https://github.clientom/mperham/dalli
  gem 'dalli',
      git: 'https://github.com/petergoldstein/dalli',
      ref: '0ff39199b5e91c6dbdaabc7c085b81938d0f08d2'

  # Unicorn worker killer to restart unicorn child workers
  gem 'unicorn-worker-killer', require: false
end

gem 'autoprefixer-rails', '~> 9.4.5'
# use until proper release no longer requiring sass exists
gem 'bourbon', git: 'https://github.com/sikachu/bourbon', ref: 'a12ca168e74d3468c80500b21b525a4e12a19ef9'
gem 'i18n-js', '~> 3.2.0'
gem 'sass-rails'
gem 'sassc-rails', '~> 2.1.0'
gem 'sprockets', '~> 3.7.0'

# required by Procfile, for deployment on heroku or packaging with packager.io.
# also, better than thin since we can control worker concurrency.
gem 'unicorn'

gem 'nokogiri', '~> 1.10.3'

gem 'carrierwave', '~> 1.3.1'
gem 'fog-aws'

gem 'aws-sdk-core', '~> 3.46.0'
# File upload via fog + screenshots on travis
gem 'aws-sdk-s3', '~> 1.30.1'

gem 'openproject-token', '~> 1.0.1'

gem 'plaintext', '~> 0.3.0'

gem 'rest-client', '~> 2.0'

gem 'ruby-progressbar', '~> 1.10.0', require: false

group :test do
  gem 'launchy', '~> 2.4.3'
  gem 'rack-test', '~> 1.1.0'
  gem 'shoulda-context', '~> 1.2'

  # Require factory_bot for usage with openproject plugins testing
  # FactoryBot needs to be available when loading app otherwise factory
  # definitions from core are not available in the plugin thus specs break
  gem 'factory_bot', '~> 4.8'
  # require factory_bot_rails for convenience in core development
  gem 'factory_bot_rails', '~> 4.8', require: false

  # Test prof provides factories from code
  # and other niceties
  gem 'test-prof', '~> 0.7.3'

  gem 'cucumber', '~> 3.1.0'
  gem 'cucumber-rails', '~> 1.6.0', require: false
  gem 'database_cleaner', '~> 1.6'
  gem 'rack_session_access'
  gem 'rspec', '~> 3.8.0'
  gem 'rspec-activemodel-mocks', '~> 1.1.0', git: 'https://github.com/rspec/rspec-activemodel-mocks'
  # also add to development group, so "spec" rake task gets loaded
  gem 'rspec-rails', '~> 3.8.1', group: :development

  # Retry failures within the same environment
  gem 'retriable', '~> 3.1.1'
  gem 'rspec-retry', '~> 0.6.1'

  gem 'rspec-example_disabler', git: 'https://github.com/finnlabs/rspec-example_disabler.git'

  # brings back testing for 'assigns' and 'assert_template' extracted in rails 5
  gem 'rails-controller-testing', '~> 1.0.2'

  gem 'capybara', '~> 3.13.0'
  gem 'capybara-screenshot', '~> 1.0.17'
  gem 'capybara-select2', git: 'https://github.com/goodwill/capybara-select2', ref: '585192e'
  gem 'chromedriver-helper', '~> 2.1.0'
  gem 'selenium-webdriver', '~> 3.14'

  gem 'fuubar', '~> 2.3.2'
  gem 'timecop', '~> 0.9.0'
  gem 'webmock', '~> 3.5.0', require: false

  gem 'equivalent-xml', '~> 0.6'
  gem 'json_spec', '~> 1.1.4'
  gem 'shoulda-matchers', '~> 3.1', require: nil
  gem 'simplecov', '~> 0.16.0', require: false

  gem 'parallel_tests', '~> 2.27.1'
end

group :ldap do
  gem 'net-ldap', '~> 0.16.0'
end

group :development do
  gem 'faker'
  gem 'letter_opener'
  gem 'livingstyleguide', '~> 2.0.1'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'rubocop'
end

group :development, :test do
  gem 'puma', '~> 3.12.0'
  gem 'thin', '~> 1.7.2'

  # Tracing and profiling gems
  gem 'flamegraph', require: false
  gem 'rack-mini-profiler', require: false
  gem 'ruby-prof', require: false
  gem 'stackprof', require: false

  gem 'pry-byebug', '~> 3.6.0', platforms: [:mri]
  gem 'pry-rails', '~> 0.3.6'
  gem 'pry-rescue', '~> 1.5.0'
  gem 'pry-stack_explorer', '~> 0.4.9.2'
end

gem 'bootsnap', '~> 1.3.2', require: false

# API gems
gem 'grape', '~> 1.2.3'

gem 'reform', '~> 2.2.0'
gem 'reform-rails', '~> 0.1.7'
gem 'roar', '~> 1.1.0'

platforms :mri, :mingw, :x64_mingw do
  group :mysql2 do
    gem 'mysql2', '~> 0.5.0'
  end

  group :postgres do
    gem 'pg', '~> 1.1.0'
  end

  # Support application loading when no database exists yet.
  gem 'activerecord-nulldb-adapter', '~> 0.3.9'
end

group :opf_plugins do
  gem 'openproject-translations', git: 'https://github.com/opf/openproject-translations.git', branch: 'dev'
end

group :docker, optional: true do
  gem 'passenger', '~> 6.0.1'

  # Used to easily precompile assets
  gem 'newrelic_rpm', require: !!ENV['HEROKU']
  gem 'rails_12factor', require: !!ENV['HEROKU']
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob File.expand_path('../{Gemfile.plugins,Gemfile.modules,Gemfile.local,lib/plugins/*/Gemfile}',
                                     __FILE__)
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)

  eval_gemfile(file)
end
