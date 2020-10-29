# frozen_string_literal: true

# NOTE: following now done in helper.rb (better Readability)
require 'helper'

def setup_db(position_options = {})
  $default_position = position_options[:default]

  # sqlite cannot drop/rename/alter columns and add constraints after table creation
  sqlite = ENV.fetch("DB", "sqlite") == "sqlite"

  # AR caches columns options like defaults etc. Clear them!
  ActiveRecord::Base.connection.create_table :mixins do |t|
    t.column :pos, :integer, position_options unless position_options[:positive] && sqlite
    t.column :active, :boolean, default: true
    t.column :parent_id, :integer
    t.column :parent_type, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
    t.column :state, :integer
  end

  if position_options[:unique] && !(sqlite && position_options[:positive])
    ActiveRecord::Base.connection.add_index :mixins, :pos, unique: true
  end

  if position_options[:positive]
    if sqlite
      # SQLite cannot add constraint after table creation, also cannot add unique inside ADD COLUMN
      ActiveRecord::Base.connection.execute('ALTER TABLE mixins ADD COLUMN pos integer8 NOT NULL CHECK (pos > 0) DEFAULT 1')
      ActiveRecord::Base.connection.execute('CREATE UNIQUE INDEX index_mixins_on_pos ON mixins(pos)')
    else
      ActiveRecord::Base.connection.execute('ALTER TABLE mixins ADD CONSTRAINT pos_check CHECK (pos > 0)')
    end
  end

  # This table is used to test table names and column names quoting
  ActiveRecord::Base.connection.create_table 'table-name' do |t|
    t.column :order, :integer
  end

  # This table is used to test table names with different primary_key columns
  ActiveRecord::Base.connection.create_table 'altid-table', primary_key: 'altid' do |t|
    t.column :pos, :integer
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  ActiveRecord::Base.connection.add_index 'altid-table', :pos, unique: true

  mixins = [ Mixin, ListMixin, ListMixinSub1, ListMixinSub2, ListWithStringScopeMixin,
    ArrayScopeListMixin, ZeroBasedMixin, DefaultScopedMixin, EnumArrayScopeListMixin,
    DefaultScopedWhereMixin, TopAdditionMixin, NoAdditionMixin, QuotedList, TouchDisabledMixin ]

  ActiveRecord::Base.connection.schema_cache.clear!
  mixins.each do |klass|
    klass.reset_column_information
  end
end

def setup_db_with_default
  setup_db default: 0
end

class Mixin < ActiveRecord::Base
  self.table_name = 'mixins'
end

class ListMixin < Mixin
  acts_as_list column: "pos", scope: :parent
end

class TouchDisabledMixin < Mixin
  acts_as_list column: "pos", touch_on_update: false
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
  validates :pos, presence: true
end

class ListMixinError < ListMixin
  validates :state, presence: true
end

class ListWithStringScopeMixin < Mixin
  acts_as_list column: "pos", scope: 'parent_id = #{parent_id}'
end

class ArrayScopeListMixin < Mixin
  acts_as_list column: "pos", scope: [:parent_id, :parent_type]
end

class ArrayScopeListWithHashMixin < Mixin
  acts_as_list column: "pos", scope: [:parent_id, state: nil]
end

class EnumArrayScopeListMixin < Mixin
  STATE_VALUES = %w(active archived)
  enum state: STATE_VALUES

  acts_as_list column: "pos", scope: [:parent_id, :state]
end

class ZeroBasedMixin < Mixin
  acts_as_list column: "pos", top_of_list: 0, scope: [:parent_id]
end

class DefaultScopedMixin < Mixin
  acts_as_list column: "pos"
  default_scope { order('pos ASC') }
end

class DefaultScopedWhereMixin < Mixin
  acts_as_list column: "pos"
  default_scope { order('pos ASC').where(active: true) }

  def self.for_active_false_tests
    unscope(:where).where(active: false)
  end
end

class SequentialUpdatesDefault < Mixin
  acts_as_list column: "pos"
end

class SequentialUpdatesAltId < ActiveRecord::Base
  self.table_name = "altid-table"
  self.primary_key = "altid"

  acts_as_list column: "pos"
end

class SequentialUpdatesAltIdTouchDisabled < SequentialUpdatesAltId
  acts_as_list column: "pos", touch_on_update: false
end

class SequentialUpdatesFalseMixin < Mixin
  acts_as_list column: "pos", sequential_updates: false
end

class TopAdditionMixin < Mixin
  acts_as_list column: "pos", add_new_at: :top, scope: :parent_id
end

class NoAdditionMixin < Mixin
  acts_as_list column: "pos", add_new_at: nil, scope: :parent_id
end

##
# The way we track changes to
# scope and position can get tripped up
# by someone using update within
# a callback because it causes multiple passes
# through the callback chain
module CallbackMixin

  def self.included(base)
    base.send :include, InstanceMethods
    base.after_create :change_field
  end

  module InstanceMethods
    def change_field
      # doesn't matter what column changes, just
      # need to change something

      self.update active: !self.active
    end
  end
end

class TheAbstractClass < ActiveRecord::Base
  self.abstract_class = true
  self.table_name = 'mixins'
end

class TheAbstractSubclass < TheAbstractClass
  acts_as_list column: "pos", scope: :parent
end

class TheBaseClass < ActiveRecord::Base
  self.table_name = 'mixins'
  acts_as_list column: "pos", scope: :parent
end

class TheBaseSubclass < TheBaseClass
end

class QuotedList < ActiveRecord::Base
  self.table_name = 'table-name'
  acts_as_list column: :order
end

class ActsAsListTestCase < Minitest::Test
  # No default test required as this class is abstract.
  # Need for test/unit.
  undef_method :default_test if method_defined?(:default_test)

  def teardown
    teardown_db
  end
end

class ZeroBasedTest < ActsAsListTestCase
  include Shared::ZeroBased

  def setup
    setup_db
    super
  end
end

class ZeroBasedTestWithDefault < ActsAsListTestCase
  include Shared::ZeroBased

  def setup
    setup_db_with_default
    super
  end
end

class ListTest < ActsAsListTestCase
  include Shared::List

  def setup
    setup_db
    super
  end

  def test_insert_race_condition
    # the bigger n is the more likely we will have a race condition
    n = 1000
    (1..n).each do |counter|
      node = ListMixin.new parent_id: 1
      node.pos = counter
      node.save!
    end

    wait_for_it  = true
    threads = []
    4.times do |i|
      threads << Thread.new do
        true while wait_for_it
        ActiveRecord::Base.connection_pool.with_connection do |c|
          n.times do
            begin
              ListMixin.where(parent_id: 1).order('pos').last.insert_at(1)
            rescue Exception
              # ignore SQLite3::SQLException due to table locking
            end
          end
        end
      end
    end
    wait_for_it = false
    threads.each(&:join)

    assert_equal((1..n).to_a, ListMixin.where(parent_id: 1).order('pos').map(&:pos))
  end
end

class ListWithCallbackTest < ActsAsListTestCase

  include Shared::List

  def setup
    ListMixin.send(:include, CallbackMixin)
    setup_db
    super
  end

end

class ListTestWithDefault < ActsAsListTestCase
  include Shared::List

  def setup
    setup_db_with_default
    super
  end
end

class ListSubTest < ActsAsListTestCase
  include Shared::ListSub

  def setup
    setup_db
    super
  end
end

class ListSubTestWithDefault < ActsAsListTestCase
  include Shared::ListSub

  def setup
    setup_db_with_default
    super
  end
end

class ArrayScopeListTest < ActsAsListTestCase
  include Shared::ArrayScopeList

  def setup
    setup_db
    super
  end
end

class ArrayScopeListTestWithDefault < ActsAsListTestCase
  include Shared::ArrayScopeList

  def setup
    setup_db_with_default
    super
  end
end

class QuotingTestList < ActsAsListTestCase
  include Shared::Quoting

  def setup
    setup_db_with_default
    super
  end
end

class DefaultScopedTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| DefaultScopedMixin.create!({pos: counter}) }
  end

  def test_insert
    new = DefaultScopedMixin.create
    assert_equal 5, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedMixin.create
    assert_equal 6, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedMixin.acts_as_list_no_update { DefaultScopedMixin.create }
    assert_equal_or_nil $default_position, new.pos
    assert_equal $default_position.is_a?(Integer), new.first?
    assert !new.last?

    new = DefaultScopedMixin.create
    assert_equal 7, new.pos
    assert !new.first?
    assert new.last?
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 2).first.move_lower
    assert_equal [1, 3, 2, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 2).first.move_higher
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 1).first.move_to_bottom
    assert_equal [2, 3, 4, 1], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 1).first.move_to_top
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 2).first.move_to_bottom
    assert_equal [1, 3, 4, 2], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 4).first.move_to_top
    assert_equal [4, 1, 3, 2], DefaultScopedMixin.all.map(&:id)
  end

  def test_insert_at
    new = DefaultScopedMixin.create
    assert_equal 5, new.pos

    new = DefaultScopedMixin.create
    assert_equal 6, new.pos

    new_noup = DefaultScopedMixin.acts_as_list_no_update { DefaultScopedMixin.create }
    assert_equal_or_nil $default_position, new_noup.pos

    new = DefaultScopedMixin.create
    assert_equal 7, new.pos

    new4 = DefaultScopedMixin.create
    assert_equal 8, new4.pos

    new4.insert_at(2)
    assert_equal 2, new4.pos

    new.reload
    assert_equal 8, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 3, new4.pos

    new5 = DefaultScopedMixin.create
    assert_equal 9, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 4, new4.pos

    new_noup.reload
    assert_equal_or_nil $default_position, new_noup.pos
  end

  def test_update_position
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 2).first.set_list_position(4)
    assert_equal [1, 3, 4, 2], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 2).first.set_list_position(2)
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 1).first.set_list_position(4)
    assert_equal [2, 3, 4, 1], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 1).first.set_list_position(1)
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)
  end
end

class DefaultScopedWhereTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| DefaultScopedWhereMixin.create! pos: counter, active: false }
  end

  def test_insert
    new = DefaultScopedWhereMixin.create
    assert_equal 5, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedWhereMixin.create
    assert_equal 6, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedWhereMixin.acts_as_list_no_update { DefaultScopedWhereMixin.create }
    assert_equal_or_nil $default_position, new.pos
    assert_equal $default_position.is_a?(Integer), new.first?
    assert !new.last?

    new = DefaultScopedWhereMixin.create
    assert_equal 7, new.pos
    assert !new.first?
    assert new.last?
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.move_lower
    assert_equal [1, 3, 2, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.move_higher
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.move_to_bottom
    assert_equal [2, 3, 4, 1], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.move_to_top
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.move_to_bottom
    assert_equal [1, 3, 4, 2], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 4).first.move_to_top
    assert_equal [4, 1, 3, 2], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
  end

  def test_insert_at
    new = DefaultScopedWhereMixin.create
    assert_equal 5, new.pos

    new = DefaultScopedWhereMixin.create
    assert_equal 6, new.pos

    new = DefaultScopedWhereMixin.create
    assert_equal 7, new.pos

    new_noup = DefaultScopedWhereMixin.acts_as_list_no_update { DefaultScopedWhereMixin.create }
    assert_equal_or_nil $default_position, new_noup.pos

    new4 = DefaultScopedWhereMixin.create
    assert_equal 8, new4.pos

    new4.insert_at(2)
    assert_equal 2, new4.pos

    new.reload
    assert_equal 8, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 3, new4.pos

    new5 = DefaultScopedWhereMixin.create
    assert_equal 9, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 4, new4.pos

    new_noup.reload
    assert_equal_or_nil $default_position, new_noup.pos
  end

  def test_update_position
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.set_list_position(4)
    assert_equal [1, 3, 4, 2], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.set_list_position(2)
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.set_list_position(4)
    assert_equal [2, 3, 4, 1], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.set_list_position(1)
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
  end

end

class MultiDestroyTest < ActsAsListTestCase

  def setup
    setup_db
  end

  # example:
  #
  #   class TodoList < ActiveRecord::Base
  #     has_many :todo_items, order: "position"
  #     accepts_nested_attributes_for :todo_items, allow_destroy: true
  #   end
  #
  #   class TodoItem < ActiveRecord::Base
  #     belongs_to :todo_list
  #     acts_as_list scope: :todo_list
  #   end
  #
  # Assume that there are three items.
  # The user mark two items as deleted, click save button, form will be post:
  #
  # todo_list.todo_items_attributes = [
  #   {id: 1, _destroy: true},
  #   {id: 2, _destroy: true}
  # ]
  #
  # Save toto_list, the position of item #3 should eql 1.
  #
  def test_destroy
    new1 = DefaultScopedMixin.create
    assert_equal 1, new1.pos

    new2 = DefaultScopedMixin.create
    assert_equal 2, new2.pos

    new3 = DefaultScopedMixin.create
    assert_equal 3, new3.pos

    new4 = DefaultScopedMixin.create
    assert_equal 4, new4.pos

    new1.destroy
    new2.destroy
    new3.reload
    new4.reload
    assert_equal 1, new3.pos
    assert_equal 2, new4.pos

    DefaultScopedMixin.acts_as_list_no_update { new3.destroy }

    new4.reload
    assert_equal 2, new4.pos
  end
end

#class TopAdditionMixin < Mixin

class TopAdditionTest < ActsAsListTestCase
  include Shared::TopAddition

  def setup
    setup_db
    super
  end
end

class TopAdditionTestWithDefault < ActsAsListTestCase
  include Shared::TopAddition

  def setup
    setup_db_with_default
    super
  end
end

class NoAdditionTest < ActsAsListTestCase
  include Shared::NoAddition

  def setup
    setup_db
    super
  end
end

class MultipleListsTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 1}
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 2}
  end

  def test_check_scope_order
    assert_equal [1, 2, 3, 4], ListMixin.where(:parent_id => 1).order('pos').map(&:id)
    assert_equal [5, 6, 7, 8], ListMixin.where(:parent_id => 2).order('pos').map(&:id)
    ListMixin.find(4).update :parent_id => 2, :pos => 2
    assert_equal [1, 2, 3], ListMixin.where(:parent_id => 1).order('pos').map(&:id)
    assert_equal [5, 4, 6, 7, 8], ListMixin.where(:parent_id => 2).order('pos').map(&:id)
  end

  def test_check_scope_position
    assert_equal [1, 2, 3, 4], ListMixin.where(:parent_id => 1).map(&:pos)
    assert_equal [1, 2, 3, 4], ListMixin.where(:parent_id => 2).map(&:pos)
    ListMixin.find(4).update :parent_id => 2, :pos => 2
    assert_equal [1, 2, 3], ListMixin.where(:parent_id => 1).order('pos').map(&:pos)
    assert_equal [1, 2, 3, 4, 5], ListMixin.where(:parent_id => 2).order('pos').map(&:pos)
  end
end

class EnumArrayScopeListMixinTest < ActsAsListTestCase
  def setup
    setup_db
    EnumArrayScopeListMixin.create! :parent_id => 1, :state => EnumArrayScopeListMixin.states['active']
    EnumArrayScopeListMixin.create! :parent_id => 1, :state => EnumArrayScopeListMixin.states['archived']
    EnumArrayScopeListMixin.create! :parent_id => 2, :state => EnumArrayScopeListMixin.states["active"]
    EnumArrayScopeListMixin.create! :parent_id => 2, :state => EnumArrayScopeListMixin.states["archived"]
  end

  def test_positions
    assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 1, :state => EnumArrayScopeListMixin.states['active']).map(&:pos)
    assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 1, :state => EnumArrayScopeListMixin.states['archived']).map(&:pos)
    assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 2, :state => EnumArrayScopeListMixin.states['active']).map(&:pos)
    assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 2, :state => EnumArrayScopeListMixin.states['archived']).map(&:pos)
  end

  def test_update_state
    active_item = EnumArrayScopeListMixin.find_by(:parent_id => 2, :state => EnumArrayScopeListMixin.states['active'])
    active_item.update(state: EnumArrayScopeListMixin.states['archived'])
    assert_equal [1, 2], EnumArrayScopeListMixin.where(:parent_id => 2, :state => EnumArrayScopeListMixin.states['archived']).map(&:pos).sort
  end
end

class MultipleListsArrayScopeTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter,:parent_id => 1, :parent_type => 'anything'}
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter,:parent_id => 2, :parent_type => 'something'}
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter,:parent_id => 3, :parent_type => 'anything'}
  end

  def test_order_after_all_scope_properties_are_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order('pos').map(&:id)
    assert_equal [5, 6, 7, 8], ArrayScopeListMixin.where(:parent_id => 2, :parent_type => 'something').order('pos').map(&:id)
    ArrayScopeListMixin.find(2).update :parent_id => 2, :pos => 2,:parent_type => 'something'
    assert_equal [1, 3, 4], ArrayScopeListMixin.where(:parent_id => 1,:parent_type => 'anything').order('pos').map(&:id)
    assert_equal [5, 2, 6, 7, 8], ArrayScopeListMixin.where(:parent_id => 2,:parent_type => 'something').order('pos').map(&:id)
  end

  def test_position_after_all_scope_properties_are_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').map(&:pos)
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 2, :parent_type => 'something').map(&:pos)
    ArrayScopeListMixin.find(4).update :parent_id => 2, :pos => 2, :parent_type => 'something'
    assert_equal [1, 2, 3], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order('pos').map(&:pos)
    assert_equal [1, 2, 3, 4, 5], ArrayScopeListMixin.where(:parent_id => 2, :parent_type => 'something').order('pos').map(&:pos)
  end

  def test_order_after_one_scope_property_is_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order('pos').map(&:id)
    assert_equal [9, 10, 11, 12], ArrayScopeListMixin.where(:parent_id => 3, :parent_type => 'anything').order('pos').map(&:id)
    ArrayScopeListMixin.find(2).update :parent_id => 3, :pos => 2
    assert_equal [1, 3, 4], ArrayScopeListMixin.where(:parent_id => 1,:parent_type => 'anything').order('pos').map(&:id)
    assert_equal [9, 2, 10, 11, 12], ArrayScopeListMixin.where(:parent_id => 3,:parent_type => 'anything').order('pos').map(&:id)
  end

  def test_position_after_one_scope_property_is_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').map(&:pos)
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 3, :parent_type => 'anything').map(&:pos)
    ArrayScopeListMixin.find(4).update :parent_id => 3, :pos => 2
    assert_equal [1, 2, 3], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order('pos').map(&:pos)
    assert_equal [1, 2, 3, 4, 5], ArrayScopeListMixin.where(:parent_id => 3, :parent_type => 'anything').order('pos').map(&:pos)
  end

  def test_order_after_moving_to_empty_list
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order('pos').map(&:id)
    assert_equal [], ArrayScopeListMixin.where(:parent_id => 4, :parent_type => 'anything').order('pos').map(&:id)
    ArrayScopeListMixin.find(2).update :parent_id => 4, :pos => 1
    assert_equal [1, 3, 4], ArrayScopeListMixin.where(:parent_id => 1,:parent_type => 'anything').order('pos').map(&:id)
    assert_equal [2], ArrayScopeListMixin.where(:parent_id => 4,:parent_type => 'anything').order('pos').map(&:id)
  end

  def test_position_after_moving_to_empty_list
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').map(&:pos)
    assert_equal [], ArrayScopeListMixin.where(:parent_id => 4, :parent_type => 'anything').map(&:pos)
    ArrayScopeListMixin.find(2).update :parent_id => 4, :pos => 1
    assert_equal [1, 2, 3], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order('pos').map(&:pos)
    assert_equal [1], ArrayScopeListMixin.where(:parent_id => 4, :parent_type => 'anything').order('pos').map(&:pos)
  end
end

class ArrayScopeListWithHashTest
  def setup
    setup_db
    @obj1 = ArrayScopeListWithHashMixin.create! :pos => counter, :parent_id => 1, :state => nil
    @obj2 = ArrayScopeListWithHashMixin.create! :pos => counter, :parent_id => 1, :state => 'anything'
  end

  def test_scope_condition_correct
    [@obj1, @obj2].each do |obj|
      assert_equal({ :parent_id => 1, :state => nil }, obj.scope_condition)
    end
  end
end

require 'timecop'

class TouchTest < ActsAsListTestCase
  def setup
    setup_db
    Timecop.freeze(yesterday) do
      4.times { ListMixin.create! }
    end
  end

  def now
    @now ||= Time.current.change(usec: 0)
  end

  def yesterday
    @yesterday ||= 1.day.ago
  end

  def updated_ats
    ListMixin.order(:id).pluck(:updated_at)
  end

  def test_moving_item_lower_touches_self_and_lower_item
    Timecop.freeze(now) do
      ListMixin.first.move_lower
      updated_ats[0..1].each do |updated_at|
        assert_equal updated_at.to_i, now.to_i
      end
      updated_ats[2..3].each do |updated_at|
        assert_equal updated_at.to_i, yesterday.to_i
      end
    end
  end

  def test_moving_item_higher_touches_self_and_higher_item
    Timecop.freeze(now) do
      ListMixin.all.second.move_higher
      updated_ats[0..1].each do |updated_at|
        assert_equal updated_at.to_i, now.to_i
      end
      updated_ats[2..3].each do |updated_at|
        assert_equal updated_at.to_i, yesterday.to_i
      end
    end
  end

  def test_moving_item_to_bottom_touches_all_other_items
    Timecop.freeze(now) do
      ListMixin.first.move_to_bottom
      updated_ats.each do |updated_at|
        assert_equal updated_at.to_i, now.to_i
      end
    end
  end

  def test_moving_item_to_top_touches_all_other_items
    Timecop.freeze(now) do
      ListMixin.last.move_to_top
      updated_ats.each do |updated_at|
        assert_equal updated_at.to_i, now.to_i
      end
    end
  end

  def test_removing_item_touches_all_lower_items
    Timecop.freeze(now) do
      ListMixin.all.third.remove_from_list
      updated_ats[0..1].each do |updated_at|
        assert_equal updated_at.to_i, yesterday.to_i
      end
      updated_ats[2..2].each do |updated_at|
        assert_equal updated_at.to_i, now.to_i
      end
    end
  end
end

class TouchDisabledTest < ActsAsListTestCase
  def setup
    setup_db
    Timecop.freeze(yesterday) do
      4.times { TouchDisabledMixin.create! }
    end
  end

  def now
    @now ||= Time.current.change(usec: 0)
  end

  def yesterday
    @yesterday ||= 1.day.ago
  end

  def updated_ats
    TouchDisabledMixin.order(:id).pluck(:updated_at)
  end

  def positions
    ListMixin.order(:id).pluck(:pos)
  end

  def test_deleting_item_does_not_touch_higher_items
    Timecop.freeze(now) do
      TouchDisabledMixin.first.destroy
      updated_ats.each do |updated_at|
        assert_equal updated_at.to_i, yesterday.to_i
      end
      assert_equal positions, [1, 2, 3]
    end
  end
end

class ActsAsListTopTest < ActsAsListTestCase
  def setup
    setup_db
  end

  def test_acts_as_list_top
    assert_equal 1, TheBaseSubclass.new.acts_as_list_top
    assert_equal 0, ZeroBasedMixin.new.acts_as_list_top
  end

  def test_class_acts_as_list_top
    assert_equal 1, TheBaseSubclass.acts_as_list_top
    assert_equal 0, ZeroBasedMixin.acts_as_list_top
  end
end

class NilPositionTest < ActsAsListTestCase
  def setup
    setup_db
  end

  def test_nil_position_ordering
    new1 = DefaultScopedMixin.create pos: nil
    new2 = DefaultScopedMixin.create pos: nil
    new3 = DefaultScopedMixin.create pos: nil
    DefaultScopedMixin.update_all(pos: nil)

    assert_equal [nil, nil, nil], DefaultScopedMixin.all.map(&:pos)

    new1.reload.pos = 1
    new1.save

    new3.reload.pos = 1
    new3.save

    assert_equal [1, 2], DefaultScopedMixin.where("pos IS NOT NULL").map(&:pos)
    assert_equal [3, 1], DefaultScopedMixin.where("pos IS NOT NULL").map(&:id)
    assert_nil new2.reload.pos

    new2.reload.pos = 1
    new2.save

    assert_equal [1, 2, 3], DefaultScopedMixin.all.map(&:pos)
    assert_equal [2, 3, 1], DefaultScopedMixin.all.map(&:id)
  end
end

class SequentialUpdatesOptionDefaultTest < ActsAsListTestCase
  def setup
    setup_db
  end

  def test_sequential_updates_default_to_false_without_unique_index
    assert_equal false, SequentialUpdatesDefault.new.send(:sequential_updates?)
  end
end

class SequentialUpdatesMixinNotNullUniquePositiveConstraintsTest < ActsAsListTestCase
  def setup
    setup_db null: false, unique: true, positive: true
    (1..4).each { |counter| SequentialUpdatesDefault.create!({pos: counter}) }
  end

  def test_sequential_updates_default_to_true_with_unique_index
    assert_equal true, SequentialUpdatesDefault.new.send(:sequential_updates?)
  end

  def test_sequential_updates_option_override_with_false
    assert_equal false, SequentialUpdatesFalseMixin.new.send(:sequential_updates?)
  end

  def test_insert_at
    new = SequentialUpdatesDefault.create
    assert_equal 5, new.pos

    new.insert_at(1)
    assert_equal 1, new.pos

    new.insert_at(5)
    assert_equal 5, new.pos

    new.insert_at(3)
    assert_equal 3, new.pos
  end

  def test_move_to_bottom
    item = SequentialUpdatesDefault.order(:pos).first
    item.move_to_bottom
    assert_equal 4, item.pos
  end

  def test_move_to_top
    new_item = SequentialUpdatesDefault.create!
    assert_equal 5, new_item.pos

    new_item.move_to_top
    assert_equal 1, new_item.pos
  end

  def test_destroy
    new_item = SequentialUpdatesDefault.create
    assert_equal 5, new_item.pos

    new_item.insert_at(2)
    assert_equal 2, new_item.pos

    new_item.destroy
    assert_equal [1,2,3,4], SequentialUpdatesDefault.all.map(&:pos).sort

  end

  def test_exception_on_wrong_position
    new_item = SequentialUpdatesDefault.create

    assert_raises ArgumentError do
      new_item.insert_at(0)
    end
  end


  class SequentialUpdatesMixinNotNullUniquePositiveConstraintsTest < ActsAsListTestCase
    def setup
      setup_db null: false, unique: true, positive: true
      (1..4).each { |counter| SequentialUpdatesAltId.create!({pos: counter}) }
    end

    def test_sequential_updates_default_to_true_with_unique_index
      assert_equal true, SequentialUpdatesAltId.new.send(:sequential_updates?)
    end

    def test_insert_at
      new = SequentialUpdatesAltId.create
      assert_equal 5, new.pos

      new.insert_at(1)
      assert_equal 1, new.pos

      new.insert_at(5)
      assert_equal 5, new.pos

      new.insert_at(3)
      assert_equal 3, new.pos
    end

    def test_create_at_top
      new = SequentialUpdatesAltId.create!(pos: 1)
      assert_equal 1, new.pos
    end

    def test_move_to_bottom
      item = SequentialUpdatesAltId.order(:pos).first
      item.move_to_bottom
      assert_equal 4, item.pos
    end

    def test_move_to_top
      new_item = SequentialUpdatesAltId.create!
      assert_equal 5, new_item.pos

      new_item.move_to_top
      assert_equal 1, new_item.pos
    end

    def test_destroy
      new_item = SequentialUpdatesAltId.create
      assert_equal 5, new_item.pos

      new_item.insert_at(2)
      assert_equal 2, new_item.pos

      new_item.destroy
      assert_equal [1,2,3,4], SequentialUpdatesAltId.all.map(&:pos).sort

    end
  end

  class SequentialUpdatesAltIdTouchDisabledTest < ActsAsListTestCase
    def setup
      setup_db
      Timecop.freeze(yesterday) do
        4.times { SequentialUpdatesAltIdTouchDisabled.create! }
      end
    end

    def now
      @now ||= Time.current.change(usec: 0)
    end

    def yesterday
      @yesterday ||= 1.day.ago
    end

    def updated_ats
      SequentialUpdatesAltIdTouchDisabled.order(:altid).pluck(:updated_at)
    end

    def positions
      SequentialUpdatesAltIdTouchDisabled.order(:altid).pluck(:pos)
    end

    def test_sequential_updates_default_to_true_with_unique_index
      assert_equal true, SequentialUpdatesAltIdTouchDisabled.new.send(:sequential_updates?)
    end

    def test_deleting_item_does_not_touch_higher_items
      Timecop.freeze(now) do
        SequentialUpdatesAltIdTouchDisabled.first.destroy
        updated_ats.each do |updated_at|
          assert_equal updated_at.to_i, yesterday.to_i
        end
        assert_equal positions, [1, 2, 3]
      end
    end
  end
end
