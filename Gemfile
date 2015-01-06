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

gem "rails", "~> 3.2.21"

gem "coderay", "~> 1.0.5"
gem "rubytree", "~> 0.8.3"
gem "rdoc", ">= 2.4.2"
gem 'globalize'
gem 'omniauth'
gem 'request_store'
gem 'gravatar_image_tag', '~> 1.2.0'

# TODO: adds #auto_link which was deprecated in rails 3.1
gem 'rails_autolink'
gem "will_paginate", '~> 3.0'
gem "acts_as_list", "~> 0.2.0"

gem 'awesome_nested_set'

gem 'color-tools', '~> 1.3.0', :require => 'color'

gem "ruby-progressbar"

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

# generates SVG Graphs
# used for statistics on svn repositories
gem 'svg-graph'

gem "date_validator"
gem 'ruby-duration', '~> 3.2.0'

# We rely on this specific version, which is the latest as of now (end of 2013),
# because we have to apply to it a bugfix which could break things in other versions.
# This can be removed as soon as said bugfix is integrated into rabl itself.
# See: config/initializers/rabl_hack.rb
gem 'rabl', '0.9.3'
gem 'multi_json'
gem 'oj'

# will need to be removed once we are on rails4 as it will be part of the rails4 core
gem 'strong_parameters'

# we need the old Version to be compatible with pgsql 8.4
# see: http://stackoverflow.com/questions/14862144/rake-jobswork-gives-pgerror-error-select-for-update-share-is-not-allowed-in
# or: https://github.com/collectiveidea/delayed_job/issues/323
gem 'delayed_job_active_record', '0.3.3'
gem 'daemons'

# include custom rack-protection for now until rkh/rack-protection is fixed and released
# (see https://www.openproject.org/work_packages/3029)
gem 'rack-protection', :git => "https://github.com/finnlabs/rack-protection.git", :ref => '5a7d1bd'

gem 'syck', :platforms => [:ruby_20, :mingw_20, :ruby_21, :mingw_21], :require => false

gem 'gon', '~> 4.0'

group :production do
  # we use dalli as standard memcache client
  # requires memcached 1.4+
  # see https://github.com/mperham/dalli
  gem 'dalli'
end

gem 'sprockets',        git: 'https://github.com/tessi/sprockets.git', branch: '2_2_2_backport2'
gem 'sprockets-rails',  git: 'https://github.com/finnlabs/sprockets-rails.git', branch: 'backport'
gem 'non-stupid-digest-assets'
gem 'sass-rails',        git: 'https://github.com/guilleiguaran/sass-rails.git', branch: 'backport'
gem 'sass',             '~> 3.3.6'
gem 'bourbon',          '~> 4.0'
gem 'uglifier',         '>= 1.0.3', require: false
gem 'livingstyleguide', '~> 1.2.0'

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

gem 'i18n', '>=0.6.8'
# see https://groups.google.com/forum/#!topic/ruby-security-ann/pLrh6DUw998

gem 'nokogiri', '>=1.5.11'
# see https://groups.google.com/forum/#!topic/ruby-security-ann/DeJpjTAg1FA

group :test do
  gem 'rack-test', '~> 0.6.2'
  gem 'shoulda'
  gem 'object-daddy', '~> 1.1.0'
  gem "launchy", "~> 2.3.0"
  gem "factory_girl_rails", "~> 4.0"
  gem 'cucumber-rails', :require => false
  gem 'rack_session_access'
  # restrict because in version 1.3 a lot of tests using acts as journalized
  # fail stating: "Column 'user_id' cannot be null". I don't understand the
  # connection with database cleaner here but setting it to 1.2 fixes the
  # issue.
  gem 'database_cleaner', '~> 1.2.0'
  gem "cucumber-rails-training-wheels" # http://aslakhellesoy.com/post/11055981222/the-training-wheels-came-off
  gem 'rspec', '~> 2.99.0'
  # also add to development group, so "spec" rake task gets loaded
  gem "rspec-rails", "~> 2.99.0", :group => :development
  gem 'rspec-activemodel-mocks'
  gem 'rspec-example_disabler', git: "https://github.com/finnlabs/rspec-example_disabler.git"
  gem 'capybara', '~> 2.3.0'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver', '~> 2.44.0'
  gem 'timecop', "~> 0.6.1"

  gem 'rb-readline', "~> 0.5.1" # ruby on CI needs this
  # why in Gemfile? see: https://github.com/guard/guard-test
  gem 'ruby-prof'
  gem 'simplecov', '0.8.0.pre'
  gem "shoulda-matchers"
  gem "json_spec"
  gem "activerecord-tableless", "~> 1.0"
  gem "codeclimate-test-reporter", :require => nil
  gem 'test-unit', '2.5.5'
end

group :ldap do
  gem "net-ldap", '~> 0.8.0'
end

group :development do
  gem 'letter_opener', '~> 1.0.0'
  gem 'rails-dev-tweaks', '~> 0.6.1'
  gem 'thin'
  gem 'faker'
  gem 'quiet_assets'
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
gem 'reform', '~> 1.2.4', require: false

# Use the commented pure ruby gems, if you have not the needed prerequisites on
# board to compile the native ones.  Note, that their use is discouraged, since
# their integration is propbably not that well tested and their are slower in
# orders of magnitude compared to their native counterparts. You have been
# warned.

platforms :mri, :mingw do
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

# Load Gemfile.local, Gemfile.plugins and plugins' Gemfiles
Dir.glob File.expand_path("../{Gemfile.local,Gemfile.plugins,lib/plugins/*/Gemfile}", __FILE__) do |file|
  next unless File.readable?(file)
  instance_eval File.read(file)
end
