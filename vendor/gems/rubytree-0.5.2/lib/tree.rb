# tree.rb
#
# $Revision: 1.29 $ by $Author: anupamsg $
# $Name:  $
#
# = tree.rb - Generic Multi-way Tree implementation
#
# Provides a generic tree data structure with ability to
# store keyed node elements in the tree. The implementation
# mixes in the Enumerable module.
#
# Author:: Anupam Sengupta (anupamsg@gmail.com)
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

# This module provides a TreeNode class which is the primary class for all
# nodes represented in the Tree.
# This module mixes in the Enumerable module.
module Tree

  # Rubytree Package Version
  VERSION = '0.5.2'

  # == TreeNode Class Description
  #
  # The node class for the tree representation. the nodes are named and have a
  # place-holder for the node data (i.e., the `content' of the node). The node
  # names are expected to be unique.  In addition, the node provides navigation
  # methods to traverse the tree.
  #
  # The nodes can have any number of child nodes attached to it. Note that while
  # this implementation does not support directed graphs, the class itself makes
  # no restrictions on associating a node's CONTENT with multiple parent nodes.
  #
  #
  # == Example
  #
  #  The following code-snippet implements this tree structure:
  #
  #                    +------------+
  #                    |    ROOT    |
  #                    +-----+------+
  #            +-------------+------------+
  #            |                          |
  #    +-------+-------+          +-------+-------+
  #    |  CHILD 1      |          |  CHILD 2      |
  #    +-------+-------+          +---------------+
  #            |
  #            |
  #    +-------+-------+
  #    | GRANDCHILD 1  |
  #    +---------------+
  #
  # require 'tree'
  #
  # myTreeRoot = Tree::TreeNode.new("ROOT", "Root Content")
  #
  # myTreeRoot << Tree::TreeNode.new("CHILD1", "Child1 Content") << Tree::TreeNode.new("GRANDCHILD1", "GrandChild1 Content")
  #
  # myTreeRoot << Tree::TreeNode.new("CHILD2", "Child2 Content")
  #
  # myTreeRoot.printTree
  #
  # child1 = myTreeRoot["CHILD1"]
  #
  # grandChild1 = myTreeRoot["CHILD1"]["GRANDCHILD1"]
  #
  # siblingsOfChild1Array = child1.siblings
  #
  # immediateChildrenArray = myTreeRoot.children
  #
  # # Process all nodes
  #
  # myTreeRoot.each { |node| node.content.reverse }
  #
  # myTreeRoot.remove!(child1) # Remove the child
  class TreeNode
    include Enumerable

    attr_reader :content, :name, :parent
    attr_writer :content

    # Constructor which expects the name of the node
    #
    # Name of the node is expected to be unique across the
    # tree.
    #
    # The content can be of any type, and is defaulted to _nil_.
    def initialize(name, content = nil)
      raise "Node name HAS to be provided" if name == nil
      @name = name
      @content = content
      self.setAsRoot!

      @childrenHash = Hash.new
      @children = []
    end

    # Returns a copy of this node, with the parent and children links removed.
    def detached_copy
      Tree::TreeNode.new(@name, @content ? @content.clone : nil)
    end

    # Print the string representation of this node.
    def to_s
      "Node Name: #{@name}" +
        " Content: " + (@content || "<Empty>") +
        " Parent: " + (isRoot?()  ? "<None>" : @parent.name) +
        " Children: #{@children.length}" +
        " Total Nodes: #{size()}"
    end

    # Returns an array of ancestors in reversed order (the first element is the
    # immediate parent). Returns nil if this is a root node.
    def parentage
      return nil if isRoot?

      parentageArray = []
      prevParent = self.parent
      while (prevParent)
        parentageArray << prevParent
        prevParent = prevParent.parent
      end

      parentageArray
    end

    # Protected method to set the parent node.
    # This method should NOT be invoked by client code.
    def parent=(parent)
      @parent = parent
    end

    # Convenience synonym for TreeNode#add method.  This method allows a convenient
    # method to add children hierarchies in the tree.
    #
    # E.g. root << child << grand_child
    def <<(child)
      add(child)
    end

    # Adds the specified child node to the receiver node.  The child node's
    # parent is set to be the receiver.  The child is added as the last child in
    # the current list of children for the receiver node.
    def add(child)
      raise "Child already added" if @childrenHash.has_key?(child.name)

      @childrenHash[child.name]  = child
      @children << child
      child.parent = self
      return child

    end

    # Removes the specified child node from the receiver node.  The removed
    # children nodes are orphaned but available if an alternate reference
    # exists.
    #
    # Returns the child node.
    def remove!(child)
      @childrenHash.delete(child.name)
      @children.delete(child)
      child.setAsRoot! unless child == nil
      return child
    end

    # Removes this node from its parent. If this is the root node, then does
    # nothing.
    def removeFromParent!
      @parent.remove!(self) unless isRoot?
    end

    # Removes all children from the receiver node.
    def removeAll!
      for child in @children
        child.setAsRoot!
      end
      @childrenHash.clear
      @children.clear
      self
    end

    # Indicates whether this node has any associated content.
    def hasContent?
      @content != nil
    end

    # Protected method which sets this node as a root node.
    def setAsRoot!
      @parent = nil
    end

    # Indicates whether this node is a root node. Note that
    # orphaned children will also be reported as root nodes.
    def isRoot?
      @parent == nil
    end

    # Indicates whether this node has any immediate child nodes.
    def hasChildren?
      @children.length != 0
    end

    # Indicates whether this node is a 'leaf' - i.e., one without
    # any children
    def isLeaf?
      !hasChildren?
    end

    # Returns an array of all the immediate children.  If a block is given,
    # yields each child node to the block.
    def children
      if block_given?
        @children.each {|child| yield child}
      else
        @children
      end
    end

    # Returns the first child of this node. Will return nil if no children are
    # present.
    def firstChild
      children.first
    end

    # Returns the last child of this node. Will return nil if no children are
    # present.
    def lastChild
      children.last
    end

    # Returns every node (including the receiver node) from the tree to the
    # specified block. The traversal is depth first and from left to right in
    # pre-ordered sequence.
    def each &block
      yield self
      children { |child| child.each(&block) }
    end

    # Traverses the tree in a pre-ordered sequence. This is equivalent to
    # TreeNode#each
    def preordered_each &block
      each(&block)
    end

    # Performs breadth first traversal of the tree rooted at this node. The
    # traversal in a given level is from left to right.
    def breadth_each &block
      node_queue = [self]       # Create a queue with self as the initial entry

      # Use a queue to do breadth traversal
      until node_queue.empty?
        node_to_traverse = node_queue.shift
        yield node_to_traverse
        # Enqueue the children from left to right.
        node_to_traverse.children { |child| node_queue.push child }
      end
    end

    # Yields all leaf nodes from this node to the specified block. May yield
    # this node as well if this is a leaf node.  Leaf traversal depth first and
    # left to right.
    def each_leaf &block
      self.each { |node| yield(node) if node.isLeaf? }
    end

    # Returns the requested node from the set of immediate children.
    #
    # If the parameter is _numeric_, then the in-sequence array of children is
    # accessed (see Tree#children).  If the parameter is not _numeric_, then it
    # is assumed to be the *name* of the child node to be returned.
    def [](name_or_index)
      raise "Name_or_index needs to be provided" if name_or_index == nil

      if name_or_index.kind_of?(Integer)
        @children[name_or_index]
      else
        @childrenHash[name_or_index]
      end
    end

    # Returns the total number of nodes in this tree, rooted at the receiver
    # node.
    def size
      @children.inject(1) {|sum, node| sum + node.size}
    end

    # Convenience synonym for Tree#size
    def length
      size()
    end

    # Pretty prints the tree starting with the receiver node.
    def printTree(level = 0)

      if isRoot?
        print "*"
      else
        print "|" unless parent.isLastSibling?
        print(' ' * (level - 1) * 4)
        print(isLastSibling? ? "+" : "|")
        print "---"
        print(hasChildren? ? "+" : ">")
      end

      puts " #{name}"

      children { |child| child.printTree(level + 1)}
    end

    # Returns the root for this tree. Root's root is itself.
    def root
      root = self
      root = root.parent while !root.isRoot?
      root
    end

    # Returns the first sibling for this node. If this is the root node, returns
    # itself.
    def firstSibling
      if isRoot?
        self
      else
        parent.children.first
      end
    end

    # Returns true if this node is the first sibling.
    def isFirstSibling?
      firstSibling == self
    end

    # Returns the last sibling for this node.  If this node is the root, returns
    # itself.
    def lastSibling
      if isRoot?
        self
      else
        parent.children.last
      end
    end

    # Returns true if his node is the last sibling
    def isLastSibling?
      lastSibling == self
    end

    # Returns an array of siblings for this node.
    # If a block is provided, yields each of the sibling
    # nodes to the block. The root always has nil siblings.
    def siblings
      return nil if isRoot?
      if block_given?
        for sibling in parent.children
          yield sibling if sibling != self
        end
      else
        siblings = []
        parent.children {|sibling| siblings << sibling if sibling != self}
        siblings
      end
    end

    # Returns true if this node is the only child of its parent
    def isOnlyChild?
      parent.children.size == 1
    end

    # Returns the next sibling for this node. Will return nil if no subsequent
    # node is present.
    def nextSibling
      if myidx = parent.children.index(self)
        parent.children.at(myidx + 1)
      end
    end

    # Returns the previous sibling for this node. Will return nil if no
    # subsequent node is present.
    def previousSibling
      if myidx = parent.children.index(self)
        parent.children.at(myidx - 1) if myidx > 0
      end
    end

    # Provides a comparision operation for the nodes. Comparision
    # is based on the natural character-set ordering for the
    # node names.
    def <=>(other)
      return +1 if other == nil
      self.name <=> other.name
    end

    # Freezes all nodes in the tree
    def freezeTree!
      each {|node| node.freeze}
    end

    # Creates the marshal-dump represention of the tree rooted at this node.
    def marshal_dump
      self.collect { |node| node.createDumpRep }
    end

    # Creates a dump representation and returns the same as a hash.
    def createDumpRep
      { :name => @name, :parent => (isRoot? ? nil : @parent.name),  :content => Marshal.dump(@content)}
    end

    # Loads a marshalled dump of the tree and returns the root node of the
    # reconstructed tree. See the Marshal class for additional details.
    def marshal_load(dumped_tree_array)
      nodes = { }
      for node_hash in dumped_tree_array do
        name        = node_hash[:name]
        parent_name = node_hash[:parent]
        content     = Marshal.load(node_hash[:content])

        if parent_name then
          nodes[name] = current_node = Tree::TreeNode.new(name, content)
          nodes[parent_name].add current_node
        else
          # This is the root node, hence initialize self.
          initialize(name, content)

          nodes[name] = self    # Add self to the list of nodes
         end
      end
    end

    # Returns depth of the tree from this node. A single leaf node has a
    # depth of 1.
    def depth
      return 1 if isLeaf?
      1 + @children.collect { |child| child.depth }.max
    end

    # Returns breadth of the tree at this node level. A single node has a
    # breadth of 1.
    def breadth
      return 1 if isRoot?
      parent.children.size
    end

    protected :parent=, :setAsRoot!, :createDumpRep

  end
end

# $Log: tree.rb,v $
# Revision 1.29  2007/12/22 00:28:59  anupamsg
# Added more test cases, and enabled ZenTest compatibility.
#
# Revision 1.28  2007/12/20 03:19:33  anupamsg
# * README (Module): Modified the install instructions from source.
# (Module): Updated the minor version number.
#
# Revision 1.27  2007/12/20 03:00:03  anupamsg
# Minor code changes. Removed self_initialize from the protected methods' list.
#
# Revision 1.26  2007/12/20 02:50:04  anupamsg
# (Tree::TreeNode): Removed the spurious self_initialize from the protected list.
#
# Revision 1.25  2007/12/19 20:28:05  anupamsg
# Removed the unnecesary self_initialize method.
#
# Revision 1.24  2007/12/19 06:39:17  anupamsg
# Removed the unnecessary field and record separator constants.  Also updated the
# history.txt file.
#
# Revision 1.23  2007/12/19 06:25:00  anupamsg
# (Tree::TreeNode): Minor fix to the comments.  Also fixed the private/protected
# scope issue with the createDumpRep method.
#
# Revision 1.22  2007/12/19 06:22:03  anupamsg
# Updated the marshalling logic to correctly handle non-string content. This
# should fix the bug # 15614 ("When dumping with an Object as the content, you get
# a delimiter collision")
#
# Revision 1.21  2007/12/19 02:24:17  anupamsg
# Updated the marshalling logic to handle non-string contents on the nodes.
#
# Revision 1.20  2007/10/10 08:42:57  anupamsg
# Release 0.4.3
#
# Revision 1.19  2007/08/31 01:16:27  anupamsg
# Added breadth and pre-order traversals for the tree. Also added a method
# to return the detached copy of a node from the tree.
#
# Revision 1.18  2007/07/21 05:14:44  anupamsg
# Added a VERSION constant to the Tree module,
# and using the same in the Rakefile.
#
# Revision 1.17  2007/07/21 03:24:25  anupamsg
# Minor edits to parameter names. User visible functionality does not change.
#
# Revision 1.16  2007/07/18 23:38:55  anupamsg
# Minor updates to tree.rb
#
# Revision 1.15  2007/07/18 22:11:50  anupamsg
# Added depth and breadth methods for the TreeNode.
#
# Revision 1.14  2007/07/18 19:33:27  anupamsg
# Added a new binary tree implementation.
#
# Revision 1.13  2007/07/18 07:17:34  anupamsg
# Fixed a  issue where TreeNode.ancestors was shadowing Module.ancestors. This method
# has been renamed to TreeNode.parentage.
#
# Revision 1.12  2007/07/17 03:39:28  anupamsg
# Moved the CVS Log keyword to end of the files.
#
