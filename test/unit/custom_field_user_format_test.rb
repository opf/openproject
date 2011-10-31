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

class CustomFieldUserFormatTest < ActiveSupport::TestCase
  fixtures :custom_fields, :projects, :members, :users, :member_roles, :trackers, :issues

  def setup
    @field = IssueCustomField.create!(:name => 'Tester', :field_format => 'user')
  end

  def test_possible_values_with_no_arguments
    assert_equal [], @field.possible_values
    assert_equal [], @field.possible_values(nil)
  end

  def test_possible_values_with_project_resource
    project = Project.find(1)
    possible_values = @field.possible_values(project.issues.first)
    assert possible_values.any?
    assert_equal project.users.sort.collect(&:id).map(&:to_s), possible_values
  end

  def test_possible_values_with_nil_project_resource
    project = Project.find(1)
    assert_equal [], @field.possible_values(Issue.new)
  end

  def test_possible_values_options_with_no_arguments
    assert_equal [], @field.possible_values_options
    assert_equal [], @field.possible_values_options(nil)
  end

  def test_possible_values_options_with_project_resource
    project = Project.find(1)
    possible_values_options = @field.possible_values_options(project.issues.first)
    assert possible_values_options.any?
    assert_equal project.users.sort.map {|u| [u.name, u.id.to_s]}, possible_values_options
  end

  def test_cast_blank_value
    assert_equal nil, @field.cast_value(nil)
    assert_equal nil, @field.cast_value("")
  end

  def test_cast_valid_value
    user = @field.cast_value("2")
    assert_kind_of User, user
    assert_equal User.find(2), user
  end

  def test_cast_invalid_value
    assert_equal nil, @field.cast_value("187")
  end
end
