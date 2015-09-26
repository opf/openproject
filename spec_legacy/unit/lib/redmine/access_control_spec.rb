#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe Redmine::AccessControl do
  before do
    @access_module = Redmine::AccessControl
  end

  it 'should permissions' do
    perms = @access_module.permissions
    assert perms.is_a?(Array)
    assert perms.first.is_a?(Redmine::AccessControl::Permission)
  end

  it 'should module permission' do
    perm = @access_module.permission(:view_work_packages)
    assert perm.is_a?(Redmine::AccessControl::Permission)
    assert_equal :view_work_packages, perm.name
    assert_equal :work_package_tracking, perm.project_module
    assert perm.actions.is_a?(Array)
    assert perm.actions.include?('issues/index')
  end

  it 'should no module permission' do
    perm = @access_module.permission(:edit_project)
    assert perm.is_a?(Redmine::AccessControl::Permission)
    assert_equal :edit_project, perm.name
    assert_nil perm.project_module
    assert perm.actions.is_a?(Array)
    assert perm.actions.include?('projects/settings')
  end
end
