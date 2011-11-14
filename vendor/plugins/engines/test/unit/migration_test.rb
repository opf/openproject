#-- encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'
require 'rails_generator'
require 'rails_generator/scripts/generate'

class MigrationsTest < Test::Unit::TestCase
  
  @@migration_dir = "#{RAILS_ROOT}/db/migrate"

  def setup
    ActiveRecord::Migration.verbose = false
    Engines.plugins[:test_migration].migrate(0)
  end
  
  def teardown
    FileUtils.rm_r(@@migration_dir) if File.exist?(@@migration_dir)
  end
  
  def test_engine_migrations_can_run_down
    assert !table_exists?('tests'), ActiveRecord::Base.connection.tables.inspect
    assert !table_exists?('others'), ActiveRecord::Base.connection.tables.inspect
    assert !table_exists?('extras'), ActiveRecord::Base.connection.tables.inspect
  end
    
  def test_engine_migrations_can_run_up
    Engines.plugins[:test_migration].migrate(3)
    assert table_exists?('tests')
    assert table_exists?('others')
    assert table_exists?('extras')
  end
  
  def test_engine_migrations_can_upgrade_incrementally
    Engines.plugins[:test_migration].migrate(1)
    assert table_exists?('tests')
    assert !table_exists?('others')
    assert !table_exists?('extras')
    assert_equal 1, Engines::Plugin::Migrator.current_version(Engines.plugins[:test_migration])
    
    
    Engines.plugins[:test_migration].migrate(2)
    assert table_exists?('others')
    assert_equal 2, Engines::Plugin::Migrator.current_version(Engines.plugins[:test_migration])
    
    
    Engines.plugins[:test_migration].migrate(3)
    assert table_exists?('extras')
    assert_equal 3, Engines::Plugin::Migrator.current_version(Engines.plugins[:test_migration])
  end
    
  def test_generator_creates_plugin_migration_file
    Rails::Generator::Scripts::Generate.new.run(['plugin_migration', 'test_migration'], :quiet => true)
    assert migration_file, "migration file is missing"
  end
  
  private
  
  def table_exists?(table)
    ActiveRecord::Base.connection.tables.include?(table)
  end
  
  def migration_file
    Dir["#{@@migration_dir}/*test_migration_to_version_3.rb"][0]
  end
end