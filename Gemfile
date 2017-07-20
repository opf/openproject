#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

source 'https://rubygems.org'

ruby '~> 2.4.1'

gem 'actionpack-xml_parser', '~> 2.0.0'
gem 'activemodel-serializers-xml', '~> 1.0.1'
gem 'activerecord-session_store', '~> 1.1.0'
gem 'rails', '~> 5.0.4'
gem 'responders', '~> 2.4'

gem 'coderay', '~> 1.1.0'
gem 'rubytree', git: 'https://github.com/dr0verride/RubyTree.git', ref: '06f53ee'
gem 'rdoc', '>= 2.4.2'

gem 'globalize', git: 'https://github.com/globalize/globalize', ref: '38443bcd', require: false
gem 'omniauth', git: 'https://github.com/oliverguenther/omniauth', ref: '40c6f5f751d2da7cce5444bbd96c390c450440a9'
gem 'request_store', '~> 1.3.1'
gem 'gravatar_image_tag', '~> 1.2.0'

gem 'warden', '~> 1.2'
gem 'warden-basic_auth', '~> 0.2.1'

# TODO: adds #auto_link which was deprecated in rails 3.1
gem 'rails_autolink', '~> 1.1.6'
gem 'will_paginate', '~> 3.1.0'

gem 'friendly_id', '~> 5.2.1'

gem 'acts_as_list', '~> 0.9.7'
gem 'acts_as_tree', '~> 2.6.1'
gem 'awesome_nested_set', '~> 3.1.3'

gem 'color-tools', '~> 1.3.0', require: 'color'

gem 'ruby-progressbar'

# Provide timezone info for TZInfo used by AR
gem 'tzinfo-data', '~> 1.2017.2'

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

# Generate url slugs with #to_url and other string niceties
gem 'stringex', '~> 2.7.1'

# generates SVG Graphs
# used for statistics on svn repositories
gem 'svg-graph', '~> 2.1.0'

gem 'date_validator', '~> 0.9.0'
gem 'ruby-duration', '~> 3.2.0'

# provide compatible filesystem information for available storage
gem 'sys-filesystem', '~> 1.1.4', require: false

gem 'bcrypt', '~> 3.1.6'

gem 'multi_json', '~> 1.12.1'
gem 'oj', '~> 3.3.2'
# We rely on this specific version, which is the latest as of now (end of 2016),
# because we have to apply to it a bugfix which could break things in other versions.
# This can be removed as soon as said bugfix is integrated into rabl itself.
# See: config/initializers/rabl_hack.rb
gem 'rabl', '~> 0.13.0'

gem 'daemons'
gem 'delayed_job_active_record', '~> 4.1.1'

gem 'rack-protection', '~> 2.0.0'

# Rack::Attack is a rack middleware to protect your web app from bad clients.
# It allows whitelisting, blacklisting, throttling, and tracking based
# on arbitrary properties of the request.
# https://github.com/kickstarter/rack-attack
gem 'rack-attack', '~> 5.0.1'

# Providing health checks
gem 'okcomputer', '~> 1.16.0'

# Patch Rails HTML whitelisting for Angular curly braces
gem 'rails-angular-xss', git: 'https://github.com/opf/rails-angular-xss', ref: 'a45267d5'

gem 'gon', '~> 6.1.0'
gem "syck", '~> 1.3.0', require: false

# catch exceptions and send them to any airbrake compatible backend
# don't require by default, instead load on-demand when actually configured
gem 'airbrake', '~> 5.1.0', require: false

gem 'transactional_lock', git: 'https://github.com/finnlabs/transactional_lock.git',
                          branch: 'master'

gem 'prawn', '~> 2.2'
gem 'prawn-table', '~> 0.2.2'

gem 'cells-rails', '~> 0.0.6'
gem 'cells-erb', '~> 0.0.8'

group :production do
  # we use dalli as standard memcache client
  # requires memcached 1.4+
  # see https://github.clientom/mperham/dalli
  gem 'dalli', '~> 2.7.6'

  # Unicorn worker killer to restart unicorn child workers
  gem 'unicorn-worker-killer', require: false
end

gem 'autoprefixer-rails', '~> 7.1.2.3'
gem 'bourbon', '~> 4.3.4'
gem 'i18n-js', '~> 3.0.0'
gem 'sass', '3.5.1'
gem 'sass-rails', '~> 5.0.6'
gem 'sprockets', '~> 3.7.0'

# small wrapper around the command line
gem 'cocaine', '~> 0.5.8'

# required by Procfile, for deployment on heroku or packaging with packager.io.
# also, better than thin since we can control worker concurrency.
gem 'unicorn'

gem 'nokogiri', '~> 1.8.0'

# carrierwave 0.11.3 should allow to use fog-aws without the rest of the
# fog dependency chain. We only need aws here, so we can avoid it
# at the cost of referencing carrierwave#master for now.
gem 'fog-aws'
gem 'carrierwave', git: 'https://github.com/carrierwaveuploader/carrierwave', branch: 'master'

gem 'openproject-token', '~> 1.0.1'

group :test do
  gem 'rack-test', '~> 0.6.3'
  gem 'shoulda-context', '~> 1.2'
  gem 'launchy', '~> 2.4.3'

  # Require factory_girl for usage with openproject plugins testing
  # FactoryGirl needs to be available when loading app otherwise factory
  # definitions from core are not available in the plugin thus specs break
  gem 'factory_girl', '~> 4.5'
  # require factory_girl_rails for convenience in core development
  gem 'factory_girl_rails', '~> 4.7', require: false

  gem 'cucumber', '~> 2.4.0'
  gem 'cucumber-rails', '~> 1.4.4', require: false
  gem 'database_cleaner', '~> 1.6'
  gem 'rack_session_access'
  # not possible to upgrade to 3.6+ until rails is 5.1+
  gem 'rspec', '~> 3.5.0'
  # also add to development group, so "spec" rake task gets loaded
  gem 'rspec-rails', '~> 3.5.2', group: :development
  gem 'rspec-activemodel-mocks', '~> 1.0.3', git: 'https://github.com/rspec/rspec-activemodel-mocks'

  # Retry failures within the same environment
  gem 'retriable', '~> 3.0'
  gem 'rspec-retry', '~> 0.5.2'

  gem 'rspec-example_disabler', git: 'https://github.com/finnlabs/rspec-example_disabler.git'
  gem 'rspec-legacy_formatters', '~> 1.0.1', require: false

  # brings back testing for 'assigns' and 'assert_template' extracted in rails 5
  gem 'rails-controller-testing', '~> 1.0.2'

  gem 'aws-sdk', '~> 2.10.1'
  gem 'capybara', '~> 2.14.0'
  gem 'capybara-screenshot', '~> 1.0.14'
  gem 'fuubar', '~> 2.2.0'
  gem 'capybara-select2', git: 'https://github.com/goodwill/capybara-select2', ref: '585192e'
  gem 'capybara-ng', '~> 0.2.7'
  gem 'selenium-webdriver', '~> 3.4'
  gem 'timecop', '~> 0.9.0'
  gem 'webmock', '~> 3.0.0', require: false

  gem 'simplecov', '~> 0.14.0', require: false
  gem 'shoulda-matchers', '~> 3.1', require: nil
  gem 'json_spec', '~> 1.1.4'
  gem 'equivalent-xml', '~> 0.6'

  gem 'parallel_tests', '~> 2.14.0'
end

group :ldap do
  gem 'net-ldap', '~> 0.16.0'
end

group :development do
  gem 'letter_opener'
  gem 'faker'
  gem 'livingstyleguide', '~> 2.0.1'

  gem 'rubocop'
  gem 'active_record_query_trace'
end

group :development, :test do
  gem 'thin', '~> 1.7.2'

  gem 'pry-rails', '~> 0.3.6'
  gem 'pry-stack_explorer', '~> 0.4.9.2'
  gem 'pry-rescue', '~> 1.4.5'
  gem 'pry-byebug', '~> 3.4.2', platforms: [:mri]
  gem 'pry-doc', '~> 0.10'
end

# API gems
gem 'grape', '~> 1.0'

gem 'reform', '~> 2.2.0'
gem 'reform-rails', '~> 0.1.7'
gem 'roar', '~> 1.1.0'

platforms :mri, :mingw, :x64_mingw do
  group :mysql2 do
    gem 'mysql2', '~> 0.4.4'
  end

  group :postgres do
    gem 'pg', '~> 0.21.0'
  end
end

platforms :jruby do
  gem 'jruby-openssl'

  group :mysql do
    gem 'activerecord-jdbcmysql-adapter'
  end

  group :postgres do
    gem 'activerecord-jdbcpostgresql-adapter'
  end
end

group :opf_plugins do
  gem 'openproject-translations', git: 'https://github.com/opf/openproject-translations.git', branch: 'dev'
end

# TODO: Make this group :optional when bundler v10.x
# is matured enough that we can use this everywhere
# http://bundler.io/blog/2015/06/24/version-1-10-released.html
group :docker do
  gem 'passenger'

  # Used to easily precompile assets
  gem 'sqlite3', require: false
  gem 'rails_12factor', require: !!ENV['HEROKU']
  gem 'health_check', require: !!ENV['HEROKU']
  gem 'newrelic_rpm', require: !!ENV['HEROKU']
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob File.expand_path('../{Gemfile.local,Gemfile.plugins,lib/plugins/*/Gemfile}',
                                     __FILE__)
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)
  eval_gemfile(file)
end
