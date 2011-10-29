#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
