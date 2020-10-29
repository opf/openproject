# binarytree.rb - This file is part of the RubyTree package.
#
# = binarytree.rb - An implementation of the binary tree data structure.
#
# Provides a binary tree data structure with ability to
# store two node elements as children at each node in the tree.
#
# Author:: Anupam Sengupta (anupamsg@gmail.com)
#

# Copyright (c) 2007, 2008, 2009, 2010, 2012, 2013, 2014, 2015 Anupam Sengupta
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# - Neither the name of the organization nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require_relative '../tree'

module Tree

  # Provides a Binary tree implementation. This node allows only two child nodes
  # (left and right child). It also provides direct access to the left or right
  # child, including assignment to the same.
  #
  # This inherits from the {Tree::TreeNode} class.
  #
  # @author Anupam Sengupta
  #
  class BinaryTreeNode < TreeNode

    # @!group Core Attributes

    # @!attribute [rw] left_child
    # Left child of the receiver node. Note that left Child == first Child.
    #
    # @return [Tree::BinaryTreeNode] The left most (or first) child.
    #
    # @see #right_child
    def left_child
      children.first
    end

    # @!attribute [rw] right_child
    # Right child of the receiver node. Note that right child == last child
    # unless there is only one child.
    #
    # Returns +nil+ if the right child does not exist.
    #
    # @return [Tree::BinaryTreeNode] The right child, or +nil+ if the right side
    #                                child does not exist.
    #
    # @see #left_child
    def right_child
      children[1]
    end

    # @!attribute is_left_child?
    # +true+ if the receiver node is the left child of its parent.
    # Always returns +false+ if it is a root node.
    #
    # @return [Boolean] +true+ if this is the left child of its parent.
    def is_left_child?
      return false if is_root?
      self == parent.left_child
    end

    # @!attribute [r] is_right_child?
    # +true+ if the receiver node is the right child of its parent.
    # Always returns +false+ if it is a root node.
    #
    # @return [Boolean] +true+ if this is the right child of its parent.
    def is_right_child?
      return false if is_root?
      self == parent.right_child
    end

    # @!group Structure Modification

    # Adds the specified child node to the receiver node. The child node's
    # parent is set to be the receiver.
    #
    # The child nodes are added in the order of addition, i.e., the first child
    # added becomes the left node, and the second child added will be the second
    # node.
    #
    # If only one child is present, then this will be the left child.
    #
    # @param [Tree::BinaryTreeNode] child The child to add.
    #
    # @raise [ArgumentError] This exception is raised if two children are
    #                        already present.
    def add(child)
      raise ArgumentError, 'Already has two child nodes' if @children.size == 2

      super(child)
    end


    # Instantiate and insert child nodes from data in a Ruby +Hash+
    #
    # This method is used in conjunction with {Tree::TreeNode.from_hash} to
    # provide a convenient way of building and inserting child nodes present
    # in a Ruby hashes.
    #
    # This method will instantiate a {Tree::TreeNode} instance for each top-
    # level key of the input hash, to be inserted as children of the receiver
    # instance.
    #
    # Nested hashes are expected and further child nodes will be created and
    # added accordingly. If a hash key is a single value that value will be
    # used as the name for the node.  If a hash key is an Array, both node
    # name and content will be populated.
    #
    # A leaf element of the tree should be represented as a hash key with
    # corresponding value nil or {}.
    #
    # @example
    #   root = Tree::TreeNode.new(:A, "Root content!")
    #   root.add_from_hash({:B => {:D => {}}, [:C, "C content!"] => {}})
    #
    # @param [Hash] hashed_subtree The hash of child subtrees.
    #
    # @raise [ArgumentError] This exception is raised if hash contains too
    #                        many children.
    # =>
    # @raise [ArgumentError] This exception is raised if a non-hash is passed.
    # @return [Array] Array of child nodes added
    def add_from_hash(hashed_subtree)
      raise ArgumentError, 'Too many children'\
                           if hashed_subtree.size + @children.size > 2
      super(hashed_subtree)
    end

    # Performs in-order traversal (including this node).
    #
    # @yieldparam node [Tree::BinaryTreeNode]  Each node (in-order).
    #
    # @return [Tree::BinaryTreeNode] This node, if a block is given
    # @return [Enumerator] An enumerator on this tree, if a block is *not* given
    #
    # @since 0.9.0
    #
    # @param [Object] block
    #
    # @see #each
    # @see #preordered_each
    # @see #postordered_each
    # noinspection RubyUnusedLocalVariable
    def inordered_each(&block)

      return self.to_enum unless block_given?

      node_stack = []
      current_node = self

      until node_stack.empty? and current_node == nil
        if current_node
          node_stack.push(current_node)
          current_node = current_node.left_child
        else
          current_node = node_stack.pop
          yield current_node
          current_node = current_node.right_child
        end
      end

      self if block_given?

    end

    # A protected method to allow insertion of child nodes at the specified
    # location. Note that this method allows insertion of +nil+ nodes.
    #
    # @param [Tree::BinaryTreeNode] child The child to add at the specified
    #                                     location.
    #
    # @param [Integer] at_index The location to add the entry at (0 or 1).
    #
    # @return [Tree::BinaryTreeNode] The added child.
    #
    # @raise [ArgumentError] If the index is out of limits.
    def set_child_at(child, at_index)
      raise ArgumentError 'A binary tree cannot have more than two children.'\
                          unless (0..1).include? at_index

      @children[at_index]        = child
      @children_hash[child.name] = child if child # Assign the name mapping
      child.parent               = self if child
      child
    end

    protected :set_child_at

    # Sets the left child of the receiver node. If a previous child existed, it
    # is replaced.
    #
    # @param [Tree::BinaryTreeNode] child The child to add as the left-side
    #                                     node.
    #
    # @return [Tree::BinaryTreeNode] The assigned child node.
    #
    # @see #left_child
    # @see #right_child=
    def left_child=(child)
      set_child_at child, 0
    end

    # Sets the right child of the receiver node. If a previous child existed, it
    # is replaced.
    #
    # @param [Tree::BinaryTreeNode] child The child to add as the right-side
    #                                     node.
    #
    # @return [Tree::BinaryTreeNode] The assigned child node.
    #
    # @see #right_child
    # @see #left_child=
    def right_child=(child)
      set_child_at child, 1
    end

    # Swaps the left and right child nodes of the receiver node with each other.
    def swap_children
      self.left_child, self.right_child = self.right_child, self.left_child
    end

  end

end
