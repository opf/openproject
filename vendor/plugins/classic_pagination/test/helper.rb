require 'test/unit'

unless defined?(ActiveRecord)
  plugin_root = File.join(File.dirname(__FILE__), '..')

  # first look for a symlink to a copy of the framework
  if framework_root = ["#{plugin_root}/rails", "#{plugin_root}/../../rails"].find { |p| File.directory? p }
    puts "found framework root: #{framework_root}"
    # this allows for a plugin to be tested outside an app
    $:.unshift "#{framework_root}/activesupport/lib", "#{framework_root}/activerecord/lib", "#{framework_root}/actionpack/lib"
  else
    # is the plugin installed in an application?
    app_root = plugin_root + '/../../..'

    if File.directory? app_root + '/config'
      puts 'using config/boot.rb'
      ENV['RAILS_ENV'] = 'test'
      require File.expand_path(app_root + '/config/boot')
    else
      # simply use installed gems if available
      puts 'using rubygems'
      require 'rubygems'
      gem 'actionpack'; gem 'activerecord'
    end
  end

  %w(action_pack active_record action_controller active_record/fixtures action_controller/test_process).each {|f| require f}

  Dependencies.load_paths.unshift "#{plugin_root}/lib"
end

# Define the connector
class ActiveRecordTestConnector
  cattr_accessor :able_to_connect
  cattr_accessor :connected

  # Set our defaults
  self.connected = false
  self.able_to_connect = true

  class << self
    def setup
      unless self.connected || !self.able_to_connect
        setup_connection
        load_schema
        require_fixture_models
        self.connected = true
      end
    rescue Exception => e  # errors from ActiveRecord setup
      $stderr.puts "\nSkipping ActiveRecord assertion tests: #{e}"
      #$stderr.puts "  #{e.backtrace.join("\n  ")}\n"
      self.able_to_connect = false
    end

    private

    def setup_connection
      if Object.const_defined?(:ActiveRecord)
        defaults = { :database => ':memory:' }
        begin
          options = defaults.merge :adapter => 'sqlite3', :timeout => 500
          ActiveRecord::Base.establish_connection(options)
          ActiveRecord::Base.configurations = { 'sqlite3_ar_integration' => options }
          ActiveRecord::Base.connection
        rescue Exception  # errors from establishing a connection
          $stderr.puts 'SQLite 3 unavailable; trying SQLite 2.'
          options = defaults.merge :adapter => 'sqlite'
          ActiveRecord::Base.establish_connection(options)
          ActiveRecord::Base.configurations = { 'sqlite2_ar_integration' => options }
          ActiveRecord::Base.connection
        end

        Object.send(:const_set, :QUOTED_TYPE, ActiveRecord::Base.connection.quote_column_name('type')) unless Object.const_defined?(:QUOTED_TYPE)
      else
        raise "Can't setup connection since ActiveRecord isn't loaded."
      end
    end

    # Load actionpack sqlite tables
    def load_schema
      File.read(File.dirname(__FILE__) + "/fixtures/schema.sql").split(';').each do |sql|
        ActiveRecord::Base.connection.execute(sql) unless sql.blank?
      end
    end

    def require_fixture_models
      Dir.glob(File.dirname(__FILE__) + "/fixtures/*.rb").each {|f| require f}
    end
  end
end

# Test case for inheritance
class ActiveRecordTestCase < Test::Unit::TestCase
  # Set our fixture path
  if ActiveRecordTestConnector.able_to_connect
    self.fixture_path = "#{File.dirname(__FILE__)}/fixtures/"
    self.use_transactional_fixtures = false
  end

  def self.fixtures(*args)
    super if ActiveRecordTestConnector.connected
  end

  def run(*args)
    super if ActiveRecordTestConnector.connected
  end

  # Default so Test::Unit::TestCase doesn't complain
  def test_truth
  end
end

ActiveRecordTestConnector.setup
ActionController::Routing::Routes.reload rescue nil
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end
