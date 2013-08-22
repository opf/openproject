source 'https://rubygems.org'

gem "rails", "~> 3.2.14"

gem "coderay", "~> 1.0.5"
gem "rubytree", "~> 0.8.3"
gem "rdoc", ">= 2.4.2"
# Needed only on RUBY_VERSION = 1.8, ruby 1.9+ compatible interpreters should bring their csv
gem "fastercsv", "~> 1.5.0", :platforms => [:ruby_18, :jruby, :mingw_18]
# master includes the uniqueness validator, formerly patched in config/initializers/globalize3_patch.rb
gem 'globalize3', :git => 'https://github.com/svenfuchs/globalize3.git'
gem "delayed_job_active_record" # that's how delayed job's readme recommends it

# TODO: adds #auto_link which was deprecated in rails 3.1
gem 'rails_autolink'
gem "will_paginate", '~> 3.0'
gem "acts_as_list", "~> 0.2.0"

gem 'awesome_nested_set'

gem 'color-tools', '~> 1.3.0', :require => 'color'

gem 'tinymce-rails'
gem 'tinymce-rails-langs'

gem 'loofah'

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

gem 'execjs'
gem 'therubyracer'

# will need to be removed once we are on rails4 as it will be part of the rails4 core
gem 'strong_parameters'

group :production do
  # we use dalli as standard memcache client remove this if you don't
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

group :test do
  gem 'shoulda'
  gem 'object-daddy', :git => 'https://github.com/awebneck/object_daddy.git'
  gem 'mocha', '~> 0.13.1', :require => false
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
  gem 'pry-byebug', :platforms => :mri_20
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
    gem 'pg'
  end

  group :sqlite do
    gem "sqlite3"
  end
end

platforms :mri_18, :mingw_18 do
  group :mysql do
    gem "mysql"
    #   gem "ruby-mysql"
  end
end

platforms :mri_19, :mingw_19 do
  group :mysql2 do
    gem "mysql2", "~> 0.3.11"
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
