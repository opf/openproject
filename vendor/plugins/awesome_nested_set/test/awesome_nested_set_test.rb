#-- encoding: UTF-8
require File.dirname(__FILE__) + '/test_helper'

class Note < ActiveRecord::Base
  acts_as_nested_set :scope => [:notable_id, :notable_type]
end

class AwesomeNestedSetTest < Test::Unit::TestCase

  class Default < ActiveRecord::Base
    acts_as_nested_set
    set_table_name 'categories'
  end
  class Scoped < ActiveRecord::Base
    acts_as_nested_set :scope => :organization
    set_table_name 'categories'
  end

  def test_left_column_default
    assert_equal 'lft', Default.acts_as_nested_set_options[:left_column]
  end

  def test_right_column_default
    assert_equal 'rgt', Default.acts_as_nested_set_options[:right_column]
  end

  def test_parent_column_default
    assert_equal 'parent_id', Default.acts_as_nested_set_options[:parent_column]
  end

  def test_scope_default
    assert_nil Default.acts_as_nested_set_options[:scope]
  end
  
  def test_left_column_name
    assert_equal 'lft', Default.left_column_name
    assert_equal 'lft', Default.new.left_column_name
  end

  def test_right_column_name
    assert_equal 'rgt', Default.right_column_name
    assert_equal 'rgt', Default.new.right_column_name
  end

  def test_parent_column_name
    assert_equal 'parent_id', Default.parent_column_name
    assert_equal 'parent_id', Default.new.parent_column_name
  end
  
  def test_quoted_left_column_name
    quoted = Default.connection.quote_column_name('lft')
    assert_equal quoted, Default.quoted_left_column_name
    assert_equal quoted, Default.new.quoted_left_column_name
  end

  def test_quoted_right_column_name
    quoted = Default.connection.quote_column_name('rgt')
    assert_equal quoted, Default.quoted_right_column_name
    assert_equal quoted, Default.new.quoted_right_column_name
  end

  def test_left_column_protected_from_assignment
    assert_raises(ActiveRecord::ActiveRecordError) { Category.new.lft = 1 }
  end
  
  def test_right_column_protected_from_assignment
    assert_raises(ActiveRecord::ActiveRecordError) { Category.new.rgt = 1 }
  end
  
  def test_parent_column_protected_from_assignment
    assert_raises(ActiveRecord::ActiveRecordError) { Category.new.parent_id = 1 }
  end
  
  def test_colums_protected_on_initialize
    c = Category.new(:lft => 1, :rgt => 2, :parent_id => 3)
    assert_nil c.lft
    assert_nil c.rgt
    assert_nil c.parent_id
  end
  
  def test_scoped_appends_id
    assert_equal :organization_id, Scoped.acts_as_nested_set_options[:scope]
  end
  
  def test_roots_class_method
    assert_equal Category.find_all_by_parent_id(nil), Category.roots
  end
    
  def test_root_class_method
    assert_equal categories(:top_level), Category.root
  end
  
  def test_root
    assert_equal categories(:top_level), categories(:child_3).root
  end
  
  def test_root?
    assert categories(:top_level).root?
    assert categories(:top_level_2).root?
  end
  
  def test_leaves_class_method
    assert_equal Category.find(:all, :conditions => "#{Category.right_column_name} - #{Category.left_column_name} = 1"), Category.leaves
    assert_equal Category.leaves.count, 4
    assert (Category.leaves.include? categories(:child_1))
    assert (Category.leaves.include? categories(:child_2_1))
    assert (Category.leaves.include? categories(:child_3))
    assert (Category.leaves.include? categories(:top_level_2))
  end
  
  def test_leaf
    assert categories(:child_1).leaf?
    assert categories(:child_2_1).leaf?
    assert categories(:child_3).leaf?
    assert categories(:top_level_2).leaf?
    
    assert !categories(:top_level).leaf?
    assert !categories(:child_2).leaf?
  end
    
  def test_parent
    assert_equal categories(:child_2), categories(:child_2_1).parent
  end
  
  def test_self_and_ancestors
    child = categories(:child_2_1)
    self_and_ancestors = [categories(:top_level), categories(:child_2), child]
    assert_equal self_and_ancestors, child.self_and_ancestors
  end

  def test_ancestors
    child = categories(:child_2_1)
    ancestors = [categories(:top_level), categories(:child_2)]
    assert_equal ancestors, child.ancestors
  end
  
  def test_self_and_siblings
    child = categories(:child_2)
    self_and_siblings = [categories(:child_1), child, categories(:child_3)]
    assert_equal self_and_siblings, child.self_and_siblings
    assert_nothing_raised do
      tops = [categories(:top_level), categories(:top_level_2)]
      assert_equal tops, categories(:top_level).self_and_siblings
    end
  end

  def test_siblings
    child = categories(:child_2)
    siblings = [categories(:child_1), categories(:child_3)]
    assert_equal siblings, child.siblings
  end
  
  def test_leaves
    leaves = [categories(:child_1), categories(:child_2_1), categories(:child_3), categories(:top_level_2)]
    assert categories(:top_level).leaves, leaves
  end
  
  def test_level
    assert_equal 0, categories(:top_level).level
    assert_equal 1, categories(:child_1).level
    assert_equal 2, categories(:child_2_1).level
  end
  
  def test_has_children?
    assert categories(:child_2_1).children.empty?
    assert !categories(:child_2).children.empty?
    assert !categories(:top_level).children.empty?
  end
  
  def test_self_and_descendents
    parent = categories(:top_level)
    self_and_descendants = [parent, categories(:child_1), categories(:child_2),
      categories(:child_2_1), categories(:child_3)]
    assert_equal self_and_descendants, parent.self_and_descendants
    assert_equal self_and_descendants, parent.self_and_descendants.count
  end
  
  def test_descendents
    lawyers = Category.create!(:name => "lawyers")
    us = Category.create!(:name => "United States")
    us.move_to_child_of(lawyers)
    patent = Category.create!(:name => "Patent Law")
    patent.move_to_child_of(us)
    lawyers.reload

    assert_equal 1, lawyers.children.size
    assert_equal 1, us.children.size
    assert_equal 2, lawyers.descendants.size
  end
  
  def test_self_and_descendents
    parent = categories(:top_level)
    descendants = [categories(:child_1), categories(:child_2),
      categories(:child_2_1), categories(:child_3)]
    assert_equal descendants, parent.descendants
  end
  
  def test_children
    category = categories(:top_level)
    category.children.each {|c| assert_equal category.id, c.parent_id }
  end
  
  def test_is_or_is_ancestor_of?
    assert categories(:top_level).is_or_is_ancestor_of?(categories(:child_1))
    assert categories(:top_level).is_or_is_ancestor_of?(categories(:child_2_1))
    assert categories(:child_2).is_or_is_ancestor_of?(categories(:child_2_1))
    assert !categories(:child_2_1).is_or_is_ancestor_of?(categories(:child_2))
    assert !categories(:child_1).is_or_is_ancestor_of?(categories(:child_2))
    assert categories(:child_1).is_or_is_ancestor_of?(categories(:child_1))
  end
  
  def test_is_ancestor_of?
    assert categories(:top_level).is_ancestor_of?(categories(:child_1))
    assert categories(:top_level).is_ancestor_of?(categories(:child_2_1))
    assert categories(:child_2).is_ancestor_of?(categories(:child_2_1))
    assert !categories(:child_2_1).is_ancestor_of?(categories(:child_2))
    assert !categories(:child_1).is_ancestor_of?(categories(:child_2))
    assert !categories(:child_1).is_ancestor_of?(categories(:child_1))
  end

  def test_is_or_is_ancestor_of_with_scope
    root = Scoped.root
    child = root.children.first
    assert root.is_or_is_ancestor_of?(child)
    child.update_attribute :organization_id, 'different'
    assert !root.is_or_is_ancestor_of?(child)
  end

  def test_is_or_is_descendant_of?
    assert categories(:child_1).is_or_is_descendant_of?(categories(:top_level))
    assert categories(:child_2_1).is_or_is_descendant_of?(categories(:top_level))
    assert categories(:child_2_1).is_or_is_descendant_of?(categories(:child_2))
    assert !categories(:child_2).is_or_is_descendant_of?(categories(:child_2_1))
    assert !categories(:child_2).is_or_is_descendant_of?(categories(:child_1))
    assert categories(:child_1).is_or_is_descendant_of?(categories(:child_1))
  end
  
  def test_is_descendant_of?
    assert categories(:child_1).is_descendant_of?(categories(:top_level))
    assert categories(:child_2_1).is_descendant_of?(categories(:top_level))
    assert categories(:child_2_1).is_descendant_of?(categories(:child_2))
    assert !categories(:child_2).is_descendant_of?(categories(:child_2_1))
    assert !categories(:child_2).is_descendant_of?(categories(:child_1))
    assert !categories(:child_1).is_descendant_of?(categories(:child_1))
  end
  
  def test_is_or_is_descendant_of_with_scope
    root = Scoped.root
    child = root.children.first
    assert child.is_or_is_descendant_of?(root)
    child.update_attribute :organization_id, 'different'
    assert !child.is_or_is_descendant_of?(root)
  end
  
  def test_same_scope?
    root = Scoped.root
    child = root.children.first
    assert child.same_scope?(root)
    child.update_attribute :organization_id, 'different'
    assert !child.same_scope?(root)
  end
  
  def test_left_sibling
    assert_equal categories(:child_1), categories(:child_2).left_sibling
    assert_equal categories(:child_2), categories(:child_3).left_sibling
  end

  def test_left_sibling_of_root
    assert_nil categories(:top_level).left_sibling
  end

  def test_left_sibling_without_siblings
    assert_nil categories(:child_2_1).left_sibling
  end

  def test_left_sibling_of_leftmost_node
    assert_nil categories(:child_1).left_sibling
  end

  def test_right_sibling
    assert_equal categories(:child_3), categories(:child_2).right_sibling
    assert_equal categories(:child_2), categories(:child_1).right_sibling
  end

  def test_right_sibling_of_root
    assert_equal categories(:top_level_2), categories(:top_level).right_sibling
    assert_nil categories(:top_level_2).right_sibling
  end

  def test_right_sibling_without_siblings
    assert_nil categories(:child_2_1).right_sibling
  end

  def test_right_sibling_of_rightmost_node
    assert_nil categories(:child_3).right_sibling
  end
  
  def test_move_left
    categories(:child_2).move_left
    assert_nil categories(:child_2).left_sibling
    assert_equal categories(:child_1), categories(:child_2).right_sibling
    assert Category.valid?
  end

  def test_move_right
    categories(:child_2).move_right
    assert_nil categories(:child_2).right_sibling
    assert_equal categories(:child_3), categories(:child_2).left_sibling
    assert Category.valid?
  end

  def test_move_to_left_of
    categories(:child_3).move_to_left_of(categories(:child_1))
    assert_nil categories(:child_3).left_sibling
    assert_equal categories(:child_1), categories(:child_3).right_sibling
    assert Category.valid?
  end

  def test_move_to_right_of
    categories(:child_1).move_to_right_of(categories(:child_3))
    assert_nil categories(:child_1).right_sibling
    assert_equal categories(:child_3), categories(:child_1).left_sibling
    assert Category.valid?
  end
  
  def test_move_to_root
    categories(:child_2).move_to_root
    assert_nil categories(:child_2).parent
    assert_equal 0, categories(:child_2).level
    assert_equal 1, categories(:child_2_1).level
    assert_equal 1, categories(:child_2).left
    assert_equal 4, categories(:child_2).right
    assert Category.valid?
  end

  def test_move_to_child_of
    categories(:child_1).move_to_child_of(categories(:child_3))
    assert_equal categories(:child_3).id, categories(:child_1).parent_id
    assert Category.valid?
  end
  
  def test_move_to_child_of_appends_to_end
    child = Category.create! :name => 'New Child'
    child.move_to_child_of categories(:top_level)
    assert_equal child, categories(:top_level).children.last
  end
  
  def test_subtree_move_to_child_of
    assert_equal 4, categories(:child_2).left
    assert_equal 7, categories(:child_2).right
    
    assert_equal 2, categories(:child_1).left
    assert_equal 3, categories(:child_1).right
    
    categories(:child_2).move_to_child_of(categories(:child_1))
    assert Category.valid?
    assert_equal categories(:child_1).id, categories(:child_2).parent_id
    
    assert_equal 3, categories(:child_2).left
    assert_equal 6, categories(:child_2).right
    assert_equal 2, categories(:child_1).left
    assert_equal 7, categories(:child_1).right    
  end
  
  def test_slightly_difficult_move_to_child_of
    assert_equal 11, categories(:top_level_2).left
    assert_equal 12, categories(:top_level_2).right
    
    # create a new top-level node and move single-node top-level tree inside it.
    new_top = Category.create(:name => 'New Top')
    assert_equal 13, new_top.left
    assert_equal 14, new_top.right
    
    categories(:top_level_2).move_to_child_of(new_top)
    
    assert Category.valid?
    assert_equal new_top.id, categories(:top_level_2).parent_id
    
    assert_equal 12, categories(:top_level_2).left
    assert_equal 13, categories(:top_level_2).right
    assert_equal 11, new_top.left
    assert_equal 14, new_top.right    
  end
  
  def test_difficult_move_to_child_of
    assert_equal 1, categories(:top_level).left
    assert_equal 10, categories(:top_level).right
    assert_equal 5, categories(:child_2_1).left
    assert_equal 6, categories(:child_2_1).right
    
    # create a new top-level node and move an entire top-level tree inside it.
    new_top = Category.create(:name => 'New Top')
    categories(:top_level).move_to_child_of(new_top)
    categories(:child_2_1).reload
    assert Category.valid?  
    assert_equal new_top.id, categories(:top_level).parent_id
    
    assert_equal 4, categories(:top_level).left
    assert_equal 13, categories(:top_level).right
    assert_equal 8, categories(:child_2_1).left
    assert_equal 9, categories(:child_2_1).right    
  end

  #rebuild swaps the position of the 2 children when added using move_to_child twice onto same parent
  def test_move_to_child_more_than_once_per_parent_rebuild
    root1 = Category.create(:name => 'Root1')
    root2 = Category.create(:name => 'Root2')
    root3 = Category.create(:name => 'Root3')
    
    root2.move_to_child_of root1
    root3.move_to_child_of root1
      
    output = Category.roots.last.to_text
    Category.update_all('lft = null, rgt = null')
    Category.rebuild!
    
    assert_equal Category.roots.last.to_text, output
  end
  
  # doing move_to_child twice onto same parent from the furthest right first
  def test_move_to_child_more_than_once_per_parent_outside_in
    node1 = Category.create(:name => 'Node-1')
    node2 = Category.create(:name => 'Node-2')
    node3 = Category.create(:name => 'Node-3')
    
    node2.move_to_child_of node1
    node3.move_to_child_of node1
      
    output = Category.roots.last.to_text
    Category.update_all('lft = null, rgt = null')
    Category.rebuild!
    
    assert_equal Category.roots.last.to_text, output
  end


  def test_valid_with_null_lefts
    assert Category.valid?
    Category.update_all('lft = null')
    assert !Category.valid?
  end

  def test_valid_with_null_rights
    assert Category.valid?
    Category.update_all('rgt = null')
    assert !Category.valid?
  end
  
  def test_valid_with_missing_intermediate_node
    # Even though child_2_1 will still exist, it is a sign of a sloppy delete, not an invalid tree.
    assert Category.valid?
    Category.delete(categories(:child_2).id)
    assert Category.valid?
  end
  
  def test_valid_with_overlapping_and_rights
    assert Category.valid?
    categories(:top_level_2)['lft'] = 0
    categories(:top_level_2).save
    assert !Category.valid?
  end
  
  def test_rebuild
    assert Category.valid?
    before_text = Category.root.to_text
    Category.update_all('lft = null, rgt = null')
    Category.rebuild!
    assert Category.valid?
    assert_equal before_text, Category.root.to_text
  end
  
  def test_move_possible_for_sibling
    assert categories(:child_2).move_possible?(categories(:child_1))
  end
  
  def test_move_not_possible_to_self
    assert !categories(:top_level).move_possible?(categories(:top_level))
  end
  
  def test_move_not_possible_to_parent
    categories(:top_level).descendants.each do |descendant|
      assert !categories(:top_level).move_possible?(descendant)
      assert descendant.move_possible?(categories(:top_level))
    end
  end
  
  def test_is_or_is_ancestor_of?
    [:child_1, :child_2, :child_2_1, :child_3].each do |c|
      assert categories(:top_level).is_or_is_ancestor_of?(categories(c))
    end
    assert !categories(:top_level).is_or_is_ancestor_of?(categories(:top_level_2))
  end
  
  def test_left_and_rights_valid_with_blank_left
    assert Category.left_and_rights_valid?
    categories(:child_2)[:lft] = nil
    categories(:child_2).save(false)
    assert !Category.left_and_rights_valid?
  end

  def test_left_and_rights_valid_with_blank_right
    assert Category.left_and_rights_valid?
    categories(:child_2)[:rgt] = nil
    categories(:child_2).save(false)
    assert !Category.left_and_rights_valid?
  end

  def test_left_and_rights_valid_with_equal
    assert Category.left_and_rights_valid?
    categories(:top_level_2)[:lft] = categories(:top_level_2)[:rgt]
    categories(:top_level_2).save(false)
    assert !Category.left_and_rights_valid?
  end

  def test_left_and_rights_valid_with_left_equal_to_parent
    assert Category.left_and_rights_valid?
    categories(:child_2)[:lft] = categories(:top_level)[:lft]
    categories(:child_2).save(false)
    assert !Category.left_and_rights_valid?
  end

  def test_left_and_rights_valid_with_right_equal_to_parent
    assert Category.left_and_rights_valid?
    categories(:child_2)[:rgt] = categories(:top_level)[:rgt]
    categories(:child_2).save(false)
    assert !Category.left_and_rights_valid?
  end
  
  def test_moving_dirty_objects_doesnt_invalidate_tree
    r1 = Category.create
    r2 = Category.create
    r3 = Category.create
    r4 = Category.create
    nodes = [r1, r2, r3, r4]
    
    r2.move_to_child_of(r1)
    assert Category.valid?
    
    r3.move_to_child_of(r1)
    assert Category.valid?
    
    r4.move_to_child_of(r2)
    assert Category.valid?
  end
  
  def test_multi_scoped_no_duplicates_for_columns?
    assert_nothing_raised do
      Note.no_duplicates_for_columns?
    end
  end

  def test_multi_scoped_all_roots_valid?
    assert_nothing_raised do
      Note.all_roots_valid?
    end
  end

  def test_multi_scoped
    note1 = Note.create!(:body => "A", :notable_id => 2, :notable_type => 'Category')
    note2 = Note.create!(:body => "B", :notable_id => 2, :notable_type => 'Category')
    note3 = Note.create!(:body => "C", :notable_id => 2, :notable_type => 'Default')
    
    assert_equal [note1, note2], note1.self_and_siblings
    assert_equal [note3], note3.self_and_siblings
  end
  
  def test_multi_scoped_rebuild
    root = Note.create!(:body => "A", :notable_id => 3, :notable_type => 'Category')
    child1 = Note.create!(:body => "B", :notable_id => 3, :notable_type => 'Category')
    child2 = Note.create!(:body => "C", :notable_id => 3, :notable_type => 'Category')
    
    child1.move_to_child_of root
    child2.move_to_child_of root
          
    Note.update_all('lft = null, rgt = null')
    Note.rebuild!
    
    assert_equal Note.roots.find_by_body('A'), root
    assert_equal [child1, child2], Note.roots.find_by_body('A').children
  end
  
  def test_same_scope_with_multi_scopes
    assert_nothing_raised do
      notes(:scope1).same_scope?(notes(:child_1))
    end
    assert notes(:scope1).same_scope?(notes(:child_1))
    assert notes(:child_1).same_scope?(notes(:scope1))
    assert !notes(:scope1).same_scope?(notes(:scope2))
  end
  
  def test_quoting_of_multi_scope_column_names
    assert_equal ["\"notable_id\"", "\"notable_type\""], Note.quoted_scope_column_names
  end
  
  def test_equal_in_same_scope
    assert_equal notes(:scope1), notes(:scope1)
    assert_not_equal notes(:scope1), notes(:child_1)
  end
  
  def test_equal_in_different_scopes
    assert_not_equal notes(:scope1), notes(:scope2)
  end
  
end
