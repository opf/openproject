require 'helper'

class Animal < ActiveRecord::Base
  acts_as_list
  default_scope -> { select(:name) }
end

class DefaultScopeWithSelectTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :animals do |t|
      t.column :position, :integer
      t.column :name, :string
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    Animal.reset_column_information
    super
  end

  def teardown
    teardown_db
    super
  end

  def test_default_scope_with_select
    animal1 = Animal.create name: 'Fox'
    animal2 = Animal.create name: 'Panda'
    animal3 = Animal.create name: 'Wildebeast'
    assert_equal 1, animal1.position
    assert_equal 2, animal2.position
    assert_equal 3, animal3.position
  end
end
