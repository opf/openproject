# --copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2022 the OpenProject GmbH
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

describe Permission do
  shared_let(:anonymous_role) { create(:anonymous_role) }
  shared_let(:non_member_role) { create(:non_member) }
  shared_let(:project) { create(:project) }
  shared_let(:public_project) { create(:public_project) }
  shared_let(:admin) { create(:admin) }
  shared_let(:logged_user) { create(:user) }
  shared_let(:anonymous) { create(:anonymous) }

  let(:member_permissions) { %i[view_work_packages work_package_assigned] }
  let(:global_member_permissions) { %i[add_project] }
  let(:member) do
    create(:member, project:, principal: logged_user, roles: [create(:role, permissions: member_permissions)])
  end
  let(:global_member) do
    create(:global_member, principal: logged_user, roles: [create(:role, permissions: global_member_permissions)])
  end

  let(:module_permission) { 'view_work_packages' }
  let(:public_permission) { 'view_project' }
  let(:public_module_permission) { 'view_news' }
  let(:global_permission) { 'add_project' }
  let(:non_admin_module_permission) { 'work_package_assigned' }

  describe 'entries (in database view)' do
    shared_examples_for 'expected entries' do
      let(:expected_included) { [] }
      let(:expected_excluded) { [] }

      it 'contains the expected sets of permissions', :aggregate_failures do
        if expected_included.any?
          expect(described_class.where(user:).pluck(:project_id, :permission))
            .to include(*expected_included)
        end

        if expected_excluded.any?
          expect(described_class.where(user:).pluck(:project_id, :permission))
            .not_to include(*expected_excluded)
        end
      end
    end

    context 'without even an admin' do
      before do
        NotificationSetting.delete_all
        User.delete_all
      end

      it 'is empty' do
        expect(described_class.all)
          .to be_empty
      end
    end

    context 'with the user not being member' do
      # Admin will receive all permission within the private and the public project
      # with the exception being permissions, flagged to not be granted to admins.
      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [project.id, module_permission],
            [public_project.id, module_permission],
            [project.id, public_permission],
            [public_project.id, public_permission],
            [project.id, public_module_permission],
            [public_project.id, public_module_permission],
            [nil, global_permission]
          ]
        end
        let(:expected_exclude) do
          [
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is no member of the project and thus receives the permissions
      # of the non member role only in the public project.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_included) do
          [
            [public_project.id, public_permission],
            [public_project.id, public_module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # Anonymous will only receive permissions granted by the anonymous role.
      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_included) do
          [
            [public_project.id, public_permission],
            [public_project.id, public_module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user not being member
             with non members and anonymous having a module permission (view_work_packages)' do
      before do
        anonymous_role.add_permission!(module_permission)
        non_member_role.add_permission!(module_permission)
      end

      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [project.id, module_permission],
            [public_project.id, module_permission],
            [project.id, public_permission],
            [public_project.id, public_permission],
            [project.id, public_module_permission],
            [public_project.id, public_module_permission],
            [nil, global_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # Logged in user will receive permissions granted by the non member role.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_included) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # Anonymous will only receive permissions granted by the anonymous role.
      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_included) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member' do
      before do
        member
      end

      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [project.id, module_permission],
            [public_project.id, module_permission],
            [project.id, public_permission],
            [public_project.id, public_permission],
            [project.id, public_module_permission],
            [public_project.id, public_module_permission],
            [nil, global_permission]
          ]
        end
        let(:expected_exclude) do
          [
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is a member of project with the :view_work_packages permission
      # and will therefore have that permission in the project but also the public permissions
      # that any member receives.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_included) do
          [
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [project.id, non_admin_module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [nil, global_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_included) do
          [
            [public_project.id, public_permission],
            [public_project.id, public_module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member
             with the membership having less permissions than non member or anonymous role' do
      let(:member_permissions) { [] }

      before do
        member

        non_member_role.add_permission! module_permission
        anonymous_role.add_permission! module_permission
      end

      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [project.id, module_permission],
            [public_project.id, module_permission],
            [project.id, public_permission],
            [public_project.id, public_permission],
            [project.id, public_module_permission],
            [public_project.id, public_module_permission],
            [nil, global_permission]
          ]
        end
        let(:expected_exclude) do
          [
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is a member of project with no explicit permissions
      # and will therefore only have public permissions within the project.
      # But since the non member role has more permissions, the user has that permission in the
      # public project.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_included) do
          [
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [public_project.id, module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [project.id, module_permission],
            [nil, global_permission],
            [public_project.id, non_admin_module_permission],
            [project.id, non_admin_module_permission]
          ]
        end
      end

      # Anonymous will have the permissions in the public project granted to the anonymous role.
      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_included) do
          [
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [public_project.id, module_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member
             with the project not being active' do
      before do
        member

        project.update_column(:active, false)
        public_project.update_column(:active, false)
      end

      # Admin will not have any project permissions there since the projects are archived.
      # But will have the global permission.
      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [nil, global_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is a member of project with the :view_work_packages permission, but
      # will in effect not have any permissions there since the projects are archived.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # Anonymous will not have any permissions there since the projects are archived.
      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member
             with the user being locked' do
      before do
        member

        logged_user.locked!
        admin.locked!
      end

      # Admin will not have any permissions since it is locked.
      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is a member of project with the :view_work_packages permission, but
      # will in effect not have any permissions as it is locked.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member
             with the user being invited' do
      before do
        member

        logged_user.invited!
        admin.invited!
      end

      # Admin will not have any permissions since it is only invited.
      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is a member of project with the :view_work_packages permission, but
      # will in effect not have any permissions as it is only invited.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member
             with the user being registered' do
      before do
        member

        logged_user.registered!
        admin.registered!
      end

      # Admin will not have any permissions since it is only registered.
      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      # The logged in user is a member of project with the :view_work_packages permission, but
      # will in effect not have any permissions as it is only registered.
      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being member
             with the project module being disabled' do
      before do
        member

        project.enabled_module_names -= %w(work_package_tracking news)
        public_project.enabled_module_names -= %w(work_package_tracking news)
      end

      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [project.id, public_permission],
            [public_project.id, public_permission],
            [nil, global_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_module_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_included) do
          [
            [project.id, public_permission],
            [public_project.id, public_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_included) do
          [
            [public_project.id, public_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [nil, global_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end

    context 'with the user being global member' do
      before do
        global_member
      end

      it_behaves_like 'expected entries' do
        let(:user) { admin }
        let(:expected_included) do
          [
            [project.id, public_permission],
            [public_project.id, public_permission],
            [public_project.id, module_permission],
            [public_project.id, public_module_permission],
            [project.id, module_permission],
            [project.id, public_module_permission],
            [nil, global_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      it_behaves_like 'expected entries' do
        let(:user) { logged_user }
        let(:expected_included) do
          [
            [nil, global_permission],
            [public_project.id, public_module_permission],
            [public_project.id, public_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [project.id, public_permission],
            [project.id, module_permission],
            [project.id, public_module_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end

      it_behaves_like 'expected entries' do
        let(:user) { anonymous }
        let(:expected_included) do
          [
            [public_project.id, public_module_permission],
            [public_project.id, public_permission]
          ]
        end
        let(:expected_excluded) do
          [
            [public_project.id, module_permission],
            [project.id, module_permission],
            [project.id, public_permission],
            [project.id, public_module_permission],
            [project.id, non_admin_module_permission],
            [public_project.id, non_admin_module_permission]
          ]
        end
      end
    end
  end
end
