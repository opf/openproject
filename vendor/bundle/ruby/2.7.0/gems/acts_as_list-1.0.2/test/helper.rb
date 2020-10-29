# frozen_string_literal: true

# $DEBUG = true

require "rubygems"
require "bundler/setup"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require "active_record"
require "minitest/autorun"
require "mocha/minitest"
require "#{File.dirname(__FILE__)}/../init"

if defined?(ActiveRecord::VERSION) &&
  ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 2

  # Was removed in Rails 5 and is effectively true.
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

db_config = YAML.load_file(File.expand_path("../database.yml", __FILE__)).fetch(ENV["DB"] || "sqlite")
ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Schema.verbose = false

def teardown_db
  if ActiveRecord::VERSION::MAJOR >= 5
    tables = ActiveRecord::Base.connection.data_sources
  else
    tables = ActiveRecord::Base.connection.tables
  end

  tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

require "shared"

# require 'logger'
# ActiveRecord::Base.logger = Logger.new(STDOUT)

def assert_equal_or_nil(a, b)
  if a.nil?
    assert_nil b
  else
    assert_equal a, b
  end
end
