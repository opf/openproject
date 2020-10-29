# frozen_string_literal: true

require 'helper'

class DestructionTodoList < ActiveRecord::Base
  has_many :destruction_todo_items, dependent: :destroy
  has_many :destruction_tada_items, dependent: :destroy
end

class DestructionTodoItem < ActiveRecord::Base
  belongs_to :destruction_todo_list
  acts_as_list scope: :destruction_todo_list
end

class DestructionTadaItem < ActiveRecord::Base
  belongs_to :destruction_todo_list
  acts_as_list scope: [:destruction_todo_list_id, :enabled]
end

class NoUpdateForScopeDestructionTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :destruction_todo_lists do |t|
    end

    ActiveRecord::Base.connection.create_table :destruction_todo_items do |t|
      t.column :position, :integer
      t.column :destruction_todo_list_id, :integer
    end

    ActiveRecord::Base.connection.create_table :destruction_tada_items do |t|
      t.column :position, :integer
      t.column :destruction_todo_list_id, :integer
      t.column :enabled, :boolean
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [DestructionTodoList, DestructionTodoItem, DestructionTadaItem].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end

  class NoUpdateForScopeDestructionTest < NoUpdateForScopeDestructionTestCase
    def setup
      super
      @list = DestructionTodoList.create!

      @todo_item_1 = DestructionTodoItem.create! position: 1, destruction_todo_list_id: @list.id
      @tada_item_1 = DestructionTadaItem.create! position: 1, destruction_todo_list_id: @list.id, enabled: true
    end

    def test_no_update_children_when_parent_destroyed
      DestructionTodoItem.any_instance.expects(:decrement_positions_on_lower_items).never
      DestructionTadaItem.any_instance.expects(:decrement_positions_on_lower_items).never
      assert @list.destroy
    end

    def test_update_children_when_sibling_destroyed
      @todo_item_1.expects(:decrement_positions_on_lower_items).once
      @tada_item_1.expects(:decrement_positions_on_lower_items).once
      assert @todo_item_1.destroy
      assert @tada_item_1.destroy
    end

  end
end
