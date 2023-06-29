# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

require 'spec_helper'

RSpec.describe ActivePermissions::Updater do
  shared_let(:user) { create(:user, firstname: 'normal', lastname: 'user') }
  shared_let(:anonymous_user) { create(:anonymous) }
  shared_let(:admin) { create(:admin, firstname: 'admin', lastname: 'user') }
  shared_let(:non_member_user) { create(:user) }
  shared_let(:system_user) { create(:system) }

  shared_let(:enabled_modules) { %i[work_package_tracking news] }
  shared_let(:private_project) do
    create(:project,
           identifier: 'private_project',
           public: false,
           active: true,
           enabled_module_names: enabled_modules)
  end
  shared_let(:public_project) do
    create(:project,
           identifier: 'public_project',
           public: true,
           active: true,
           enabled_module_names: enabled_modules)
  end
  shared_let(:memberless_private_project) do
    create(:project,
           identifier: 'memberless_private_project',
           public: false,
           active: true,
           enabled_module_names: enabled_modules)
  end

  shared_let(:member_permissions) { %w[view_work_packages add_work_packages] }
  shared_let(:anonymous_permissions) { %w[view_work_packages add_work_packages] }
  shared_let(:non_member_permissions) { %w[view_work_packages add_work_packages] }
  shared_let(:global_permissions) { ['add_project'] }

  shared_let(:role) do
    create(:role,
           permissions: member_permissions)
  end
  shared_let(:global_role) do
    build(:global_role,
          permissions: global_permissions)
  end
  shared_let(:member) do
    create(:member,
           user:,
           roles: [role],
           project: private_project)
  end
  shared_let(:anonymous_role) do
    create(:anonymous_role,
           permissions: anonymous_permissions)
  end
  shared_let(:non_member_role) do
    create(:non_member,
           permissions: non_member_permissions)
  end
  shared_let(:global_member) do
    create(:global_member,
           user:,
           roles: [global_role])
  end

  shared_examples_for 'expected entries' do
    let(:expected_included) { [] }
    let(:expected_excluded) { [] }
    let(:expected_included_default) do
      [
        [user, nil, 'add_project'],
        [admin, nil, 'add_project'],
        [system_user, nil, 'add_project'],
        [user, public_project, 'view_project'],
        [user, public_project, 'view_work_packages'],
        [user, private_project, 'view_work_packages'],
        [user, private_project, 'add_work_packages'],
        [user, private_project, 'view_project'],
        [anonymous_user, public_project, 'view_project'],
        [anonymous_user, public_project, 'view_work_packages'],
        [admin, private_project, 'view_work_packages'],
        [admin, private_project, 'view_project'],
        [admin, memberless_private_project, 'view_work_packages'],
        [system_user, private_project, 'view_work_packages'],
        [system_user, private_project, 'view_project'],
        [system_user, memberless_private_project, 'view_work_packages']
      ]
    end
    let(:expected_excluded_default) do
      [
        [user, memberless_private_project, 'view_project'],
        [user, memberless_private_project, 'view_work_packages'],
        [user, private_project, 'view_wiki_pages'],
        [admin, private_project, 'view_project_activity'],
        [system_user, private_project, 'view_project_activity'],
        [admin, public_project, 'view_project_activity'],
        [system_user, public_project, 'view_project_activity']
      ]
    end

    it 'contains the expected sets of permissions', :aggregate_failures do
      expected_included_result = (expected_included + expected_included_default - expected_excluded).uniq
      expected_excluded_result = (expected_excluded + expected_excluded_default - expected_included).uniq

      if expected_included_result.any?
        expect(ActivePermission
          .includes(:user, :project)
          .map { |ap| [ap.user.name, ap.project&.identifier, ap.permission] })
          .to include(*expected_included_result.map do |user, project, permission|
            [user.try(:name), project.try(:identifier), permission]
          end)
      end

      if expected_excluded_result.any?
        expect(ActivePermission
          .includes(:user, :project)
          .map { |ap| [ap.user.name, ap.project&.identifier, ap.permission] })
          .not_to include(*expected_excluded_result.map do |user, project, permission|
            [user.try(:name), project.try(:identifier), permission]
          end)
      end
    end
  end

  context 'when creating a member' do
    context 'for a private project' do
      let!(:other_role) { create(:role, permissions: %w[view_work_packages manage_news]) }

      before do
        create(:member,
               user:,
               roles: [other_role],
               project: memberless_private_project)
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, memberless_private_project, 'view_project'],
            [user, memberless_private_project, 'view_work_packages'],
            [user, memberless_private_project, 'manage_news']
          ]
        end
      end
    end

    context 'for a public project' do
      let!(:other_role) { create(:role, permissions: %w[view_work_packages manage_news]) }

      before do
        create(:member,
               user:,
               roles: [other_role],
               project: public_project)
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, public_project, 'manage_news']
          ]
        end
      end
    end

    context 'for the global realm' do
      let!(:other_user) { create(:user) }

      before do
        create(:global_member,
               user: other_user,
               roles: [global_role])
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [other_user, nil, 'add_project']
          ]
        end
      end
    end
  end

  context 'when deleting a member' do
    context 'with the user having no other membership in the project' do
      before do
        member.destroy
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'add_work_packages'],
            [user, private_project, 'view_project']
          ]
        end
      end
    end

    context 'with the user having another membership in another project' do
      let(:other_role) { create(:role, permissions: %w[view_work_packages manage_news]) }
      let!(:other_member) do
        create(:member,
               user:,
               roles: [other_role],
               project: memberless_private_project)
      end

      before do
        member.destroy
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, memberless_private_project, 'view_project'],
            [user, memberless_private_project, 'view_work_packages'],
            [user, memberless_private_project, 'manage_news']
          ]
        end
        let(:expected_excluded) do
          [
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'add_work_packages'],
            [user, private_project, 'view_project']
          ]
        end
      end
    end
  end

  context 'when adding a project role to a member' do
    let(:other_role) { create(:role, permissions: %w[view_work_packages manage_news view_wiki_pages]) }

    shared_examples_for 'expected entries on role addition' do
      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, private_project, 'manage_news']
          ]
        end
        let(:expected_excluded) do
          [
            [user, private_project, 'view_wiki_pages']
          ]
        end
      end
    end

    context 'for a member_role creation' do
      before do
        MemberRole.create(member:, role: other_role)
      end

      it_behaves_like 'expected entries on role addition'
    end

    context 'for an assignment to member#roles' do
      before do
        member.roles << other_role
      end

      it_behaves_like 'expected entries on role addition'
    end

    context 'for an assignment via role_ids' do
      before do
        member.role_ids = [other_role.id, role.id]
      end

      it_behaves_like 'expected entries on role addition'
    end
  end

  context 'when adding a global role to a member' do
    let(:other_role) { create(:global_role, permissions: %w[manage_user]) }

    shared_examples_for 'expected entries on role addition' do
      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, nil, 'manage_user']
          ]
        end
      end
    end

    context 'for a member_role creation' do
      before do
        MemberRole.create(member: global_member, role: other_role)
      end

      it_behaves_like 'expected entries on role addition'
    end

    context 'for an assignment to member#roles' do
      before do
        global_member.roles << other_role
      end

      it_behaves_like 'expected entries on role addition'
    end

    context 'for an assignment via role_ids' do
      before do
        global_member.role_ids = [other_role.id, global_role.id]
      end

      it_behaves_like 'expected entries on role addition'
    end
  end

  context 'when removing a role from a member' do
    let!(:other_role) { create(:role, permissions: %w[view_work_packages manage_news]) }

    before do
      MemberRole.create(member:, role: other_role)
    end

    shared_examples_for 'expected entries on role removal' do
      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            # still included because the other role grants the permission as well
            [user, private_project, 'view_work_packages']
          ]
        end
        let(:expected_excluded) do
          [
            [user, private_project, 'manage_news']
          ]
        end
      end
    end

    context 'for a member_role destruction' do
      before do
        member.member_roles.find_by(role: other_role).destroy
      end

      it_behaves_like 'expected entries on role removal'
    end

    context 'for an unassignment by member#roles' do
      before do
        member.roles = [role]
      end

      it_behaves_like 'expected entries on role removal'
    end

    context 'for an unassignment via role_ids' do
      before do
        member.role_ids = [role.id]
      end

      it_behaves_like 'expected entries on role removal'
    end

    context 'for an unassignment by member#member_roles' do
      before do
        member.member_roles = [member.member_roles.where(role:).first]
      end

      it_behaves_like 'expected entries on role removal'
    end

    context 'for an unassignment via member_role_ids' do
      before do
        member.member_role_ids = [member.member_roles.where(role:).first.id]
      end

      it_behaves_like 'expected entries on role removal'
    end
  end

  context 'when removing a global role from a member' do
    let(:other_role) { create(:global_role, permissions: %w[manage_user]) }

    before do
      MemberRole.create(member: global_member, role: other_role)
    end

    shared_examples_for 'expected entries on global role removal' do
      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            # Another role grants that permission
            [user, nil, 'add_project']
          ]
        end
        let(:expected_excluded) do
          [
            [user, nil, 'manage_user']
          ]
        end
      end
    end

    context 'for a member_role destruction' do
      before do
        global_member.member_roles.find_by(role: other_role).destroy
      end

      it_behaves_like 'expected entries on global role removal'
    end

    context 'for an unassignment by member#roles' do
      before do
        global_member.roles = [global_role]
      end

      it_behaves_like 'expected entries on global role removal'
    end

    context 'for an unassignment via role_ids' do
      before do
        global_member.role_ids = [global_role.id]
      end

      it_behaves_like 'expected entries on global role removal'
    end

    context 'for an unassignment by member#member_roles' do
      before do
        global_member.member_roles = [global_member.member_roles.where(role: global_role).first]
      end

      it_behaves_like 'expected entries on global role removal'
    end

    context 'for an unassignment via member_role_ids' do
      before do
        global_member.member_role_ids = [global_member.member_roles.where(role: global_role).first.id]
      end

      it_behaves_like 'expected entries on global role removal'
    end
  end

  context 'when enabling a module for a project' do
    shared_examples_for 'expected entries on enabling a module' do
      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, private_project, 'view_messages'],
            [user, public_project, 'view_messages'],
            [admin, private_project, 'view_project']
          ]
        end
      end
    end

    context 'for an EnabledModule creation' do
      before do
        EnabledModule.create(project: private_project, name: 'forums')
        EnabledModule.create(project: public_project, name: 'forums')
      end

      it_behaves_like 'expected entries on enabling a module'
    end

    context 'for an assignment to project#enabled_module_names' do
      before do
        private_project.enabled_module_names = %w[news work_package_tracking forums]
        public_project.enabled_module_names = %w[news work_package_tracking forums]
      end

      it_behaves_like 'expected entries on enabling a module'
    end
  end

  context 'when disabling a module for a project' do
    shared_examples_for 'expected entries on disabling the news module' do
      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, private_project, 'view_news'],
            [admin, private_project, 'view_news'],
            [user, public_project, 'view_news'],
            [admin, public_project, 'view_news']
          ]
        end
      end
    end

    context 'for EnabledModule destruction' do
      before do
        EnabledModule.where(project: private_project, name: 'news').destroy_all
        EnabledModule.where(project: public_project, name: 'news').destroy_all
      end

      it_behaves_like 'expected entries on disabling the news module'
    end

    context 'for an assignment to project#enabled_module_names' do
      before do
        private_project.enabled_module_names = %w[work_package_tracking]
        public_project.enabled_module_names = %w[work_package_tracking]
      end

      it_behaves_like 'expected entries on disabling the news module'
    end

    context 'for a complete unassignment via project#enabled_module_names' do
      before do
        private_project.enabled_module_names = %w[]
        public_project.enabled_module_names = %w[]
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, private_project, 'view_news'],
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'add_work_packages'],
            [user, public_project, 'view_work_packages'],
            [admin, private_project, 'view_news'],
            [admin, private_project, 'view_work_packages'],
            [anonymous_user, public_project, 'view_work_packages'],
            [system_user, private_project, 'view_work_packages'],
            [system_user, public_project, 'view_work_packages']
          ]
        end
      end
    end
  end

  context 'when destroying a project' do
    context 'for a private project' do
      before do
        private_project.destroy
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, private_project, 'view_project'],
            [user, private_project, 'view_news'],
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'add_work_packages'],
            [admin, private_project, 'view_news'],
            [admin, private_project, 'view_work_packages'],
            [admin, private_project, 'view_project'],
            [system_user, private_project, 'view_project'],
            [system_user, private_project, 'view_work_packages']
          ]
        end
      end
    end

    context 'for a public project' do
      before do
        public_project.destroy
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, public_project, 'view_project'],
            [user, public_project, 'view_work_packages'],
            [admin, public_project, 'view_work_packages'],
            [anonymous_user, public_project, 'view_project'],
            [anonymous_user, public_project, 'view_work_packages']
          ]
        end
      end
    end
  end

  context 'when creating a project' do
    context 'for a private project' do
      let!(:new_project) { create(:project, enabled_module_names: enabled_modules) }

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [admin, new_project, 'view_news'],
            [admin, new_project, 'view_work_packages'],
            [admin, new_project, 'view_project']
          ]
        end
      end
    end

    context 'for a public project' do
      let!(:new_project) { create(:public_project, enabled_module_names: enabled_modules) }

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [admin, new_project, 'view_news'],
            [admin, new_project, 'view_work_packages'],
            [admin, new_project, 'view_project'],
            [user, new_project, 'view_news'],
            [user, new_project, 'view_work_packages'],
            [user, new_project, 'view_project']
          ]
        end
      end
    end
  end

  context 'when destroying a user' do
    context 'for a normal user' do
      before do
        user.destroy
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, nil, 'add_project'],
            [user, public_project, 'view_project'],
            [user, public_project, 'view_work_packages'],
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'add_work_packages'],
            [user, private_project, 'view_project']
          ]
        end
      end
    end

    context 'for an admin user' do
      before do
        admin.destroy
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [admin, nil, 'add_project'],
            [admin, private_project, 'view_work_packages'],
            [admin, private_project, 'view_project'],
            [admin, memberless_private_project, 'view_work_packages']
          ]
        end
      end
    end
  end

  context 'when creating a user' do
    context 'for a normal user' do
      let!(:new_user) { create(:user) }

      it_behaves_like 'expected entries' do
        # Nothing changes
      end
    end

    context 'for an admin user' do
      let!(:new_admin) { create(:admin) }

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [new_admin, nil, 'add_project'],
            [new_admin, private_project, 'view_work_packages'],
            [new_admin, private_project, 'view_project'],
            [new_admin, memberless_private_project, 'view_work_packages']
          ]
        end
      end
    end
  end

  context 'when updating a user' do
    context 'when modifying a normal user (no permission relevant stuff)' do
      before do
        User.find(user.id).update!(login: 'new_login')
      end

      it_behaves_like 'expected entries' do
        # Nothing changes
      end
    end

    context 'when modifying a normal user to become admin' do
      before do
        User.find(user.id).update!(admin: true)
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'view_project'],
            [user, memberless_private_project, 'view_work_packages'],
            [user, memberless_private_project, 'view_project']
          ]
        end
      end
    end

    context 'when modifying an admin user to become non admin' do
      before do
        User.find(admin.id).update!(admin: false)
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [admin, nil, 'add_project'],
            [admin, private_project, 'view_work_packages'],
            [admin, private_project, 'view_project'],
            [admin, memberless_private_project, 'view_work_packages'],
            [admin, memberless_private_project, 'view_project']
          ]
        end
      end
    end

    context 'when modifying a normal user to become locked' do
      before do
        User.find(user.id).locked!
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [user, nil, 'add_project'],
            [user, public_project, 'view_project'],
            [user, public_project, 'view_work_packages'],
            [user, private_project, 'view_work_packages'],
            [user, private_project, 'add_work_packages'],
            [user, private_project, 'view_project']
          ]
        end
      end
    end

    context 'when modifying a normal user to become invited' do
      before do
        User.find(user.id).invited!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying a normal user to become registered' do
      before do
        User.find(user.id).registered!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying a normal user to become active from registered' do
      before do
        User.find(user.id).registered!
        User.find(user.id).active!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying a normal user to become active from invited' do
      before do
        User.find(user.id).invited!
        User.find(user.id).active!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying an admin user to become invited' do
      before do
        User.find(admin.id).invited!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying an admin user to become registered' do
      before do
        User.find(admin.id).registered!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying an admin user to become active from registered' do
      before do
        User.find(admin.id).registered!
        User.find(admin.id).active!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying an admin user to become active from invited' do
      before do
        User.find(admin.id).invited!
        User.find(admin.id).active!
      end

      it_behaves_like 'expected entries' do
        # no change
      end
    end

    context 'when modifying an admin user to become locked' do
      before do
        User.find(admin.id).locked!
      end

      it_behaves_like 'expected entries' do
        let(:expected_excluded) do
          [
            [admin, nil, 'add_project'],
            [admin, private_project, 'view_work_packages'],
            [admin, private_project, 'view_project'],
            [admin, memberless_private_project, 'view_work_packages']
          ]
        end
      end
    end
  end

  context 'when updating a role' do
    context 'when changing the permissions of a member role' do
      before do
        role.permissions = %w[add_work_packages archive_project]
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, private_project, 'archive_project']
          ]
        end
        let(:expected_excluded) do
          [
            [user, private_project, 'view_work_packages']
          ]
        end
      end
    end

    context 'when changing the permissions of a global role' do
      before do
        global_role.permissions = %w[create_backup]
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, nil, 'create_backup']
          ]
        end
        let(:expected_excluded) do
          [
            [user, nil, 'add_project']
          ]
        end
      end
    end

    context 'when changing the permissions of the non member role' do
      before do
        non_member_role.permissions = %w[add_work_packages edit_work_package_notes]
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [user, public_project, 'edit_work_package_notes']
          ]
        end
        let(:expected_excluded) do
          [
            [user, public_project, 'view_work_packages']
          ]
        end
      end
    end

    context 'when changing the permissions of the anonymous role' do
      before do
        anonymous_role.permissions = %w[add_work_packages edit_work_package_notes]
      end

      it_behaves_like 'expected entries' do
        let(:expected_included) do
          [
            [anonymous_user, public_project, 'edit_work_package_notes']
          ]
        end
        let(:expected_excluded) do
          [
            [anonymous_user, public_project, 'view_work_packages']
          ]
        end
      end
    end
  end
end

# TODO archiving of a project
# * public
# * private
