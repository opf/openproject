require 'helper'

class Checklist < ActiveRecord::Base
  has_many :checklist_items, foreign_key: 'list_id', inverse_of: :checklist
end

class ChecklistItem < ActiveRecord::Base
  belongs_to :checklist, foreign_key: 'list_id', inverse_of: :checklist_items
  acts_as_list scope: :checklist
end

class ScopeWithUserDefinedForeignKeyTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :checklists do |t|
    end

    ActiveRecord::Base.connection.create_table :checklist_items do |t|
      t.column :list_id, :integer
      t.column :position, :integer
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [Checklist, ChecklistItem].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end

  def test_scope_with_user_defined_foreign_key
    checklist = Checklist.create
    checklist_item_1 = checklist.checklist_items.create
    checklist_item_2 = checklist.checklist_items.create
    checklist_item_3 = checklist.checklist_items.create

    assert_equal 1, checklist_item_1.position
    assert_equal 2, checklist_item_2.position
    assert_equal 3, checklist_item_3.position
  end
end
