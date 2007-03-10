require File.join(File.dirname(__FILE__), 'abstract_unit')

if ActiveRecord::Base.connection.supports_migrations? 
  class Thing < ActiveRecord::Base
    attr_accessor :version
    acts_as_versioned
  end

  class MigrationTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false
    def teardown
      ActiveRecord::Base.connection.initialize_schema_information
      ActiveRecord::Base.connection.update "UPDATE schema_info SET version = 0"

      Thing.connection.drop_table "things" rescue nil
      Thing.connection.drop_table "thing_versions" rescue nil
      Thing.reset_column_information
    end
        
    def test_versioned_migration
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
      # take 'er up
      ActiveRecord::Migrator.up(File.dirname(__FILE__) + '/fixtures/migrations/')
      t = Thing.create :title => 'blah blah'
      assert_equal 1, t.versions.size

      # now lets take 'er back down
      ActiveRecord::Migrator.down(File.dirname(__FILE__) + '/fixtures/migrations/')
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
    end
  end
end
