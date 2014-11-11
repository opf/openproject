#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require File.expand_path('../../test_helper', __FILE__)

describe Group do

  before do

    @group = FactoryGirl.create :group
    @member = FactoryGirl.build :member
    @work_package = FactoryGirl.create :work_package
    @roles = FactoryGirl.create_list :role, 2
    @member.force_attributes = { :principal => @group, :role_ids => @roles.map(&:id) }
    @member.save!
    @project = @member.project
    @user = FactoryGirl.create :user
    @group.users << @user
    @group.save!
  end

  it 'should create' do
    g = Group.new(:lastname => 'New group')
    assert g.save
  end

  it 'should roles_given_to_new_user' do
    user = FactoryGirl.build :user
    @group.users << user

    assert user.member_of? @project
  end

  it 'should roles_given_to_existing_user' do
    assert @user.member_of? @project
  end

  it 'should roles_updated' do
    group = FactoryGirl.create :group
    member = FactoryGirl.build :member
    roles = FactoryGirl.create_list :role, 2
    role_ids = roles.map { |r| r.id }
    member.force_attributes = { :principal => group, :role_ids => role_ids }
    member.save!
    user = FactoryGirl.create :user
    group.users << user
    group.save!

    member.role_ids = [role_ids.first]
    assert_equal [role_ids.first], user.reload.roles_for_project(member.project).collect(&:id).sort

    member.role_ids = role_ids
    assert_equal role_ids, user.reload.roles_for_project(member.project).collect(&:id).sort

    member.role_ids = [role_ids.last]
    assert_equal [role_ids.last], user.reload.roles_for_project(member.project).collect(&:id).sort

    member.role_ids = [role_ids.first]
    assert_equal [role_ids.first], user.reload.roles_for_project(member.project).collect(&:id).sort
  end

  it 'should roles_removed_when_removing_group_membership' do
    assert @user.member_of?(@project)
    @member.destroy
    @user.reload
    @project.reload
    assert !@user.member_of?(@project)
  end

  it 'should roles_removed_when_removing_user_from_group' do
    assert @user.member_of?(@project)
    @user.groups.clear
    @user.reload
    @project.reload
    assert !@user.member_of?(@project)
  end
end
