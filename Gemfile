source :rubygems

gem "rails", "2.3.11"

gem "coderay", "~> 0.9.7"
gem "i18n", "< 0.5" # explicit version 0.4.2 is used in config!
gem "ruby-openid"
gem "rubytree", "~> 0.5.2", :require => 'tree'

group :development, :test do
  gem 'shoulda', '~> 2.10.3'
  gem 'edavis10-object_daddy', :require => 'object_daddy'
  gem 'mocha'
end


# Use the commented pure ruby gems, if you have not the needed prerequisites on
# board to compile the native ones.  Note, that their use is discouraged, since
# their integration is propbably not that well tested and their are slower in
# orders of magnitude compared to their native counterparts. You have been
# warned.
#
platforms :mri do
  group :mysql do
    gem "mysql"
    #   gem "ruby-mysql"
  end

  group :mysql2 do
    gem "mysql2"
  end
  
  group :postgres do
    gem "pg", "~> 0.9.0"
    #   gem "postgres-pr"
  end
  
  group :sqlite do
    gem "sqlite3-ruby", "< 1.3", :require => "sqlite3"
    #   please tell me, if you are fond of a pure ruby sqlite3 binding
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

# Load plugins' Gemfiles
Dir.glob File.expand_path("../vendor/plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..."
  instance_eval File.read(file)
end
