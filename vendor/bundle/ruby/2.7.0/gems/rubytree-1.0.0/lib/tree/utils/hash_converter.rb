# hash_converter.rb - This file is part of the RubyTree package.
#
# = hash_converter.rb - Provides utility methods for converting between
#   {Tree::TreeNode} and Ruby's native +Hash+.
#
# Author::  Jen Hamon (http://www.github.com/jhamon)
#
# Time-stamp: <2015-05-30 14:19:16 anupam>
#
# Copyright (C) 2014, 2015 Jen Hamon (http://www.github.com/jhamon) and
#                    Anupam Sengupta <anupamsg@gmail.com>
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

require_relative '../../../lib/tree/utils/utils'

module Tree::Utils::HashConverter

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Methods in {Tree::Utils::HashConverter::ClassMethods} will be added as
  # class methods on any class mixing in the {Tree::Utils::HashConverter}
  # module.
  module ClassMethods

    # Factory method builds a {Tree::TreeNode} from a +Hash+.
    #
    # This method will interpret each key of your +Hash+ as a {Tree::TreeNode}.
    # Nested hashes are expected and child nodes will be added accordingly. If
    # a hash key is a single value that value will be used as the name for the
    # node.  If a hash key is an Array, both node name and content will be
    # populated.
    #
    # A leaf element of the tree should be represented as a hash key with
    # corresponding value +nil+ or +{}+.
    #
    # @example
    #   TreeNode.from_hash({:A => {:B => {}, :C => {:D => {}, :E => {}}}})
    #   # would be parsed into the following tree structure:
    #   #    A
    #   #   / \
    #   #  B   C
    #   #     / \
    #   #    D   E
    #
    #   # The same tree would result from this nil-terminated Hash
    #   {:A => {:B => nil, :C => {:D => nil, :E => nil}}}
    #
    #   # A tree with equivalent structure but with content present for
    #   # nodes A and D could be built from a hash like this:
    #   {[:A, "A content"] => {:B => {},
    #                          :C => { [:D, "D content"] => {},
    #                                   :E => {}  }}}
    #
    # @author Jen Hamon (http://www.github.com/jhamon)
    # @param [Hash] hash Hash to build tree from.
    #
    # @return [Tree::TreeNode] The {Tree::TreeNode} instance representing the
    #                          root of your tree.
    #
    # @raise [ArgumentError] This exception is raised if a non-Hash is passed.
    #
    # @raise [ArgumentError] This exception is raised if the hash has multiple
    #                        top-level elements.
    #
    # @raise [ArgumentError] This exception is raised if the hash contains
    #                        values that are not hashes or nils.

    def from_hash(hash)
      raise ArgumentError, 'Argument must be a type of hash'\
                           unless hash.is_a?(Hash)

      raise ArgumentError, 'Hash must have one top-level element'\
                           if hash.size != 1

      root, children = hash.first

      unless [Hash, NilClass].include?(children.class)
        raise ArgumentError, 'Invalid child. Must be nil or hash.'
      end

      node = self.new(*root)
      node.add_from_hash(children) unless children.nil?
      node
    end
  end

    # Instantiate and insert child nodes from data in a Ruby +Hash+
    #
    # This method is used in conjunction with from_hash to provide a
    # convenient way of building and inserting child nodes present in a Ruby
    # hashes.
    #
    # This method will instantiate a node instance for each top-
    # level key of the input hash, to be inserted as children of the receiver
    # instance.
    #
    # Nested hashes are expected and further child nodes will be created and
    # added accordingly. If a hash key is a single value that value will be
    # used as the name for the node.  If a hash key is an Array, both node
    # name and content will be populated.
    #
    # A leaf element of the tree should be represented as a hash key with
    # corresponding value +nil+ or {}.
    #
    # @example
    #   root = Tree::TreeNode.new(:A, "Root content!")
    #   root.add_from_hash({:B => {:D => {}}, [:C, "C content!"] => {}})
    #
    # @author Jen Hamon (http://www.github.com/jhamon)
    # @param [Hash] children The hash of child subtrees.
    # @raise [ArgumentError] This exception is raised if a non-hash is passed.
    # @return [Array] Array of child nodes added
    # @see ClassMethods#from_hash
    def add_from_hash(children)
      raise ArgumentError, 'Argument must be a type of hash'\
                           unless children.is_a?(Hash)

      child_nodes = []
      children.each do |child, grandchildren|
        child_node = self.class.from_hash({child => grandchildren})
        child_nodes << child_node
        self << child_node
      end

      child_nodes
    end

    # Convert a node and its subtree into a Ruby hash.
    #
    # @example
    #    root = Tree::TreeNode.new(:root, "root content")
    #    root << Tree::TreeNode.new(:child1, "child1 content")
    #    root << Tree::TreeNode.new(:child2, "child2 content")
    #    root.to_h # => {[:root, "root content"] =>
    #                         { [:child1, "child1 content"] =>
    #                                    {}, [:child2, "child2 content"] => {}}}
    # @author Jen Hamon (http://www.github.com/jhamon)
    # @return [Hash] Hash representation of tree.
    def to_h
      key = has_content? ? [name, content] : name

      children_hash = {}
      children do |child|
        children_hash.merge! child.to_h
      end

      { key => children_hash }
    end
end
