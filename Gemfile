source 'https://rubygems.org'

gem 'rails', '3.2.9'

gem "coderay", "~> 1.0.5"
gem "rubytree", "~> 0.8.3"
gem "rdoc", ">= 2.4.2"
# Needed only on RUBY_VERSION = 1.8, ruby 1.9+ compatible interpreters should bring their csv
gem "fastercsv", "~> 1.5.0", :platforms => [:ruby_18, :jruby, :mingw_18]
# master includes the uniqueness validator, formerly patched in config/initializers/globalize3_patch.rb
gem 'globalize3', :git => 'git://github.com/svenfuchs/globalize3.git'
gem "delayed_job_active_record" # that's how delayed job's readme recommends it

# TODO: adds #auto_link which was deprecated in rails 3.1
gem 'rails_autolink'

gem 'awesome_nested_set'

gem 'tinymce-rails'
gem 'tinymce-rails-langs'

gem 'loofah'

# to generate html-diffs (e.g. for wiki comparison)
gem 'htmldiff'

gem 'therubyracer'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-ui-rails'
end

gem "prototype-rails"
gem 'jquery-rails'

group :test do
  gem 'shoulda', '~> 3.1.1'
  gem 'object-daddy', :git => 'git://github.com/awebneck/object_daddy.git'
  gem 'mocha'
  gem "launchy", "~> 2.1.0"
  gem "factory_girl_rails", "~> 4.0"
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem "rspec-rails", "~> 2.0", :group => :development
  gem 'capybara'
  gem 'spork-rails'
  gem 'spork-testunit' # needed for test-unit only

  gem 'ruby-debug', :platforms => [:mri_18, :mingw_18]
  # TODO: remove dependency to v 1.1.3 when pry-debugger is updated to > 0.2
  gem 'debugger', '~> 1.1.3', :platforms => [:mri_19, :mingw_19]
  # why in Gemfile? see: https://github.com/guard/guard-test
  gem 'ruby-prof'
end

group :openid do
  gem "ruby-openid", '~> 2.1.4', :require => 'openid'
end

gem 'openproject-themes', :git => 'git@github.com:finnlabs/openproject-themes.git'
gem 'landing_page', :git => 'git@github.com:finnlabs/chiliproject_landing_page.git', :branch => 'rails3'

group :development do
  gem 'rails-footnotes', '>= 3.7.5.rc4'
  gem 'bullet'
  gem 'letter_opener', '~> 1.0.0'
  gem 'rails-dev-tweaks', '~> 0.6.1'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'guard-spork'
  gem 'rb-fsevent', :group => :test, :require => false if RUBY_PLATFORM =~ /darwin/i
  gem 'rack-mini-profiler'
end

group :development, :test do
  gem 'pry-rails', '~> 0.2.2'
  gem 'pry-stack_explorer'
  gem 'pry-rescue'
  gem 'pry-debugger'
  gem 'pry-doc'
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
end

platforms :mri_18, :mingw_18 do
  group :mysql do
    gem "mysql"
    #   gem "ruby-mysql"
  end

  group :sqlite do
    gem "sqlite3-ruby", "< 1.3", :require => "sqlite3"
  end
end

platforms :mri_19, :mingw_19 do
  group :sqlite do
    gem "sqlite3"
  end

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

# Load a "local" Gemfile
gemfile_local = File.join(File.dirname(__FILE__), "Gemfile.local")
if File.readable?(gemfile_local)
  puts "Loading #{gemfile_local} ..." if $DEBUG
  instance_eval(File.read(gemfile_local))
end

# Load plugins' Gemfiles
Dir.glob File.expand_path("../vendor/plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
end
