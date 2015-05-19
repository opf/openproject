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

describe Watcher do
  before do
    @user  = FactoryGirl.create :user
    @issue = FactoryGirl.create :work_package
    @role  = FactoryGirl.create :role, permissions: [:view_work_packages]
    @issue.project.add_member! @user, @role
  end

  it 'should add_watcher' do
    @issue.add_watcher(@user)
    assert_contains @issue.watchers.map(&:user), @user
  end

  it 'should add_watcher_will_not_add_same_user_twice' do
    assert @issue.add_watcher(@user)
    refute @issue.add_watcher(@user)
  end

  it 'should watched_by' do
    @issue.add_watcher(@user)
    assert @issue.watched_by?(@user)
    assert_contains WorkPackage.watched_by(@user), @issue
  end

  it 'should watcher_users_contains_correct_classes' do
    @issue.add_watcher(@user)
    watcher_users = @issue.watcher_users
    assert_kind_of Array, watcher_users
    assert_kind_of User, watcher_users.first
  end

  it 'should watcher_users_should_not_validate_user' do
    allow(@user).to receive(:valid?).and_return(false)
    @issue.watcher_users << @user
    assert @issue.watched_by?(@user)
  end

  it 'should watcher_user_ids' do
    @issue.add_watcher(@user)
    assert_contains @issue.watcher_user_ids, @user.id
  end

  it 'should watcher_user_ids' do
    @issue.watcher_user_ids = [@user.id]
    assert @issue.watched_by?(@user)
  end

  it 'should watcher_user_ids_should_make_ids_uniq' do
    @issue.watcher_user_ids = [@user.id, @user.id]
    assert @issue.valid?
    assert_equal 1, @issue.watchers.count
  end

  it 'should addable_watcher_users' do
    addable_watcher_users = @issue.addable_watcher_users
    assert_kind_of Array, addable_watcher_users
    assert_kind_of User, addable_watcher_users.first
  end

  it 'should recipients' do
    @user.update_attribute :mail_notification, 'all'

    assert @issue.watcher_recipients.empty?
    assert @issue.add_watcher(@user)
    assert_contains @issue.watcher_recipients, @user.mail

    @user.update_attribute :mail_notification, 'none'
    assert_does_not_contain @issue.watcher_recipients, @user.mail
  end

  it 'should unwatch' do
    assert @issue.add_watcher(@user)
    @issue.save
    assert_equal 1, @issue.remove_watcher(@user)
    @issue.save
    @issue.reload
    refute @issue.watched_by?(@user)
  end

  it 'should prune_removes_watchers_that_dont_have_permission' do
    @issue.add_watcher(@user)

    assert_no_difference 'Watcher.count' do
      Watcher.prune(user: @user)
    end
    assert @issue.watched_by?(@user)

    Member.delete_all
    @user.reload

    assert_difference 'Watcher.count', -1 do
      Watcher.prune(user: @user)
    end
    refute @issue.watched_by?(@user)
  end
end
