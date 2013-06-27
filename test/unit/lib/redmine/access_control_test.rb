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
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::AccessControlTest < ActiveSupport::TestCase

  def setup
    @access_module = Redmine::AccessControl
  end

  def test_permissions
    perms = @access_module.permissions
    assert perms.is_a?(Array)
    assert perms.first.is_a?(Redmine::AccessControl::Permission)
  end

  def test_module_permission
    perm = @access_module.permission(:view_work_packages)
    assert perm.is_a?(Redmine::AccessControl::Permission)
    assert_equal :view_work_packages, perm.name
    assert_equal :issue_tracking, perm.project_module
    assert perm.actions.is_a?(Array)
    assert perm.actions.include?('issues/index')
  end

  def test_no_module_permission
    perm = @access_module.permission(:edit_project)
    assert perm.is_a?(Redmine::AccessControl::Permission)
    assert_equal :edit_project, perm.name
    assert_nil perm.project_module
    assert perm.actions.is_a?(Array)
    assert perm.actions.include?('projects/settings')
  end
end
