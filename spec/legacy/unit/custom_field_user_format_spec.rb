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

describe 'CustomFieldFormat' do # TODO: what is this?
  before do
    @project = FactoryGirl.create :valid_project
    role   = FactoryGirl.create :role, permissions: [:view_work_packages, :edit_work_packages]
    @users = FactoryGirl.create_list(:user, 5)
    @users.each { |user| @project.add_member!(user, role) }
    @issue = FactoryGirl.create :work_package,
                                project: @project,
                                author: @users.first,
                                type: @project.types.first
    @field = WorkPackageCustomField.create!(name: 'Tester', field_format: 'user')
  end

  it 'should possible_values_with_no_arguments' do
    assert_equal [], @field.possible_values
    assert_equal [], @field.possible_values(nil)
  end

  it 'should possible_values_with_project_resource' do
    possible_values = @field.possible_values(@project.work_packages.first)
    assert possible_values.any?
    assert_equal @project.users.sort.map(&:id).map(&:to_s), possible_values
  end

  it 'should possible_values_with_nil_project_resource' do
    assert_equal [], @field.possible_values(WorkPackage.new)
  end

  it 'should possible_values_options_with_no_arguments' do
    assert_equal [], @field.possible_values_options
    assert_equal [], @field.possible_values_options(nil)
  end

  it 'should possible_values_options_with_project_resource' do
    possible_values_options = @field.possible_values_options(@project.work_packages.first)
    assert possible_values_options.any?
    assert_equal @project.users.sort.map { |u| [u.name, u.id.to_s] }, possible_values_options
  end

  it 'should cast_blank_value' do
    assert_equal nil, @field.cast_value(nil)
    assert_equal nil, @field.cast_value('')
  end

  it 'should cast_valid_value' do
    user = @field.cast_value("#{@users.first.id}")
    assert_kind_of User, user
    assert_equal @users.first, user
  end

  it 'should cast_invalid_value' do
    User.delete_all
    assert_equal nil, @field.cast_value('1')
  end
end
