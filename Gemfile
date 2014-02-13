#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

gem "rails", "~> 3.2.18"

gem "coderay", "~> 1.0.5"
gem "rubytree", "~> 0.8.3"
gem "rdoc", ">= 2.4.2"
gem 'globalize'

gem 'request_store'

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

gem 'execjs'

gem 'therubyracer'

gem "date_validator"

# replacing rsb with rabl --
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

gem 'syck', :require => false

group :production do
  # we use dalli as standard memcache client
  # requires memcached 1.4+
  # see https://github.com/mperham/dalli
  gem 'dalli'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-ui-rails'
  gem 'select2-rails', '~> 3.3.2'
  gem 'jquery-atwho-rails'
end

gem "prototype-rails"
# remove once we no longer use the deprecated "link_to_remote", "remote_form_for" and alike methods
# replace those with :remote => true
gem 'prototype_legacy_helper', '0.0.0', :git => 'https://github.com/rails/prototype_legacy_helper.git'

gem 'jquery-rails', '~> 2.0.3'
# branch rewrite has commit 6bfdcd7e14df1efffc00b2bbdf4e14e614d00418 which adds
# a "magic comment" in the translations.js.erb and somehow breaks i18n-js
# using the commit before this comment
gem "i18n-js", :git => "https://github.com/fnando/i18n-js.git", :ref => '8801f8d17ef96c48a7a0269e251fcf1648c8f441'

# small wrapper around the command line
gem 'cocaine'


# Security fixes
# Gems we don't depend directly on, but specify here to make sure we don't use a vulnerable
# version. Please add a link to a security advisory when adding a Gem here.

gem 'i18n', '>=0.6.8'
# see https://groups.google.com/forum/#!topic/ruby-security-ann/pLrh6DUw998

gem 'nokogiri', '>=1.5.11'
# see https://groups.google.com/forum/#!topic/ruby-security-ann/DeJpjTAg1FA


group :test do
  gem 'shoulda'
  gem 'object-daddy', '~> 1.1.0'
  gem "launchy", "~> 2.3.0"
  gem "factory_girl_rails", "~> 4.0"
  gem 'cucumber-rails', :require => false
  gem 'rack_session_access'
  gem 'database_cleaner'
  gem "cucumber-rails-training-wheels" # http://aslakhellesoy.com/post/11055981222/the-training-wheels-came-off
  gem 'rspec', '~> 2.0'
  # also add to development group, so "spec" rake task gets loaded
  gem "rspec-rails", "~> 2.0", :group => :development
  gem 'rspec-example_disabler'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver'
  gem 'timecop', "~> 0.6.1"

  gem 'rb-readline' # ruby on CI needs this
  # why in Gemfile? see: https://github.com/guard/guard-test
  gem 'ruby-prof'
  gem 'simplecov', ">= 0.8.pre"
  gem "shoulda-matchers"
  gem "json_spec"
  gem "activerecord-tableless", "~> 1.0"
  gem "codeclimate-test-reporter", :require => nil
end

group :ldap do
  gem "net-ldap", '~> 0.2.2'
end

group :openid do
  gem "ruby-openid", '~> 2.2.3', :require => 'openid'
end

group :development do
  gem 'letter_opener', '~> 1.0.0'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'pry-rescue'
  gem 'pry-byebug', :platforms => [:mri_20,:mri_21]
  gem 'pry-debugger', :platforms => :mri_19
  gem 'pry-doc'
  gem 'rails-dev-tweaks', '~> 0.6.1'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'rb-fsevent', :group => :test
  gem 'thin'
  gem 'faker'
end

group :tools do
  # why tools? see: https://github.com/guard/guard-test
  gem 'guard-test'
end

group :rmagick do
  gem "rmagick", ">= 1.15.17"
  # Older distributions might not have a sufficiently new ImageMagick version
  # for the current rmagick release (current rmagick is rmagick 2, which
  # requires ImageMagick 6.4.9 or later). If this is the case for you, comment
  # the line above this comment block and uncomment the one underneath it to
  # get an rmagick version known to work on older distributions.
  #
  # The following distributíons are known to *not* ship with a usable
  # ImageMagick version. There might be additional ones.
  #   * Ubuntu 9.10 and older
  #   * Debian Lenny 5.0 and older
  #   * CentOS 5 and older
  #   * RedHat 5 and older
  #
  #gem "rmagick", "< 2.0.0"
end

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

  group :sqlite do
    gem "sqlite3"
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

  group :sqlite do
    gem "activerecord-jdbcsqlite3-adapter"
  end
end

# Load Gemfile.local, Gemfile.plugins and plugins' Gemfiles
Dir.glob File.expand_path("../{Gemfile.local,Gemfile.plugins,lib/plugins/*/Gemfile}", __FILE__) do |file|
  next unless File.readable?(file)
  instance_eval File.read(file)
end

