#!/usr/bin/env ruby

# testtree.rb
#
# $Revision: 1.6 $ by $Author: anupamsg $
# $Name:  $
#
# Copyright (c) 2006, 2007 Anupam Sengupta
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
require 'tree'

module TestTree
  # Test class for the Tree node.
  class TestTreeNode < Test::Unit::TestCase

    Person = Struct::new(:First, :last)

    def setup
      @root = Tree::TreeNode.new("ROOT", "Root Node")

      @child1 = Tree::TreeNode.new("Child1", "Child Node 1")
      @child2 = Tree::TreeNode.new("Child2", "Child Node 2")
      @child3 = Tree::TreeNode.new("Child3", "Child Node 3")
      @child4 = Tree::TreeNode.new("Child31", "Grand Child 1")

    end

    # Create this structure for the tests
    #
    #          +----------+
    #          |  ROOT    |
    #          +-+--------+
    #            |
    #            |    +---------------+
    #            +----+  CHILD1       |
    #            |    +---------------+
    #            |
    #            |    +---------------+
    #            +----+  CHILD2       |
    #            |    +---------------+
    #            |
    #            |    +---------------+   +------------------+
    #            +----+  CHILD3       +---+  CHILD4          |
    #                 +---------------+   +------------------+
    #
    def loadChildren
      @root << @child1
      @root << @child2
      @root << @child3 << @child4
    end

    def teardown
      @root = nil
    end

    def test_root_setup
      assert_not_nil(@root, "Root cannot be nil")
      assert_nil(@root.parent, "Parent of root node should be nil")
      assert_not_nil(@root.name, "Name should not be nil")
      assert_equal("ROOT", @root.name, "Name should be 'ROOT'")
      assert_equal("Root Node", @root.content, "Content should be 'Root Node'")
      assert(@root.isRoot?, "Should identify as root")
      assert(!@root.hasChildren?, "Cannot have any children")
      assert(@root.hasContent?, "This root should have content")
      assert_equal(1, @root.size, "Number of nodes should be one")
      assert_nil(@root.siblings, "Root cannot have any children")

      assert_raise(RuntimeError) { Tree::TreeNode.new(nil) }
    end

    def test_root
      loadChildren

      assert_same(@root, @root.root, "Root's root is self")
      assert_same(@root, @child1.root, "Root should be ROOT")
      assert_same(@root, @child4.root, "Root should be ROOT")
    end

    def test_hasContent_eh
      aNode = Tree::TreeNode.new("A Node")
      assert_nil(aNode.content, "The node should not have content")
      assert(!aNode.hasContent?, "The node should not have content")

      aNode.content = "Something"
      assert_not_nil(aNode.content, "The node should now have content")
      assert(aNode.hasContent?, "The node should now have content")
    end

    def test_length
      loadChildren
      assert_equal(@root.size, @root.length, "Length and size methods should return the same result")
    end

    def test_spaceship          # Test the <=> operator.
      firstNode  = Tree::TreeNode.new(1)
      secondNode = Tree::TreeNode.new(2)

      assert_equal(firstNode <=> nil, +1)
      assert_equal(firstNode <=> secondNode, -1)

      secondNode = Tree::TreeNode.new(1)
      assert_equal(firstNode <=> secondNode, 0)

      firstNode  = Tree::TreeNode.new("ABC")
      secondNode = Tree::TreeNode.new("XYZ")

      assert_equal(firstNode <=> nil, +1)
      assert_equal(firstNode <=> secondNode, -1)

      secondNode = Tree::TreeNode.new("ABC")
      assert_equal(firstNode <=> secondNode, 0)
    end

    def test_to_s
      aNode = Tree::TreeNode.new("A Node", "Some Content")

      expectedString = "Node Name: A Node Content: Some Content Parent: <None> Children: 0 Total Nodes: 1"

      assert_equal(expectedString, aNode.to_s, "The string representation should be same")
    end

    def test_firstSibling
      loadChildren

      assert_same(@root, @root.firstSibling, "Root's first sibling is itself")
      assert_same(@child1, @child1.firstSibling, "Child1's first sibling is itself")
      assert_same(@child1, @child2.firstSibling, "Child2's first sibling should be child1")
      assert_same(@child1, @child3.firstSibling, "Child3's first sibling should be child1")
      assert_not_same(@child1, @child4.firstSibling, "Child4's first sibling is itself")
    end

    def test_isFirstSibling_eh
      loadChildren

      assert(@root.isFirstSibling?, "Root's first sibling is itself")
      assert( @child1.isFirstSibling?, "Child1's first sibling is itself")
      assert(!@child2.isFirstSibling?, "Child2 is not the first sibling")
      assert(!@child3.isFirstSibling?, "Child3 is not the first sibling")
      assert( @child4.isFirstSibling?, "Child4's first sibling is itself")
    end

    def test_isLastSibling_eh
      loadChildren

      assert(@root.isLastSibling?, "Root's last sibling is itself")
      assert(!@child1.isLastSibling?, "Child1 is not the last sibling")
      assert(!@child2.isLastSibling?, "Child2 is not the last sibling")
      assert( @child3.isLastSibling?, "Child3's last sibling is itself")
      assert( @child4.isLastSibling?, "Child4's last sibling is itself")
    end

    def test_lastSibling
      loadChildren

      assert_same(@root, @root.lastSibling, "Root's last sibling is itself")
      assert_same(@child3, @child1.lastSibling, "Child1's last sibling should be child3")
      assert_same(@child3, @child2.lastSibling, "Child2's last sibling should be child3")
      assert_same(@child3, @child3.lastSibling, "Child3's last sibling should be itself")
      assert_not_same(@child3, @child4.lastSibling, "Child4's last sibling is itself")
    end

    def test_siblings
      loadChildren

      siblings = []
      @child1.siblings { |sibling| siblings << sibling}
      assert_equal(2, siblings.length, "Should have two siblings")
      assert(siblings.include?(@child2), "Should have 2nd child as sibling")
      assert(siblings.include?(@child3), "Should have 3rd child as sibling")

      siblings.clear
      siblings = @child1.siblings
      assert_equal(2, siblings.length, "Should have two siblings")

      siblings.clear
      @child4.siblings {|sibling| siblings << sibling}
      assert(siblings.empty?, "Should not have any children")

    end

    def test_isOnlyChild_eh
      loadChildren

      assert(!@child1.isOnlyChild?, "Child1 is not the only child")
      assert(!@child2.isOnlyChild?, "Child2 is not the only child")
      assert(!@child3.isOnlyChild?, "Child3 is not the only child")
      assert( @child4.isOnlyChild?, "Child4 is not the only child")
    end

    def test_nextSibling
      loadChildren

      assert_equal(@child2, @child1.nextSibling, "Child1's next sibling is Child2")
      assert_equal(@child3, @child2.nextSibling, "Child2's next sibling is Child3")
      assert_nil(@child3.nextSibling, "Child3 does not have a next sibling")
      assert_nil(@child4.nextSibling, "Child4 does not have a next sibling")
    end

    def test_previousSibling
      loadChildren

      assert_nil(@child1.previousSibling, "Child1 does not have previous sibling")
      assert_equal(@child1, @child2.previousSibling, "Child2's previous sibling is Child1")
      assert_equal(@child2, @child3.previousSibling, "Child3's previous sibling is Child2")
      assert_nil(@child4.previousSibling, "Child4 does not have a previous sibling")
    end

    def test_add
      assert(!@root.hasChildren?, "Should not have any children")

      @root.add(@child1)

      @root << @child2

      assert(@root.hasChildren?, "Should have children")
      assert_equal(3, @root.size, "Should have three nodes")

      @root << @child3 << @child4

      assert_equal(5, @root.size, "Should have five nodes")
      assert_equal(2, @child3.size, "Should have two nodes")

      assert_raise(RuntimeError) { @root.add(Tree::TreeNode.new(@child1.name)) }

    end

    def test_remove_bang
      @root << @child1
      @root << @child2

      assert(@root.hasChildren?, "Should have children")
      assert_equal(3, @root.size, "Should have three nodes")

      @root.remove!(@child1)
      assert_equal(2, @root.size, "Should have two nodes")
      @root.remove!(@child2)

      assert(!@root.hasChildren?, "Should have no children")
      assert_equal(1, @root.size, "Should have one node")

      @root << @child1
      @root << @child2

      assert(@root.hasChildren?, "Should have children")
      assert_equal(3, @root.size, "Should have three nodes")

      @root.removeAll!

      assert(!@root.hasChildren?, "Should have no children")
      assert_equal(1, @root.size, "Should have one node")

    end

    def test_removeAll_bang
      loadChildren
      assert(@root.hasChildren?, "Should have children")
      @root.removeAll!

      assert(!@root.hasChildren?, "Should have no children")
      assert_equal(1, @root.size, "Should have one node")
    end

    def test_removeFromParent_bang
      loadChildren
      assert(@root.hasChildren?, "Should have children")
      assert(!@root.isLeaf?, "Root is not a leaf here")

      child1 = @root[0]
      assert_not_nil(child1, "Child 1 should exist")
      assert_same(@root, child1.root, "Child 1's root should be ROOT")
      assert(@root.include?(child1), "root should have child1")
      child1.removeFromParent!
      assert_same(child1, child1.root, "Child 1's root should be self")
      assert(!@root.include?(child1), "root should not have child1")

      child1.removeFromParent!
      assert_same(child1, child1.root, "Child 1's root should still be self")
    end

    def test_children
      loadChildren

      assert(@root.hasChildren?, "Should have children")
      assert_equal(5, @root.size, "Should have four nodes")
      assert(@child3.hasChildren?, "Should have children")
      assert(!@child3.isLeaf?, "Should not be a leaf")

      children = []
      for child in @root.children
        children << child
      end

      assert_equal(3, children.length, "Should have three direct children")
      assert(!children.include?(@root), "Should not have root")
      assert(children.include?(@child1), "Should have child 1")
      assert(children.include?(@child2), "Should have child 2")
      assert(children.include?(@child3), "Should have child 3")
      assert(!children.include?(@child4), "Should not have child 4")

      children.clear
      children = @root.children
      assert_equal(3, children.length, "Should have three children")

    end

    def test_firstChild
      loadChildren

      assert_equal(@child1, @root.firstChild, "Root's first child is Child1")
      assert_nil(@child1.firstChild, "Child1 does not have any children")
      assert_equal(@child4, @child3.firstChild, "Child3's first child is Child4")

    end

    def test_lastChild
      loadChildren

      assert_equal(@child3, @root.lastChild, "Root's last child is Child3")
      assert_nil(@child1.lastChild, "Child1 does not have any children")
      assert_equal(@child4, @child3.lastChild, "Child3's last child is Child4")

    end

    def test_find
      loadChildren
      foundNode = @root.find { |node| node == @child2}
      assert_same(@child2, foundNode, "The node should be Child 2")

      foundNode = @root.find { |node| node == @child4}
      assert_same(@child4, foundNode, "The node should be Child 4")

      foundNode = @root.find { |node| node.name == "Child31" }
      assert_same(@child4, foundNode, "The node should be Child 4")
      foundNode = @root.find { |node| node.name == "NOT PRESENT" }
      assert_nil(foundNode, "The node should not be found")
    end

    def test_parentage
      loadChildren

      assert_nil(@root.parentage, "Root does not have any parentage")
      assert_equal([@root], @child1.parentage, "Child1 has Root as its parent")
      assert_equal([@child3, @root], @child4.parentage, "Child4 has Child3 and Root as ancestors")
    end

    def test_each
      loadChildren
      assert(@root.hasChildren?, "Should have children")
      assert_equal(5, @root.size, "Should have five nodes")
      assert(@child3.hasChildren?, "Should have children")

      nodes = []
      @root.each { |node| nodes << node }

      assert_equal(5, nodes.length, "Should have FIVE NODES")
      assert(nodes.include?(@root), "Should have root")
      assert(nodes.include?(@child1), "Should have child 1")
      assert(nodes.include?(@child2), "Should have child 2")
      assert(nodes.include?(@child3), "Should have child 3")
      assert(nodes.include?(@child4), "Should have child 4")
    end

    def test_each_leaf
      loadChildren

      nodes = []
      @root.each_leaf { |node| nodes << node }

      assert_equal(3, nodes.length, "Should have THREE LEAF NODES")
      assert(!nodes.include?(@root), "Should not have root")
      assert(nodes.include?(@child1), "Should have child 1")
      assert(nodes.include?(@child2), "Should have child 2")
      assert(!nodes.include?(@child3), "Should not have child 3")
      assert(nodes.include?(@child4), "Should have child 4")
    end

    def test_parent
      loadChildren
      assert_nil(@root.parent, "Root's parent should be nil")
      assert_equal(@root, @child1.parent, "Parent should be root")
      assert_equal(@root, @child3.parent, "Parent should be root")
      assert_equal(@child3, @child4.parent, "Parent should be child3")
      assert_equal(@root, @child4.parent.parent, "Parent should be root")
    end

    def test_indexed_access
      loadChildren
      assert_equal(@child1, @root[0], "Should be the first child")
      assert_equal(@child4, @root[2][0], "Should be the grandchild")
      assert_nil(@root["TEST"], "Should be nil")
      assert_raise(RuntimeError) { @root[nil] }
    end

    def test_printTree
      loadChildren
      #puts
      #@root.printTree
    end

    # Tests the binary dumping mechanism with an Object content node
    def test_marshal_dump
      # Setup Test Data
      test_root = Tree::TreeNode.new("ROOT", "Root Node")
      test_content = {"KEY1" => "Value1", "KEY2" => "Value2" }
      test_child      = Tree::TreeNode.new("Child", test_content)
      test_content2 = ["AValue1", "AValue2", "AValue3"]
      test_grand_child = Tree::TreeNode.new("Grand Child 1", test_content2)
      test_root << test_child << test_grand_child

      # Perform the test operation
      data = Marshal.dump(test_root) # Marshal
      new_root = Marshal.load(data)  # And unmarshal

      # Test the root node
      assert_equal(test_root.name, new_root.name, "Must identify as ROOT")
      assert_equal(test_root.content, new_root.content, "Must have root's content")
      assert(new_root.isRoot?, "Must be the ROOT node")
      assert(new_root.hasChildren?, "Must have a child node")

      # Test the child node
      new_child = new_root[test_child.name]
      assert_equal(test_child.name, new_child.name, "Must have child 1")
      assert(new_child.hasContent?, "Child must have content")
      assert(new_child.isOnlyChild?, "Child must be the only child")

      new_child_content = new_child.content
      assert_equal(Hash, new_child_content.class, "Class of child's content should be a hash")
      assert_equal(test_child.content.size, new_child_content.size, "The content should have same size")

      # Test the grand-child node
      new_grand_child = new_child[test_grand_child.name]
      assert_equal(test_grand_child.name, new_grand_child.name, "Must have grand child")
      assert(new_grand_child.hasContent?, "Grand-child must have content")
      assert(new_grand_child.isOnlyChild?, "Grand-child must be the only child")

      new_grand_child_content = new_grand_child.content
      assert_equal(Array, new_grand_child_content.class, "Class of grand-child's content should be an Array")
      assert_equal(test_grand_child.content.size, new_grand_child_content.size, "The content should have same size")
    end

    # marshal_load and marshal_dump are symmetric methods
    # This alias is for satisfying ZenTest
    alias test_marshal_load test_marshal_dump

    # Test the collect method from the mixed-in Enumerable functionality.
    def test_collect
      loadChildren
      collectArray = @root.collect do |node|
        node.content = "abc"
        node
      end
      collectArray.each {|node| assert_equal("abc", node.content, "Should be 'abc'")}
    end

    # Test freezing the tree
    def test_freezeTree_bang
      loadChildren
      @root.content = "ABC"
      assert_equal("ABC", @root.content, "Content should be 'ABC'")
      @root.freezeTree!
      assert_raise(TypeError) {@root.content = "123"}
      assert_raise(TypeError) {@root[0].content = "123"}
    end

    # Test whether the content is accesible
    def test_content
      pers = Person::new("John", "Doe")
      @root.content = pers
      assert_same(pers, @root.content, "Content should be the same")
    end

    # Test the depth computation algorithm
    def test_depth
      assert_equal(1, @root.depth, "A single node's depth is 1")

      @root << @child1
      assert_equal(2, @root.depth, "This should be of depth 2")

      @root << @child2
      assert_equal(2, @root.depth, "This should be of depth 2")

      @child2 << @child3
      assert_equal(3, @root.depth, "This should be of depth 3")
      assert_equal(2, @child2.depth, "This should be of depth 2")

      @child3 << @child4
      assert_equal(4, @root.depth, "This should be of depth 4")
    end

    # Test the breadth computation algorithm
    def test_breadth
      assert_equal(1, @root.breadth, "A single node's breadth is 1")

      @root << @child1
      assert_equal(1, @root.breadth, "This should be of breadth 1")

      @root << @child2
      assert_equal(2, @child1.breadth, "This should be of breadth 2")
      assert_equal(2, @child2.breadth, "This should be of breadth 2")

      @root << @child3
      assert_equal(3, @child1.breadth, "This should be of breadth 3")
      assert_equal(3, @child2.breadth, "This should be of breadth 3")

      @child3 << @child4
      assert_equal(1, @child4.breadth, "This should be of breadth 1")
    end

    # Test the breadth for each
    def test_breadth_each
      j = Tree::TreeNode.new("j")
      f = Tree::TreeNode.new("f")
      k = Tree::TreeNode.new("k")
      a = Tree::TreeNode.new("a")
      d = Tree::TreeNode.new("d")
      h = Tree::TreeNode.new("h")
      z = Tree::TreeNode.new("z")

      # The expected order of response
      expected_array = [j,
                        f, k,
                        a, h, z,
                        d]

      # Create the following Tree
      #        j         <-- level 0 (Root)
      #      /   \
      #     f      k     <-- level 1
      #   /   \      \
      #  a     h      z  <-- level 2
      #   \
      #    d             <-- level 3
      j << f << a << d
      f << h
      j << k << z

      # Create the response
      result_array = Array.new
      j.breadth_each { |node| result_array << node.detached_copy }

      expected_array.each_index do |i|
        assert_equal(expected_array[i].name, result_array[i].name)      # Match only the names.
      end
    end


    def test_preordered_each
      j = Tree::TreeNode.new("j")
      f = Tree::TreeNode.new("f")
      k = Tree::TreeNode.new("k")
      a = Tree::TreeNode.new("a")
      d = Tree::TreeNode.new("d")
      h = Tree::TreeNode.new("h")
      z = Tree::TreeNode.new("z")

      # The expected order of response
      expected_array = [j, f, a, d, h, k, z]

      # Create the following Tree
      #        j         <-- level 0 (Root)
      #      /   \
      #     f      k     <-- level 1
      #   /   \      \
      #  a     h      z  <-- level 2
      #   \
      #    d             <-- level 3
      j << f << a << d
      f << h
      j << k << z

      result_array = []
      j.preordered_each { |node| result_array << node.detached_copy}

      expected_array.each_index do |i|
        # Match only the names.
        assert_equal(expected_array[i].name, result_array[i].name)
      end
    end

    def test_detached_copy
      loadChildren

      assert(@root.hasChildren?, "The root should have children")
      copy_of_root = @root.detached_copy
      assert(!copy_of_root.hasChildren?, "The copy should not have children")
      assert_equal(@root.name, copy_of_root.name, "The names should be equal")

      # Try the same test with a child node
      assert(!@child3.isRoot?, "Child 3 is not a root")
      assert(@child3.hasChildren?, "Child 3 has children")
      copy_of_child3 = @child3.detached_copy
      assert(copy_of_child3.isRoot?, "Child 3's copy is a root")
      assert(!copy_of_child3.hasChildren?, "Child 3's copy does not have children")
    end

    def test_hasChildren_eh
      loadChildren
      assert(@root.hasChildren?, "The Root node MUST have children")
    end

    def test_isLeaf_eh
      loadChildren
      assert(!@child3.isLeaf?, "Child 3 is not a leaf node")
      assert(@child4.isLeaf?, "Child 4 is a leaf node")
    end

    def test_isRoot_eh
      loadChildren
      assert(@root.isRoot?, "The ROOT node must respond as the root node")
    end

    def test_content_equals
      @root.content = nil
      assert_nil(@root.content, "Root's content should be nil")
      @root.content = "ABCD"
      assert_equal("ABCD", @root.content, "Root's content should now be 'ABCD'")
    end

    def test_size
      assert_equal(1, @root.size, "Root's size should be 1")
      loadChildren
      assert_equal(5, @root.size, "Root's size should be 5")
      assert_equal(2, @child3.size, "Child 3's size should be 2")
    end

    def test_lt2                # Test the << method
      @root << @child1
      @root << @child2
      @root << @child3 << @child4
      assert_not_nil(@root['Child1'], "Child 1 should have been added to Root")
      assert_not_nil(@root['Child2'], "Child 2 should have been added to Root")
      assert_not_nil(@root['Child3'], "Child 3 should have been added to Root")
      assert_not_nil(@child3['Child31'], "Child 31 should have been added to Child3")
    end

    def test_index              #  Test the [] method
      assert_raise(RuntimeError) {@root[nil]}

      @root << @child1
      @root << @child2
      assert_equal(@child1.name, @root['Child1'].name, "Child 1 should be returned")
      assert_equal(@child1.name, @root[0].name, "Child 1 should be returned")
      assert_equal(@child2.name, @root['Child2'].name, "Child 2 should be returned")
      assert_equal(@child2.name, @root[1].name, "Child 2 should be returned")

      assert_nil(@root['Some Random Name'], "Should return nil")
      assert_nil(@root[99], "Should return nil")
    end
  end
end

__END__

# $Log: test_tree.rb,v $
# Revision 1.6  2007/12/22 00:28:59  anupamsg
# Added more test cases, and enabled ZenTest compatibility.
#
# Revision 1.5  2007/12/19 02:24:18  anupamsg
# Updated the marshalling logic to handle non-string contents on the nodes.
#
# Revision 1.4  2007/10/02 03:38:11  anupamsg
# Removed dependency on the redundant "Person" class.
# (TC_TreeTest::test_comparator): Added a new test for the spaceship operator.
# (TC_TreeTest::test_hasContent): Added tests for hasContent? and length methods.
#
# Revision 1.3  2007/10/02 03:07:30  anupamsg
# * Rakefile: Added an optional task for rcov code coverage.
#
# * test/test_binarytree.rb: Removed the unnecessary dependency on "Person" class.
#
# * test/test_tree.rb: Removed dependency on the redundant "Person" class.
#
# Revision 1.2  2007/08/31 01:16:28  anupamsg
# Added breadth and pre-order traversals for the tree. Also added a method
# to return the detached copy of a node from the tree.
#
# Revision 1.1  2007/07/21 04:52:38  anupamsg
# Renamed the test files.
#
# Revision 1.13  2007/07/18 22:11:50  anupamsg
# Added depth and breadth methods for the TreeNode.
#
# Revision 1.12  2007/07/18 07:17:34  anupamsg
# Fixed a  issue where TreeNode.ancestors was shadowing Module.ancestors. This method
# has been renamed to TreeNode.parentage.
#
# Revision 1.11  2007/07/17 03:39:29  anupamsg
# Moved the CVS Log keyword to end of the files.
#
