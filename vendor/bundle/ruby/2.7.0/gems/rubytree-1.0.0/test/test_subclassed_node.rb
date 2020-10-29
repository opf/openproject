#!/usr/bin/env ruby

# test_subclassed_node.rb - This file is part of the RubyTree package.
#
# Copyright (c) 2012, 2017 Anupam Sengupta
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
  class TestSubclassedTreeNode < Test::Unit::TestCase

    # A subclassed node to test various inheritance related features.
    class MyNode < Tree::TreeNode
      # A dummy method to test the camelCasedMethod resolution
      def my_dummy_method
        'Hello'
      end
    end

    def test_camelcase_methods
      root = MyNode.new('Root')

      assert_equal('Hello', root.my_dummy_method)

      # We should get a warning as we are invoking the camelCase version of the dummy method.
      assert_warn(StructuredWarnings::DeprecatedMethodWarning) { root.send('MyDummyMethod') }

      # Test if the structured_warnings can be disabled to call the CamelCase methods.
      StructuredWarnings::DeprecatedMethodWarning.disable do
        # noinspection RubyResolve
        assert_equal('Hello', root.myDummyMethod)
      end

    end

    def test_detached_copy_same_clz
      root = MyNode.new('Root')
      assert_equal(MyNode, root.detached_copy.class)
    end

  end
end

__END__
