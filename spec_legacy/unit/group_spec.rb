#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Group, type: :model do
  before do
    @group = FactoryGirl.create :group
    @member = FactoryGirl.build :member
    @work_package = FactoryGirl.create :work_package
    @roles = FactoryGirl.create_list :role, 2
    @member.attributes = { principal: @group, role_ids: @roles.map(&:id) }
    @member.save!
    @project = @member.project
    @user = FactoryGirl.create :user
    @group.users << @user
    @group.save!
  end

  it 'should create' do
    g = Group.new(lastname: 'New group')
    assert g.save
  end

  it 'should roles given to new user' do
    user = FactoryGirl.build :user
    @group.users << user

    assert user.member_of? @project
  end

  it 'should roles given to existing user' do
    assert @user.member_of? @project
  end

  it 'should roles updated' do
    group = FactoryGirl.create :group
    member = FactoryGirl.build :member
    roles = FactoryGirl.create_list :role, 2
    role_ids = roles.map(&:id)
    member.attributes = { principal: group, role_ids: role_ids }
    member.save!
    user = FactoryGirl.create :user
    group.users << user
    group.save!

    member.role_ids = [role_ids.first]
    assert_equal [role_ids.first], user.reload.roles_for_project(member.project).map(&:id).sort

    member.role_ids = role_ids
    assert_equal role_ids, user.reload.roles_for_project(member.project).map(&:id).sort

    member.role_ids = [role_ids.last]
    assert_equal [role_ids.last], user.reload.roles_for_project(member.project).map(&:id).sort

    member.role_ids = [role_ids.first]
    assert_equal [role_ids.first], user.reload.roles_for_project(member.project).map(&:id).sort
  end

  it 'should roles removed when removing group membership' do
    assert @user.member_of?(@project)
    @member.destroy
    @user.reload
    @project.reload
    assert !@user.member_of?(@project)
  end

  it 'should roles removed when removing user from group' do
    assert @user.member_of?(@project)
    @user.groups.destroy_all
    @user.reload
    @project.reload
    assert !@user.member_of?(@project)
  end
end
