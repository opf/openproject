#-- encoding: UTF-8
$:.unshift(File.dirname(__FILE__) + '/../lib')
plugin_test_dir = File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'multi_rails_init'
# gem 'activerecord', '>= 2.0'
require 'active_record' 
require 'action_controller'
require 'action_view'
require 'active_record/fixtures'

require plugin_test_dir + '/../init.rb'

ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

ActiveRecord::Base.configurations = YAML::load(IO.read(plugin_test_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection(ENV["DB"] || "sqlite3mem")
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))

Dir["#{plugin_test_dir}/fixtures/*.rb"].each {|file| require file }


class Test::Unit::TestCase #:nodoc:
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  
  fixtures :categories, :notes, :departments
end