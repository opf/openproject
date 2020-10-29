# frozen_string_literal: true

require 'helper'

class TodoList < ActiveRecord::Base
  has_many :todo_items
  acts_as_list
end

class TodoItem < ActiveRecord::Base
  belongs_to :todo_list
  has_many :todo_item_attachments
  acts_as_list scope: :todo_list
end

class TodoItemAttachment < ActiveRecord::Base
  belongs_to :todo_item
  acts_as_list scope: :todo_item
end

class NoUpdateForCollectionClassesTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :todo_lists do |t|
      t.column :position, :integer
    end

    ActiveRecord::Base.connection.create_table :todo_items do |t|
      t.column :position, :integer
      t.column :todo_list_id, :integer
    end

    ActiveRecord::Base.connection.create_table :todo_item_attachments do |t|
      t.column :position, :integer
      t.column :todo_item_id, :integer
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [TodoList, TodoItem, TodoItemAttachment].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end
end

class NoUpdateForCollectionClassesTest < NoUpdateForCollectionClassesTestCase
  def setup
    super
    @list_1, @list_2 = (1..2).map { |counter| TodoList.create!(position: counter) }

    @item_1, @item_2 = (1..2).map { |counter| TodoItem.create!(position: counter, todo_list_id: @list_1.id) }
    @attachment_1, @attachment_2 = (1..2).map { |counter| TodoItemAttachment.create!(position: counter, todo_item_id: @item_1.id) }
    @attachment_3, @attachment_4 = (1..2).map {|counter| TodoItemAttachment.create!(position: counter, todo_item_id: @item_2.id)}
  end

  def test_update
    @item_1.update position: 2
    assert_equal 2, @item_1.reload.position
    assert_equal 1, @item_2.reload.position
  end

  def test_no_update_for_single_class_instances
    TodoItem.acts_as_list_no_update { @item_1.update position: 2 }

    assert_equal 2, @item_1.reload.position
    assert_equal 2, @item_2.reload.position
  end

  def test_no_update_for_different_class_instances
    TodoItem.acts_as_list_no_update([TodoItemAttachment]) { update_records! }

    assert_equal 2, @item_1.reload.position
    assert_equal 2, @item_2.reload.position

    assert_equal 2, @attachment_1.reload.position
    assert_equal 2, @attachment_2.reload.position

    assert_equal 2, @list_1.reload.position
    assert_equal 1, @list_2.reload.position
  end

  def test_no_update_for_nested_blocks
    new_list = @list_1.dup
    new_list.save!

    TodoItem.acts_as_list_no_update do
      @list_1.todo_items.reverse.each do |item|
        new_item = item.dup
        new_list.todo_items << new_item
        new_item.save!

        assert_equal new_item.position, item.reload.position

        TodoItemAttachment.acts_as_list_no_update do
          item.todo_item_attachments.reverse.each do |attach|
            new_attach = attach.dup
            new_item.todo_item_attachments << new_attach
            new_attach.save!
            assert_equal new_attach.position, attach.reload.position
          end
        end
      end
    end
  end

  def test_raising_array_type_error
    exception = assert_raises ActiveRecord::Acts::List::NoUpdate::ArrayTypeError do
      TodoList.acts_as_list_no_update(nil)
    end

    assert_equal("The first argument must be an array", exception.message )
  end

  def test_non_disparity_classes_error
    exception = assert_raises ActiveRecord::Acts::List::NoUpdate::DisparityClassesError do
      TodoList.acts_as_list_no_update([Class])
    end

    assert_equal("The first argument should contain ActiveRecord or ApplicationRecord classes", exception.message )
  end

  private

  def update_records!
    @item_1.update position: 2
    @attachment_1.update position: 2
    @list_1.update position: 2
  end
end
