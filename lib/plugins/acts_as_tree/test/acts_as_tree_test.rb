#-- encoding: UTF-8
require 'test/unit'

require 'rubygems'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../lib'
require File.dirname(__FILE__) + '/../init'

class Test::Unit::TestCase
  def assert_queries(num = 1)
    $query_count = 0
    yield
  ensure
    assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

# AR keeps printing annoying schema statements
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :type, :string
      t.column :parent_id, :integer
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class TreeMixin < Mixin 
  acts_as_tree :foreign_key => "parent_id", :order => "id"
end

class TreeMixinWithoutOrder < Mixin
  acts_as_tree :foreign_key => "parent_id"
end

class RecursivelyCascadedTreeMixin < Mixin
  acts_as_tree :foreign_key => "parent_id"
  has_one :first_child, :class_name => 'RecursivelyCascadedTreeMixin', :foreign_key => :parent_id
end

class TreeTest < Test::Unit::TestCase
  
  def setup
    setup_db
    @root1 = TreeMixin.create!
    @root_child1 = TreeMixin.create! :parent_id => @root1.id
    @child1_child = TreeMixin.create! :parent_id => @root_child1.id
    @root_child2 = TreeMixin.create! :parent_id => @root1.id
    @root2 = TreeMixin.create!
    @root3 = TreeMixin.create!
  end

  def teardown
    teardown_db
  end

  def test_children
    assert_equal @root1.children, [@root_child1, @root_child2]
    assert_equal @root_child1.children, [@child1_child]
    assert_equal @child1_child.children, []
    assert_equal @root_child2.children, []
  end

  def test_parent
    assert_equal @root_child1.parent, @root1
    assert_equal @root_child1.parent, @root_child2.parent
    assert_nil @root1.parent
  end

  def test_delete
    assert_equal 6, TreeMixin.count
    @root1.destroy
    assert_equal 2, TreeMixin.count
    @root2.destroy
    @root3.destroy
    assert_equal 0, TreeMixin.count
  end

  def test_insert
    @extra = @root1.children.create

    assert @extra

    assert_equal @extra.parent, @root1

    assert_equal 3, @root1.children.size
    assert @root1.children.include?(@extra)
    assert @root1.children.include?(@root_child1)
    assert @root1.children.include?(@root_child2)
  end

  def test_ancestors
    assert_equal [], @root1.ancestors
    assert_equal [@root1], @root_child1.ancestors
    assert_equal [@root_child1, @root1], @child1_child.ancestors
    assert_equal [@root1], @root_child2.ancestors
    assert_equal [], @root2.ancestors
    assert_equal [], @root3.ancestors
  end

  def test_root
    assert_equal @root1, TreeMixin.root
    assert_equal @root1, @root1.root
    assert_equal @root1, @root_child1.root
    assert_equal @root1, @child1_child.root
    assert_equal @root1, @root_child2.root
    assert_equal @root2, @root2.root
    assert_equal @root3, @root3.root
  end

  def test_roots
    assert_equal [@root1, @root2, @root3], TreeMixin.roots
  end

  def test_siblings
    assert_equal [@root2, @root3], @root1.siblings
    assert_equal [@root_child2], @root_child1.siblings
    assert_equal [], @child1_child.siblings
    assert_equal [@root_child1], @root_child2.siblings
    assert_equal [@root1, @root3], @root2.siblings
    assert_equal [@root1, @root2], @root3.siblings
  end

  def test_self_and_siblings
    assert_equal [@root1, @root2, @root3], @root1.self_and_siblings
    assert_equal [@root_child1, @root_child2], @root_child1.self_and_siblings
    assert_equal [@child1_child], @child1_child.self_and_siblings
    assert_equal [@root_child1, @root_child2], @root_child2.self_and_siblings
    assert_equal [@root1, @root2, @root3], @root2.self_and_siblings
    assert_equal [@root1, @root2, @root3], @root3.self_and_siblings
  end           
end

class TreeTestWithEagerLoading < Test::Unit::TestCase
  
  def setup 
    teardown_db
    setup_db
    @root1 = TreeMixin.create!
    @root_child1 = TreeMixin.create! :parent_id => @root1.id
    @child1_child = TreeMixin.create! :parent_id => @root_child1.id
    @root_child2 = TreeMixin.create! :parent_id => @root1.id
    @root2 = TreeMixin.create!
    @root3 = TreeMixin.create!
    
    @rc1 = RecursivelyCascadedTreeMixin.create!
    @rc2 = RecursivelyCascadedTreeMixin.create! :parent_id => @rc1.id 
    @rc3 = RecursivelyCascadedTreeMixin.create! :parent_id => @rc2.id
    @rc4 = RecursivelyCascadedTreeMixin.create! :parent_id => @rc3.id
  end

  def teardown
    teardown_db
  end
    
  def test_eager_association_loading
    roots = TreeMixin.find(:all, :include => :children, :conditions => "mixins.parent_id IS NULL", :order => "mixins.id")
    assert_equal [@root1, @root2, @root3], roots                     
    assert_no_queries do
      assert_equal 2, roots[0].children.size
      assert_equal 0, roots[1].children.size
      assert_equal 0, roots[2].children.size
    end   
  end
  
  def test_eager_association_loading_with_recursive_cascading_three_levels_has_many
    root_node = RecursivelyCascadedTreeMixin.find(:first, :include => { :children => { :children => :children } }, :order => 'mixins.id')
    assert_equal @rc4, assert_no_queries { root_node.children.first.children.first.children.first }
  end
  
  def test_eager_association_loading_with_recursive_cascading_three_levels_has_one
    root_node = RecursivelyCascadedTreeMixin.find(:first, :include => { :first_child => { :first_child => :first_child } }, :order => 'mixins.id')
    assert_equal @rc4, assert_no_queries { root_node.first_child.first_child.first_child }
  end
  
  def test_eager_association_loading_with_recursive_cascading_three_levels_belongs_to
    leaf_node = RecursivelyCascadedTreeMixin.find(:first, :include => { :parent => { :parent => :parent } }, :order => 'mixins.id DESC')
    assert_equal @rc1, assert_no_queries { leaf_node.parent.parent.parent }
  end 
end

class TreeTestWithoutOrder < Test::Unit::TestCase
  
  def setup                               
    setup_db
    @root1 = TreeMixinWithoutOrder.create!
    @root2 = TreeMixinWithoutOrder.create!
  end

  def teardown
    teardown_db
  end

  def test_root
    assert [@root1, @root2].include?(TreeMixinWithoutOrder.root)
  end
  
  def test_roots
    assert_equal [], [@root1, @root2] - TreeMixinWithoutOrder.roots
  end
end 
