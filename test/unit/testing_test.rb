#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

# Test case that checks that the testing infrastructure is setup correctly.
class TestingTest < ActiveSupport::TestCase
  def test_working
    assert true
  end

  test "Rails 'test' case syntax" do
    assert true
  end

  test "Generating with object_daddy" do
    assert_difference "IssueStatus.count" do
      IssueStatus.generate!
    end
  end

  should "work with shoulda" do
    assert true
  end

  context "works with a context" do
    should "work" do
      assert true
    end
  end

end
