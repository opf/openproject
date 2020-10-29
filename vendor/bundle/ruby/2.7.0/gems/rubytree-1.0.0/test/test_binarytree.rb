#!/usr/bin/env ruby

# test_binarytree.rb - This file is part of the RubyTree package.
#
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2012, 2013, 2015, 2017 Anupam Sengupta
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# - Neither the name of the organization nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require 'test/unit'
require_relative '../lib/tree/binarytree'

module TestTree
  # Test class for the binary tree node.
  class TestBinaryTreeNode < Test::Unit::TestCase

    # Setup the test data scaffolding.
    def setup
      @root = Tree::BinaryTreeNode.new('ROOT', 'Root Node')

      @left_child1  = Tree::BinaryTreeNode.new('A Child at Left', 'Child Node @ left')
      @right_child1 = Tree::BinaryTreeNode.new('B Child at Right', 'Child Node @ right')
    end

    # Tear down the test data scaffolding.
    def teardown
      @root.remove!(@left_child1)
      @root.remove!(@right_child1)
      @root = nil
    end

    # Test initialization of the binary tree.
    def test_initialize
      assert_not_nil(@root, "Binary tree's Root should have been created")
      assert_nil(@root.left_child, 'The initial left child of root should be nil')
      assert_nil(@root.right_child, 'The initial right child of root should be nil')
      assert_equal(@root.children.size, 0, 'Initially no children should be present')
    end

    def test_from_hash
      # Can't make a root node without a name
      assert_raise (ArgumentError) { Tree::BinaryTreeNode.from_hash({})}
      # Can't have multiple roots
      assert_raise (ArgumentError) { Tree::BinaryTreeNode.from_hash({A: {}, B: {}}) }

      # Can't have more than 2 children
      too_many_kids = {A: {B: {}, C: {}, D: {}}}
      assert_raise(ArgumentError) { Tree::BinaryTreeNode.from_hash(too_many_kids) }

      valid_hash = {A: {B: {}, C: {D: {}}}}
      tree = Tree::BinaryTreeNode.from_hash(valid_hash)
      #    A
      #   / \
      #  B   C
      #      |
      #      D

      assert_same(tree.class, Tree::BinaryTreeNode)
      assert_same(:A, tree.name)
      assert_equal(true, tree.is_root?)
      assert_equal(false, tree.is_leaf?)
      assert_equal(2, tree.children.count) # B, C, D
      assert_equal(4, tree.size)

      valid_hash_with_content = {[:A, 'Content!'] => {B: {}, C: {[:D, 'More content'] => {}}} }
      tree2 = Tree::BinaryTreeNode.from_hash(valid_hash_with_content)

      assert_equal(Tree::BinaryTreeNode, tree2.class)
      assert_equal('Content!', tree2.content)
      assert_equal('More content', tree2[:C][:D].content)
    end

    def test_add_from_hash
      root = Tree::BinaryTreeNode.new('Root')

      # Can't have too many children
      too_many_kids = {child1: {}, child2: {}, child3: {}}
      assert_raise(ArgumentError) { root.add_from_hash(too_many_kids) }
      assert_equal(0, root.children.count) # Nothing added

      # Well behaved when adding nothing
      assert_equal([], root.add_from_hash({}))
      assert_equal(1, root.size)

      valid_hash = {A: {}, B: {C: {}, [:D, 'leaf'] => {}}}
      added = root.add_from_hash(valid_hash)
      #   root
      #   / \
      #  A   B
      #     / \
      #    C   D

      assert_equal(Array, added.class)
      assert_equal(2, added.count)
      assert_equal(5, root.size)
      assert_equal(root.children.count, 2)
      assert_equal('leaf', root[:B][:D].content)

      # Can't add more than two children
      assert_raise(ArgumentError) { root.add_from_hash({X: {}}) }
      node = Tree::BinaryTreeNode.new('Root 2')
      assert_raise(ArgumentError) { node.add_from_hash({A: {}, B: {}, C: {}}) }
    end

    # Test the add method.
    def test_add
      @root.add @left_child1
      assert(!@left_child1.is_root?, 'Left child1 cannot be a root after addition to the ROOT node')

      assert_same(@left_child1, @root.left_child, 'The left node should be left_child1')
      assert_same(@left_child1, @root.first_child, 'The first node should be left_child1')

      @root.add @right_child1
      assert(!@right_child1.is_root?, 'Right child1 cannot be a root after addition to the ROOT node')

      assert_same(@right_child1, @root.right_child, 'The right node should be right_child1')
      assert_same(@right_child1, @root.last_child, 'The first node should be right_child1')

      assert_raise ArgumentError do
        @root.add Tree::BinaryTreeNode.new('The third child!')
      end

      assert_raise ArgumentError do
        @root << Tree::BinaryTreeNode.new('The third child!')
      end
    end

    # Test the inordered_each method.
    def test_inordered_each
      a = Tree::BinaryTreeNode.new('a')
      b = Tree::BinaryTreeNode.new('b')
      c = Tree::BinaryTreeNode.new('c')
      d = Tree::BinaryTreeNode.new('d')
      e = Tree::BinaryTreeNode.new('e')
      f = Tree::BinaryTreeNode.new('f')
      g = Tree::BinaryTreeNode.new('g')
      h = Tree::BinaryTreeNode.new('h')
      i = Tree::BinaryTreeNode.new('i')

      # Create the following Tree
      #        f         <-- level 0 (Root)
      #      /   \
      #     b      g     <-- level 1
      #   /   \      \
      #  a     d      i  <-- level 2
      #       / \    /
      #      c  e   h    <-- level 3
      f << b << a
      f << g
      b << d << c
      d << e
      g.right_child = i         # This needs to be explicit
      i << h

      # The expected order of response
      expected_array = [a, b, c, d, e, f, g, h, i]

      result_array = []
      result = f.inordered_each { |node| result_array << node.detached_copy}

      assert_equal(f, result)   # each should return the original object

      expected_array.each_index do |idx|
        # Match only the names.
        assert_equal(expected_array[idx].name, result_array[idx].name)
      end

      assert_equal(Enumerator, f.inordered_each.class) if defined?(Enumerator.class )# Without a block
      assert_equal(Enumerable::Enumerator, f.inordered_each.class) if defined?(Enumerable::Enumerator.class )# Without a block
    end

    # Test the left_child method.
    def test_left_child
      @root << @left_child1
      @root << @right_child1
      assert_same(@left_child1, @root.left_child, "The left child should be 'left_child1")
      assert_not_same(@right_child1, @root.left_child, 'The right_child1 is not the left child')
    end

    # Test the right_child method.
    def test_right_child
      @root << @left_child1
      @root << @right_child1
      assert_same(@right_child1, @root.right_child, "The right child should be 'right_child1")
      assert_not_same(@left_child1, @root.right_child, 'The left_child1 is not the left child')
    end

    # Test left_child= method.
    def test_left_child_equals
      @root << @left_child1
      @root << @right_child1
      assert_same(@left_child1, @root.left_child, "The left child should be 'left_child1")
      assert(!@left_child1.is_root?, 'The left child now cannot be a root.')

      @root.left_child = Tree::BinaryTreeNode.new('New Left Child')
      assert(!@root.left_child.is_root?, 'The left child now cannot be a root.')
      assert_equal('New Left Child', @root.left_child.name, 'The left child should now be the new child')
      assert_equal('B Child at Right', @root.last_child.name, 'The last child should now be the right child')

      # Now set the left child as nil, and retest
      @root.left_child = nil
      assert_nil(@root.left_child, 'The left child should now be nil')
      assert_nil(@root.first_child, 'The first child is now nil')
      assert_equal('B Child at Right', @root.last_child.name, 'The last child should now be the right child')
    end

    # Test right_child= method.
    def test_right_child_equals
      @root << @left_child1
      @root << @right_child1
      assert_same(@right_child1, @root.right_child, "The right child should be 'right_child1")
      assert(!@right_child1.is_root?, 'The right child now cannot be a root.')

      @root.right_child = Tree::BinaryTreeNode.new('New Right Child')
      assert(!@root.right_child.is_root?, 'The right child now cannot be a root.')
      assert_equal('New Right Child', @root.right_child.name, 'The right child should now be the new child')
      assert_equal('A Child at Left', @root.first_child.name, 'The first child should now be the left child')
      assert_equal('New Right Child', @root.last_child.name, 'The last child should now be the right child')

      # Now set the right child as nil, and retest
      @root.right_child = nil
      assert_nil(@root.right_child, 'The right child should now be nil')
      assert_equal('A Child at Left', @root.first_child.name, 'The first child should now be the left child')
      assert_nil(@root.last_child, 'The first child is now nil')
    end

    # Test isLeft_child? method.
    def test_is_left_child_eh
      @root << @left_child1
      @root << @right_child1

      assert(@left_child1.is_left_child?, 'left_child1 should be the left child')
      assert(!@right_child1.is_left_child?, 'left_child1 should be the left child')

      # Now set the right child as nil, and retest
      @root.right_child = nil
      assert(@left_child1.is_left_child?, 'left_child1 should be the left child')

      assert(!@root.is_left_child?, 'Root is neither left child nor right')
    end

    # Test is_right_child? method.
    def test_is_right_child_eh
      @root << @left_child1
      @root << @right_child1

      assert(@right_child1.is_right_child?, 'right_child1 should be the right child')
      assert(!@left_child1.is_right_child?, 'right_child1 should be the right child')

      # Now set the left child as nil, and retest
      @root.left_child = nil
      assert(@right_child1.is_right_child?, 'right_child1 should be the right child')
      assert(!@root.is_right_child?, 'Root is neither left child nor right')
    end

    # Test swap_children method.
    def test_swap_children
      @root << @left_child1
      @root << @right_child1

      assert(@right_child1.is_right_child?, 'right_child1 should be the right child')
      assert(!@left_child1.is_right_child?, 'right_child1 should be the right child')

      @root.swap_children

      assert(@right_child1.is_left_child?, 'right_child1 should now be the left child')
      assert(@left_child1.is_right_child?, 'left_child1 should now be the right child')
      assert_equal(@right_child1, @root.first_child, 'right_child1 should now be the first child')
      assert_equal(@left_child1, @root.last_child, 'left_child1 should now be the last child')
      assert_equal(@right_child1, @root[0], 'right_child1 should now be the first child')
      assert_equal(@left_child1, @root[1], 'left_child1 should now be the last child')
    end

    # Test the old CamelCase method names
    def test_old_camel_case_names
      @left_child2  = Tree::BinaryTreeNode.new('A Child at Left', 'Child Node @ left')
      @right_child2 = Tree::BinaryTreeNode.new('B Child at Right', 'Child Node @ right')

      require 'structured_warnings'

      meth_names_for_test = %w{leftChild isLeftChild? rightChild isRightChild?}

      meth_names_for_test.each do |meth_name|
        assert_warn(StructuredWarnings::DeprecatedMethodWarning) {@root.send(meth_name)}
      end

      # noinspection RubyResolve
      assert_warn(StructuredWarnings::DeprecatedMethodWarning) {@root.leftChild = @left_child2}
      # noinspection RubyResolve
      assert_warn(StructuredWarnings::DeprecatedMethodWarning) {@root.rightChild = @right_child2}
      assert_raise(NoMethodError) {@root.DummyMethodDoesNotExist} # Make sure the right method is visible

    end

  end
end
