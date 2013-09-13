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

class GroupTest < ActiveSupport::TestCase

  def setup
    super
    @group = FactoryGirl.create :group
    @member = FactoryGirl.build :member
    @issue = FactoryGirl.create :issue
    @roles = FactoryGirl.create_list :role, 2
    @member.force_attributes = { :principal => @group, :role_ids => @roles.map(&:id) }
    @member.save!
    @project = @member.project
    @user = FactoryGirl.create :user
    @group.users << @user
    @group.save!
  end

  def test_create
    g = Group.new(:lastname => 'New group')
    assert g.save
  end

  def test_roles_given_to_new_user
    user = FactoryGirl.build :user
    @group.users << user

    assert user.member_of? @project
  end

  def test_roles_given_to_existing_user
    assert @user.member_of? @project
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
    assert @user.member_of?(@project)
    @member.destroy
    @user.reload
    @project.reload
    assert !@user.member_of?(@project)
  end

  def test_roles_removed_when_removing_user_from_group
    assert @user.member_of?(@project)
    @user.groups.clear
    @user.reload
    @project.reload
    assert !@user.member_of?(@project)
  end

  def test_destroy_should_unassign_issues
    @issue.assigned_to_id = @group.id

    assert @issue.save
    assert @issue.assigned_to_id == @group.id
    assert @group.destroy
    assert @group.destroyed?

    @issue.reload
    assert_equal nil, @issue.assigned_to_id
  end
end
