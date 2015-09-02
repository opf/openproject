#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

source 'https://rubygems.org'

gem "rails", "~> 3.2.22"

gem "coderay", "~> 1.0.9"
gem "rubytree", "~> 0.8.3"
gem "rdoc", ">= 2.4.2"
gem 'globalize', "~> 3.1.0"
gem 'omniauth'
gem 'request_store', "~> 1.1.0"
gem 'gravatar_image_tag', '~> 1.2.0'

gem 'warden', '~> 1.2'
gem 'warden-basic_auth', '~> 0.2.1'

# TODO: adds #auto_link which was deprecated in rails 3.1
gem 'rails_autolink', '~> 1.1.6'
gem "will_paginate", '~> 3.0'
gem "acts_as_list", "~> 0.3.0"

gem 'awesome_nested_set'

gem 'color-tools', '~> 1.3.0', :require => 'color'

gem "ruby-progressbar"

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

# generates SVG Graphs
# used for statistics on svn repositories
gem 'svg-graph'

gem "date_validator", '~> 0.7.1'
gem 'ruby-duration', '~> 3.2.0'

# We rely on this specific version, which is the latest as of now (end of 2013),
# because we have to apply to it a bugfix which could break things in other versions.
# This can be removed as soon as said bugfix is integrated into rabl itself.
# See: config/initializers/rabl_hack.rb
gem 'rabl', '0.9.3'
gem 'multi_json', '~> 1.11.0'
gem 'oj', '~> 2.11.4'

# will need to be removed once we are on rails4 as it will be part of the rails4 core
gem 'strong_parameters'

# we need the old Version to be compatible with pgsql 8.4
# see: http://stackoverflow.com/questions/14862144/rake-jobswork-gives-pgerror-error-select-for-update-share-is-not-allowed-in
# or: https://github.com/collectiveidea/delayed_job/issues/323
gem 'delayed_job_active_record', '0.3.3'
gem 'daemons'

# include custom rack-protection for now until rkh/rack-protection is fixed and released
# (see https://community.openproject.org/work_packages/3029)
gem 'rack-protection', :git => "https://github.com/finnlabs/rack-protection.git", :ref => '5a7d1bd'

# Rack::Attack is a rack middleware to protect your web app from bad clients.
# It allows whitelisting, blacklisting, throttling, and tracking based on arbitrary properties of the request.
# https://github.com/kickstarter/rack-attack
gem 'rack-attack'

gem 'gon', '~> 4.0'

# catch exceptions and send them to any airbrake compatible backend
gem 'airbrake', '~> 4.1.0'

group :production do
  # we use dalli as standard memcache client
  # requires memcached 1.4+
  # see https://github.com/mperham/dalli
  gem 'dalli', '~> 2.7.2'
end

gem 'sprockets',       git: 'https://github.com/finnlabs/sprockets.git',
                       branch: '2_2_3_backport2'
gem 'sprockets-rails', git: 'https://github.com/finnlabs/sprockets-rails.git',
                       branch: 'backport_w_2_2_3_sprockets'
gem 'non-stupid-digest-assets'
gem 'sass-rails',        git: 'https://github.com/guilleiguaran/sass-rails.git', branch: 'backport'
gem 'sass',             '~> 3.4.12'
gem 'autoprefixer-rails'
gem 'execjs',           '~> 2.4.0'
gem 'bourbon',          '~> 4.2.0'
gem 'uglifier',         '>= 1.0.3', require: false
gem 'livingstyleguide', '~> 1.2.2'

gem "prototype-rails"
# remove once we no longer use the deprecated "link_to_remote", "remote_form_for" and alike methods
# replace those with :remote => true
gem 'prototype_legacy_helper', '0.0.0', :git => 'https://github.com/rails/prototype_legacy_helper.git'

# small wrapper around the command line
gem 'cocaine'

# required by Procfile, for deployment on heroku or packaging with packager.io.
# also, better than thin since we can control worker concurrency.
gem 'unicorn'

# Security fixes
# Gems we don't depend directly on, but specify here to make sure we don't use a vulnerable
# version. Please add a link to a security advisory when adding a Gem here.

gem 'rack', '~>1.4.7'

gem 'i18n', '~> 0.6.8'
# see https://groups.google.com/forum/#!topic/ruby-security-ann/pLrh6DUw998

gem 'nokogiri', '~> 1.6.6'

gem 'carrierwave', '~> 0.10.0'
gem 'fog', '~> 1.23.0', require: "fog/aws/storage"

group :test do
  gem 'rack-test', '~> 0.6.2'
  gem 'shoulda-context', '~> 1.2'

  gem 'object-daddy', '~> 1.1.0'
  gem "launchy", "~> 2.3.0"
  gem "factory_girl_rails", "~> 4.5"
  gem 'cucumber-rails', "~> 1.4.2", :require => false
  gem 'rack_session_access'
  # restrict because in version 1.3 a lot of tests using acts as journalized
  # fail stating: "Column 'user_id' cannot be null". I don't understand the
  # connection with database cleaner here but setting it to 1.2 fixes the
  # issue.
  gem 'database_cleaner', '~> 1.2.0'
  gem 'rspec', '~> 3.2.0'
  # also add to development group, so "spec" rake task gets loaded
  gem 'rspec-rails', '~> 3.2.0', group: :development
  gem 'rspec-activemodel-mocks'
  gem 'rspec-example_disabler', git: "https://github.com/finnlabs/rspec-example_disabler.git"
  gem 'rspec-legacy_formatters'
  gem 'capybara', '~> 2.3.0'
  gem 'capybara-screenshot', '~> 1.0.4'
  gem 'capybara-select2', github: 'goodwill/capybara-select2'
  gem 'capybara-ng', '~> 0.2.1'
  gem 'selenium-webdriver', '~> 2.45.0'
  gem 'timecop', '~> 0.7.1'

  gem 'rb-readline', "~> 0.5.1" # ruby on CI needs this
  # why in Gemfile? see: https://github.com/guard/guard-test
  gem 'ruby-prof'
  gem 'simplecov', '0.8.0.pre'
  gem "shoulda-matchers", '~> 2.8', require: nil
  gem "json_spec"
  gem "activerecord-tableless", "~> 1.0"
  gem 'codecov', require: nil
  gem 'equivalent-xml', '~> 0.5.1'
end

group :ldap do
  gem "net-ldap", '~> 0.8.0'
end



# Optional groups are only available with Bundler 1.10+
# We still want older bundlers to parse this gemfile correctly,
# thus this rather ugly workaround is needed.
if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new('1.10.0')
  group :syck, optional: true do
    gem "syck", require: false
  end
else
  gem "syck", require: false
end

group :development do
  gem 'letter_opener', '~> 1.3.0'
  gem 'rails-dev-tweaks', '~> 0.6.1'
  gem 'thin'
  gem 'faker'
  gem 'quiet_assets'
  gem 'rubocop', '~> 0.28'
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'pry-rescue'
  gem 'pry-byebug', :platforms => [:mri]
  gem 'pry-doc'
end

# API gems
gem 'grape', '~> 0.10.1'
gem 'roar',   '~> 1.0.0'
gem 'reform', '~> 1.2.6', require: false

# Use the commented pure ruby gems, if you have not the needed prerequisites on
# board to compile the native ones.  Note, that their use is discouraged, since
# their integration is propbably not that well tested and their are slower in
# orders of magnitude compared to their native counterparts. You have been
# warned.

platforms :mri, :mingw, :x64_mingw do
  group :mysql2 do
    gem "mysql2", "~> 0.3.11"
  end

  group :postgres do
    gem 'pg', "~> 0.17.1"
  end
end

platforms :jruby do
  gem "jruby-openssl"

  group :mysql do
    gem "activerecord-jdbcmysql-adapter"
  end

  group :postgres do
    gem "activerecord-jdbcpostgresql-adapter"
  end
end

group :opf_plugins do
  gem 'openproject-translations', git:'https://github.com/opf/openproject-translations.git', branch: 'release/4.2'
end

# Load Gemfile.local, Gemfile.plugins and plugins' Gemfiles
Dir.glob File.expand_path("../{Gemfile.local,Gemfile.plugins,lib/plugins/*/Gemfile}", __FILE__) do |file|
  next unless File.readable?(file)
  eval_gemfile(file)
end
