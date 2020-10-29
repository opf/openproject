source 'https://rubygems.org'

gemspec

version = ENV['AR_VERSION'].to_f

mysql2_version = '0.3.0'
mysql2_version = '0.4.0' if version >= 4.2
sqlite3_version = '1.3.0'
sqlite3_version = '1.4.0' if version >= 6.0

group :development, :test do
  gem 'rubocop', '~> 0.40.0'
  gem 'rake'
end

# Database Adapters
platforms :ruby do
  gem "mysql2",                 "~> #{mysql2_version}"
  gem "pg",                     "~> 0.9"
  gem "sqlite3",                "~> #{sqlite3_version}"
  gem "seamless_database_pool", "~> 1.0.20"
end

platforms :jruby do
  gem "jdbc-mysql"
  gem "jdbc-postgres"
  gem "activerecord-jdbcsqlite3-adapter",    "~> 1.3"
  gem "activerecord-jdbcmysql-adapter",      "~> 1.3"
  gem "activerecord-jdbcpostgresql-adapter", "~> 1.3"
end

# Support libs
gem "factory_bot"
gem "timecop"
gem "chronic"
gem "mocha", "~> 1.3.0"

# Debugging
platforms :jruby do
  gem "ruby-debug", "= 0.10.4"
end

platforms :mri_19 do
  gem "debugger"
end

platforms :ruby do
  gem "pry-byebug"
  gem "pry", "~> 0.12.0"
  gem "rb-readline"
end

if version >= 4.0
  gem "minitest"
else
  gem "test-unit"
end

eval_gemfile File.expand_path("../gemfiles/#{version}.gemfile", __FILE__)
