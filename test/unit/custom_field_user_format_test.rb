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

class CustomFieldUserFormatTest < ActiveSupport::TestCase
  def setup
    super
    @project = FactoryGirl.create :valid_project
    role   = FactoryGirl.create :role, :permissions => [:view_work_packages, :edit_work_packages]
    @users = FactoryGirl.create_list(:user, 5)
    @users.each {|user| @project.add_member!(user, role) }
    @issue = FactoryGirl.create :issue,
        :project => @project,
        :author => @users.first,
        :type => @project.types.first
    @field = WorkPackageCustomField.create!(:name => 'Tester', :field_format => 'user')
  end

  def test_possible_values_with_no_arguments
    assert_equal [], @field.possible_values
    assert_equal [], @field.possible_values(nil)
  end

  def test_possible_values_with_project_resource
    possible_values = @field.possible_values(@project.work_packages.first)
    assert possible_values.any?
    assert_equal @project.users.sort.collect(&:id).map(&:to_s), possible_values
  end

  def test_possible_values_with_nil_project_resource
    assert_equal [], @field.possible_values(WorkPackage.new)
  end

  def test_possible_values_options_with_no_arguments
    assert_equal [], @field.possible_values_options
    assert_equal [], @field.possible_values_options(nil)
  end

  def test_possible_values_options_with_project_resource
    possible_values_options = @field.possible_values_options(@project.work_packages.first)
    assert possible_values_options.any?
    assert_equal @project.users.sort.map {|u| [u.name, u.id.to_s]}, possible_values_options
  end

  def test_cast_blank_value
    assert_equal nil, @field.cast_value(nil)
    assert_equal nil, @field.cast_value("")
  end

  def test_cast_valid_value
    user = @field.cast_value("#{@users.first.id}")
    assert_kind_of User, user
    assert_equal @users.first, user
  end

  def test_cast_invalid_value
    User.delete_all
    assert_equal nil, @field.cast_value("1")
  end
end
