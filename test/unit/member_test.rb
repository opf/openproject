#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class MemberTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    @jsmith = Member.find(1)
  end

  def test_create
    member = Member.new(:project_id => 1, :user_id => 4, :role_ids => [1, 2])
    assert member.save
    member.reload

    assert_equal 2, member.roles.size
    assert_equal Role.find(1), member.roles.sort.first
  end

  def test_update
    assert_equal "eCookbook", @jsmith.project.name
    assert_equal "Manager", @jsmith.roles.first.name
    assert_equal "jsmith", @jsmith.user.login

    @jsmith.mail_notification = !@jsmith.mail_notification
    assert @jsmith.save
  end

  def test_update_roles
    assert_equal 1, @jsmith.roles.size
    @jsmith.role_ids = [1, 2]
    assert @jsmith.save
    assert_equal 2, @jsmith.reload.roles.size
  end

  def test_validate
    member = Member.new(:project_id => 1, :user_id => 2, :role_ids => [2])
    # same use can't have more than one membership for a project
    assert !member.save

    member = Member.new(:project_id => 1, :user_id => 2, :role_ids => [])
    # must have one role at least
    assert !member.save
  end

  def test_destroy
    assert_difference 'Member.count', -1 do
      assert_difference 'MemberRole.count', -1 do
        @jsmith.destroy
      end
    end

    assert_raise(ActiveRecord::RecordNotFound) { Member.find(@jsmith.id) }
  end

  context "removing permissions" do
    setup do
      Watcher.delete_all("user_id = 9")
      user = User.find(9)
      # public
      Watcher.create!(:watchable => Issue.find(1), :user => user)
      # private
      Watcher.create!(:watchable => Issue.find(4), :user => user)
      Watcher.create!(:watchable => Message.find(7), :user => user)
      Watcher.create!(:watchable => Wiki.find(2), :user => user)
      Watcher.create!(:watchable => WikiPage.find(3), :user => user)
    end

    context "of user" do
      setup do
        @member = Member.create!(:project => Project.find(2), :principal => User.find(9), :role_ids => [1, 2])
      end

      context "by deleting membership" do
        should "prune watchers" do
          assert_difference 'Watcher.count', -4 do
            @member.destroy
          end
        end

        should "not prune watchers if the user still has permission to watch as a non-member" do
          @member_on_public_project = Member.create!(:project => Project.find(1), :principal => User.find(9), :role_ids => [1, 2])

          assert_no_difference 'Watcher.count' do
            @member_on_public_project.destroy
          end
        end
        
      end

      context "by updating roles" do
        should "prune watchers" do
          Role.find(2).remove_permission! :view_wiki_pages
          member = Member.first(:order => 'id desc')
          assert_difference 'Watcher.count', -2 do
            member.role_ids = [2]
            member.save
          end
          assert !Message.find(7).watched_by?(@user)
        end
      end
    end

    context "of group" do
      setup do
        group = Group.find(10)
        @member = Member.create!(:project => Project.find(2), :principal => group, :role_ids => [1, 2])
        group.users << User.find(9)
      end

      context "by deleting membership" do
        should "prune watchers" do
          assert_difference 'Watcher.count', -4 do
            @member.destroy
          end
        end
      end

      context "by updating roles" do
        should "prune watchers" do
          Role.find(2).remove_permission! :view_wiki_pages
          assert_difference 'Watcher.count', -2 do
            @member.role_ids = [2]
            @member.save
          end
        end
      end
    end
  end
end
