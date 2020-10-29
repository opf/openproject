# metrics_methods.rb - This file is part of the RubyTree package.
#
# = metrics_methods.rb - Provides methods for various tree measurements
#
# Author::  Anupam Sengupta (anupamsg@gmail.com)
#
# Time-stamp: <2017-12-21 12:49:25 anupam>
#
# Copyright (C) 2013, 2015, 2017 Anupam Sengupta <anupamsg@gmail.com>
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

require_relative '../../../lib/tree'
require 'structured_warnings'

module Tree::Utils
  # Provides utility functions to measure various tree metrics.
  module TreeMetricsHandler
    # noinspection RubyUnusedLocalVariable
    def self.included(base)

      # @!group Metrics and Measures

      # @!attribute [r] size
      # Total number of nodes in this (sub)tree, including this node.
      #
      # Size of the tree is defined as:
      #
      # Size:: Total number nodes in the subtree including this node.
      #
      # @return [Integer] Total number of nodes in this (sub)tree.
      def size
        inject(0) {|sum, node| sum + 1 if node}
      end

      # @!attribute [r] length
      # Convenience synonym for {#size}.
      #
      # @deprecated This method name is ambiguous and may be removed. Use
      # {#size} instead.
      #
      # @return [Integer] The total number of nodes in this (sub)tree.
      # @see #size
      def length
        self.size
      end

      # @!attribute [r] node_height
      # Height of the (sub)tree from this node.  Height of a node is defined as:
      #
      # Height:: Length of the longest downward path to a leaf from the node.
      #
      # - Height from a root node is height of the entire tree.
      # - The height of a leaf node is zero.
      #
      # @return [Integer] Height of the node.
      def node_height
        return 0 if is_leaf?
        1 + @children.collect { |child| child.node_height }.max
      end

      # @!attribute [r] node_depth
      # Depth of this node in its tree.  Depth of a node is defined as:
      #
      # Depth:: Length of the node's path to its root. Depth of a root node is
      # zero.
      #
      # *Note* that the deprecated method {#depth} was incorrectly computing
      # this value. Please replace all calls to the old method with
      # {#node_depth} instead.
      #
      # {#level} is an alias for this method.
      #
      # @return [Integer] Depth of this node.
      def node_depth
        return 0 if is_root?
        1 + parent.node_depth
      end

      # @!attribute [r] level
      # Alias for {#node_depth}
      #
      # @see #node_depth
      def level
        node_depth
      end

      # @!attribute [r] depth
      # Depth of the tree from this node. A single leaf node has a depth of 1.
      #
      # This method is *DEPRECATED* and may be removed in the subsequent
      # releases. Note that the value returned by this method is actually the:
      #
      # _height_ + 1 of the node, *NOT* the _depth_.
      #
      # For correct and conventional behavior, please use {#node_depth} and
      # {#node_height} methods instead.
      #
      # @return [Integer] depth of the node.
      #
      # @deprecated This method returns an incorrect value. Use the
      # {#node_depth} method instead.
      #
      # @see #node_depth
      def depth
        warn StructuredWarnings::DeprecatedMethodWarning,
             'This method is deprecated.  '\
             'Please use node_depth() or node_height() instead (bug # 22535)'

        return 1 if is_leaf?
        1 + @children.collect { |child| child.depth }.max
      end

      # @!attribute [r] breadth
      # Breadth of the tree at this node's level.
      # A single node without siblings has a breadth of 1.
      #
      # Breadth is defined to be:
      # Breadth:: Number of sibling nodes to this node + 1 (this node itself),
      # i.e., the number of children the parent of this node has.
      #
      # @return [Integer] breadth of the node's level.
      def breadth
        is_root? ? 1 : parent.children.size
      end

      # @!attribute [r] in_degree
      # The incoming edge-count of this node.
      #
      # In-degree is defined as:
      # In-degree:: Number of edges arriving at the node (0 for root, 1 for
      # all other nodes)
      #
      # - In-degree = 0 for a root or orphaned node
      # - In-degree = 1 for a node which has a parent
      #
      # @return [Integer] The in-degree of this node.
      def in_degree
        is_root? ? 0 : 1
      end

      # @!attribute [r] out_degree
      # The outgoing edge-count of this node.
      #
      # Out-degree is defined as:
      # Out-degree:: Number of edges leaving the node (zero for leafs)
      #
      # @return [Integer] The out-degree of this node.
      def out_degree
        is_leaf? ? 0 : children.size
      end

      # @!endgroup
    end # self.included
  end
end
