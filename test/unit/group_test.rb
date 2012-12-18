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

class GroupTest < ActiveSupport::TestCase
  fixtures :all

  def test_create
    g = Group.new(:lastname => 'New group')
    assert g.save
  end

  def test_roles_given_to_new_user
    group = FactoryGirl.create :group
    member = FactoryGirl.build :member
    role = FactoryGirl.create :role
    member.force_attributes = { :principal => group, :role_ids => [role.id] }
    member.save!
    user = FactoryGirl.build :user
    group.users << user

    assert user.member_of? member.project
  end

  def test_roles_given_to_existing_user
    group = FactoryGirl.create :group
    member = FactoryGirl.build :member
    role = FactoryGirl.create :role
    member.force_attributes = { :principal => group, :role_ids => [role.id] }
    member.save!
    user = FactoryGirl.create :user
    group.users << user

    assert user.member_of? member.project
  end

  def test_roles_updated
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

  def test_roles_removed_when_removing_group_membership
    assert User.find(8).member_of?(Project.find(5))
    Member.find_by_project_id_and_user_id(5, 10).destroy
    assert !User.find(8).member_of?(Project.find(5))
  end

  def test_roles_removed_when_removing_user_from_group
    assert User.find(8).member_of?(Project.find(5))
    User.find(8).groups.clear
    assert !User.find(8).member_of?(Project.find(5))
  end
end
