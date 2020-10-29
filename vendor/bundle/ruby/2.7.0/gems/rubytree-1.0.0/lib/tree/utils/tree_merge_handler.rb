#!/usr/bin/env ruby
#
# tree_merge_handler.rb
#
# Author:  Anupam Sengupta
# Time-stamp: <2015-05-30 16:06:18 anupam>
#
# Copyright (C) 2013, 2015 Anupam Sengupta (anupamsg@gmail.com)
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

require_relative '../../../lib/tree/utils/utils'

# Provides utility methods to merge two {Tree::TreeNode} based trees.
# @since 0.9.0
module Tree::Utils::TreeMergeHandler

  # @!group Merging Trees

  # Merge two trees that share the same root node and returns <em>a new
  # tree</em>.
  #
  # The new tree contains the contents of the merge between _other_tree_ and
  # self. Duplicate nodes (coming from _other_tree_) will *NOT* be overwritten
  # in self.
  #
  # @author Darren Oakley (https://github.com/dazoakley)
  #
  # @param [Tree::TreeNode] other_tree The other tree to merge with.
  # @return [Tree::TreeNode] the resulting tree following the merge.
  #
  # @raise [TypeError] This exception is raised if _other_tree_ is not a
  #                    {Tree::TreeNode}.
  #
  # @raise [ArgumentError] This exception is raised if _other_tree_ does not
  #                        have the same root node as self.
  def merge(other_tree)
    check_merge_prerequisites(other_tree)
    merge_trees(self.root.dup, other_tree.root)
  end

  # Merge in another tree (that shares the same root node) into +this+ tree.
  # Duplicate nodes (coming from _other_tree_) will NOT be overwritten in
  # self.
  #
  # @author Darren Oakley (https://github.com/dazoakley)
  #
  # @param [Tree::TreeNode] other_tree The other tree to merge with.
  #
  # @raise [TypeError] This exception is raised if _other_tree_ is not a
  #                    {Tree::TreeNode}.
  #
  # @raise [ArgumentError] This exception is raised if _other_tree_ does not
  #                        have the same root node as self.
  def merge!(other_tree)
    check_merge_prerequisites( other_tree )
    merge_trees( self.root, other_tree.root )
  end

  private

  # Utility function to check that the conditions for a tree merge are met.
  #
  # @author Darren Oakley (https://github.com/dazoakley)
  #
  # @see #merge
  # @see #merge!
  def check_merge_prerequisites(other_tree)
    unless other_tree.is_a?(Tree::TreeNode)
      raise TypeError,
            'You can only merge in another instance of Tree::TreeNode'
    end

    unless self.root.name == other_tree.root.name
      raise ArgumentError,
            'Unable to merge trees as they do not share the same root'
    end
  end

  # Utility function to recursively merge two subtrees.
  #
  # @author Darren Oakley (https://github.com/dazoakley)
  #
  # @param [Tree::TreeNode] tree1 The target tree to merge into.
  # @param [Tree::TreeNode] tree2 The donor tree (that will be merged
  #                               into target).
  # @raise [Tree::TreeNode] The merged tree.
  def merge_trees(tree1, tree2)
    names1 = tree1.has_children? ? tree1.children.map { |child| child.name } : []
    names2 = tree2.has_children? ? tree2.children.map { |child| child.name } : []

    names_to_merge = names2 - names1
    names_to_merge.each do |name|
      tree1 << tree2[name].detached_subtree_copy
    end

    tree1.children.each do |child|
      merge_trees( child, tree2[child.name] ) unless tree2[child.name].nil?
    end

    tree1
  end

end
