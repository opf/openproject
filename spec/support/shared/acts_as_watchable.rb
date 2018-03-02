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

shared_examples_for 'acts_as_watchable included' do
  before do
    unless defined?(model_instance) &&
           defined?(watch_permission) &&
           defined?(project)
      raise <<MESSAGE
  This share example needs the following objects:
  * model_instance: An instance of the watchable under test
  * watch_permission: The symbol for the permission required for watching an instance
  * project: the project the model_instance is in
MESSAGE
    end
  end

  let(:watcher_role) do
    permissions = is_public_permission ? [] : [watch_permission]

    FactoryGirl.create(:role, permissions: permissions)
  end
  let(:non_watcher_role) { FactoryGirl.create(:role, permissions: []) }
  let(:non_member_user) { FactoryGirl.create(:user) }
  let(:user_with_permission) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: watcher_role)
  end
  let(:locked_user_with_permission) do
    FactoryGirl.create(:user,
                       status: Principal::STATUSES[:locked],
                       member_in_project: project,
                       member_through_role: watcher_role)
  end

  let(:user_wo_permission) do
    if is_public_permission
      FactoryGirl.create(:user)
    else
      FactoryGirl.create(:user,
                         member_in_project: project,
                         member_through_role: non_watcher_role)
    end
  end
  let(:admin) { FactoryGirl.build(:admin) }
  let(:anonymous_user) { FactoryGirl.build(:anonymous) }
  let(:watching_user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: watcher_role).tap do |user|
      Watcher.create(watchable: model_instance, user: user)
    end
  end

  let(:is_public_permission) do
    Redmine::AccessControl.public_permissions.map(&:name).include?(watch_permission)
  end

  shared_context 'non member role has the permission to watch' do
    let(:non_member_role) do
      unless is_public_permission
        Role.non_member.add_permission! watch_permission
      end

      Role.non_member
    end

    before do
      unless is_public_permission
        non_member_role.add_permission! watch_permission
      end
    end
  end

  shared_context 'anonymous role has the permission to watch' do
    let(:anonymous_role) do
      permissions = is_public_permission ? [] : [watch_permission]
      FactoryGirl.build :anonymous_role, permissions: permissions
    end

    before do
      anonymous_role.save!
    end
  end

  describe '#possible_watcher_users' do
    subject { model_instance.possible_watcher_users }

    before do
      # in case the model_instance creates users, we do not want them
      # to mess with our expected users
      model_instance
      User.destroy_all

      Role.non_member
      Role.anonymous
      admin.save!
      anonymous_user.save!
      user_with_permission.save!
      user_wo_permission.save!
      locked_user_with_permission.save!
    end

    include_context 'non member role has the permission to watch'
    include_context 'anonymous role has the permission to watch'

    context 'when it is a public project' do
      before do
        project.update_attributes is_public: true
        model_instance.reload
      end

      it 'contains all allowed to view' do
        expected_users = [user_with_permission,
                          non_member_user,
                          admin]

        expected_users << user_wo_permission if is_public_permission

        expect(model_instance.possible_watcher_users)
          .to match_array(expected_users)
      end
    end

    context 'when it is a private project' do
      before do
        project.update_attributes is_public: false
        model_instance.reload
      end

      it 'contains members allowed to view' do
        expect(model_instance.possible_watcher_users)
          .to match_array([user_with_permission])
      end
    end
  end

  describe '#watcher_recipients' do
    before do
      watching_user
      model_instance.reload
    end

    subject { model_instance.watcher_recipients }

    it 'has the watching user' do
      is_expected.to match_array([watching_user])
    end

    context 'when the permission to watch has been removed' do
      before do
        if is_public_permission
          watching_user.memberships.destroy_all
        else
          watcher_role.remove_permission! watch_permission
        end

        model_instance.reload
      end

      it 'is empty' do
        is_expected.to match_array([])
      end
    end
  end

  describe '#watched_by?' do
    before do
      watching_user
      model_instance.reload
    end

    subject { model_instance.watched_by?(watching_user) }

    it 'is truthy' do
      is_expected.to be_truthy
    end

    context 'when the permission to view work packages has been removed' do
      # an existing watcher shouldn't be removed
      before do
        if is_public_permission
          skip "Not applicable for #{model_instance.class} as #{watch_permission} " +
               'is a public permission'
        end

        watcher_role.remove_permission! watch_permission

        model_instance.reload
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#addable_watcher_users' do
    subject { model_instance.addable_watcher_users }

    before do
      # in case the model_instance creates users, we do not want them
      # to mess with our expected users
      model_instance
      User.destroy_all

      Role.non_member
      Role.anonymous
      admin.save!
      anonymous_user.save!
      user_with_permission.save!
      user_wo_permission.save!
    end

    include_context 'non member role has the permission to watch'
    include_context 'anonymous role has the permission to watch'

    context 'when it is a public project' do
      before do
        project.update_attributes is_public: true
        model_instance.reload
      end

      it 'contains all allowed to view' do
        expected_users = [user_with_permission,
                          non_member_user,
                          admin]

        expected_users << user_wo_permission if is_public_permission

        is_expected
          .to match_array(expected_users)
      end

      context 'when the user is already watching' do
        before do
          Watcher.create(watchable: model_instance, user: user_with_permission)
          Watcher.create(watchable: model_instance, user: non_member_user)
        end

        it 'is no longer contained' do
          expected_users = [admin]

          expected_users << user_wo_permission if is_public_permission

          is_expected
            .to match_array(expected_users)
        end
      end
    end

    context 'when it is a private project' do
      before do
        project.update_attributes is_public: false
        model_instance.reload
      end

      it 'contains members allowed to view' do
        is_expected
          .to match_array([user_with_permission])
      end

      context 'when the user is already watching' do
        before do
          Watcher.create(watchable: model_instance, user: user_with_permission)
        end

        it 'is no longer contained' do
          is_expected
            .to be_empty
        end
      end
    end
  end
end
