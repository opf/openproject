# frozen_string_literal: true

require 'helper'

class MasterItem < ActiveRecord::Base
  acts_as_list
end

class SlaveItem < MasterItem; end

class NoUpdateForSubclassesTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :master_items do |t|
      t.column :position, :integer
      t.column :type, :string
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [MasterItem, SlaveItem].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end
end

class NoUpdateForSubclassesTest < NoUpdateForSubclassesTestCase
  def setup
    super
    @item_1, @item_2 = (1..2).map do |counter|
      SlaveItem.create!(position: counter)
    end
  end

  def test_update
    @item_1.update position: 2
    assert_equal 2, @item_1.reload.position
    assert_equal 1, @item_2.reload.position
  end

  def test_no_update_for_subclass_instances_with_no_update_on_superclass
    MasterItem.acts_as_list_no_update { @item_1.update position: 2 }

    assert_equal 2, @item_1.reload.position
    assert_equal 2, @item_2.reload.position
  end

  def test_no_update_for_subclass_instances_with_no_update_on_subclass
    SlaveItem.acts_as_list_no_update { @item_1.update position: 2 }

    assert_equal 2, @item_1.reload.position
    assert_equal 2, @item_2.reload.position
  end
end
