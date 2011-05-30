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

class IssueCategoryTest < ActiveSupport::TestCase
  fixtures :issue_categories, :issues

  def setup
    @category = IssueCategory.find(1)
  end

  def test_destroy
    issue = @category.issues.first
    @category.destroy
    # Make sure the category was nullified on the issue
    assert_nil issue.reload.category
  end

  def test_destroy_with_reassign
    issue = @category.issues.first
    reassign_to = IssueCategory.find(2)
    @category.destroy(reassign_to)
    # Make sure the issue was reassigned
    assert_equal reassign_to, issue.reload.category
  end
end
