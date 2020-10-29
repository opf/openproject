#!/usr/bin/env ruby

# test_thread_and_fiber.rb - This file is part of the RubyTree package.
#
# Copyright (c) 2012, 2013 Anupam Sengupta
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
require 'json'
require_relative '../lib/tree'

module TestTree
  # Test class for the Tree node.
  class TestFiberAndThreadOnNode < Test::Unit::TestCase

    # Test long and unbalanced trees
    def create_long_depth_trees(depth=100)
      tree = Tree::TreeNode.new('/')
      current = tree
      depth.times do |i|
        new_node = Tree::TreeNode.new("#{i}")
        current << new_node
        current = new_node
      end

      tree.each { |_| nil }
      tree
    end

    # Test the recursive methods with a fiber. The stack usage is causing
    # failure for very large depths on unbalanced nodes.
    def test_fiber_for_recursion
      return unless defined?(Fiber.class) # Fibers exist only from Ruby 1.9 onwards.
      assert_nothing_thrown do
        Fiber.new do
          depth = 1000             # Use a reasonably large depth, which would trip a recursive stack
          root = create_long_depth_trees(depth)
          assert_equal(depth+1, root.size)
        end.resume
      end

    end # test_fiber

    # Test the recursive methods with a thread. The stack usage is causing
    # failure for very large depths on unbalanced nodes.
    def test_thread_for_recursion
      assert_nothing_thrown do
        depth = 1000             # Use a reasonably large depth, which would trip a recursive stack
        Thread.abort_on_exception = true
        Thread.new do
          root = create_long_depth_trees(depth)
          assert_equal(depth+1, root.size)
        end
      end

    end # test_thread

  end
end

__END__
