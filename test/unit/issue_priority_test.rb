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

class IssuePriorityTest < ActiveSupport::TestCase
  fixtures :all

  def test_should_be_an_enumeration
    assert IssuePriority.ancestors.include?(Enumeration)
  end

  def test_objects_count
    # low priority
    assert_equal 6, IssuePriority.find(4).objects_count
    # urgent
    assert_equal 0, IssuePriority.find(7).objects_count
  end

  def test_option_name
    assert_equal :enumeration_work_package_priorities, IssuePriority.new.option_name
  end
end

