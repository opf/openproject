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

describe Member, type: :model do
  before do
    Role.non_member.add_permission! :view_work_packages # non_member users may be watchers of work units
    Role.non_member.add_permission! :view_wiki_pages # non_member users may be watchers of wikis
    @project = FactoryGirl.create :project_with_types
    @user = FactoryGirl.create :user, member_in_project: @project
    @member = @project.members.first
    @role = @member.roles.first
    @role.add_permission! :view_wiki_pages
  end

  it 'should create' do
    member = Member.new.tap do |m|
      m.force_attributes = { project_id: @project.id,
                             user_id: FactoryGirl.create(:user).id,
                             role_ids: [@role.id] }
    end
    assert member.save
    member.reload

    assert_equal 1, member.roles.size
    assert_equal @role, member.roles.first
  end

  it 'should update' do
    assert_equal @project.name, @member.project.name
    assert_equal @role.name, @member.roles.first.name
    assert_equal @user.login, @member.user.login

    @member.mail_notification = !@member.mail_notification
    assert @member.save
  end

  it 'should update roles' do
    assert_equal 1, @member.roles.size
    @member.role_ids = [@role.id, FactoryGirl.create(:role).id]
    assert @member.save
    assert_equal 2, @member.reload.roles.size
  end

  it 'should validate' do
    members = []
    user_id = FactoryGirl.create(:user).id
    2.times do
      members << Member.new.tap do |m|
        m.force_attributes = { project_id: @project.id,
                               user_id: user_id,
                               role_ids: [@role.id] }
      end
    end

    assert members.first.save
    # same user can't have more than one membership for a project
    assert !members.last.save

    member = Member.new.tap do |m|
      m.force_attributes = { project_id: @project,
                             user_id: FactoryGirl.create(:user).id,
                             role_ids: [] }
    end
    # must have one role at least
    assert !member.save
  end

  it 'should destroy' do
    assert_difference 'Member.count', -1 do
      assert_difference 'MemberRole.count', -1 do
        @member.destroy
      end
    end

    assert_raise(ActiveRecord::RecordNotFound) { Member.find(@member.id) }
  end

  context 'removing permissions' do
    before do
      @private_project = FactoryGirl.create :project_with_types,
                                            is_public: true # has to be public first to successfully create things. Will be set to private later
      @watcher_user = FactoryGirl.create(:user)

      # watchers for public issue
      public_issue = FactoryGirl.create :work_package
      public_issue.project.is_public = true
      public_issue.project.save!
      Watcher.create!(watchable: public_issue, user: @watcher_user)

      # watchers for private things
      Watcher.create!(watchable: FactoryGirl.create(:work_package, project: @private_project), user: @watcher_user)
      board = FactoryGirl.create :board, project: @private_project
      @message = FactoryGirl.create :message, board: board
      Watcher.create!(watchable: @message, user: @watcher_user)
      Watcher.create!(watchable: FactoryGirl.create(:wiki, project: @private_project), user: @watcher_user)
      @private_project.reload # to access @private_project.wiki
      Watcher.create!(watchable: FactoryGirl.create(:wiki_page, wiki: @private_project.wiki), user: @watcher_user)
      @private_role = FactoryGirl.create :role, permissions: [:view_wiki_pages, :view_work_packages]

      @private_project.is_public = false
      @private_project.save
    end

    context 'of user' do
      before do
        (@member = Member.new.tap do |m|
          m.force_attributes = { project_id: @private_project.id,
                                 user_id: @watcher_user.id,
                                 role_ids: [@private_role.id, FactoryGirl.create(:role).id] }
        end).save!
      end

      context 'by deleting membership' do
        it 'should prune watchers' do
          assert_difference 'Watcher.count', -4 do
            @member.destroy
          end
        end
      end

      context 'by updating roles' do
        it 'should prune watchers' do
          @private_role.remove_permission! :view_wiki_pages
          assert_difference 'Watcher.count', -2 do
            @member.role_ids = [@private_role.id]
            @member.save
          end
          assert !@message.watched_by?(@watcher_user)
        end
      end
    end

    context 'of group' do
      before do
        @group = FactoryGirl.create :group
        @member = (Member.new.tap do |m|
          m.force_attributes = { project_id: @private_project.id,
                                 user_id: @group.id,
                                 role_ids: [@private_role.id, FactoryGirl.create(:role).id] }
        end)

        @group.members << @member
        @group.users << @watcher_user
        assert @group.save
      end

      context 'by deleting membership' do
        it 'should prune watchers' do
          assert_difference 'Watcher.count', -4 do
            @member.destroy
          end
        end
      end

      context 'by updating roles' do
        it 'should prune watchers' do
          @private_role.remove_permission! :view_wiki_pages
          assert_difference 'Watcher.count', -2 do
            @member.role_ids = [@private_role.id]
            @member.save
          end
        end
      end
    end
  end
end
