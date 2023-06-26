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

RSpec.describe ActivePermission do
  shared_let(:user) { create(:user) }
  shared_let(:anonymous_user) { create(:anonymous) }
  shared_let(:admin) { create(:admin) }
  shared_let(:non_member_user) { create(:user) }

  let(:private_project) do
    create(:project,
           public: false,
           active: project_active,
           enabled_module_names: enabled_modules)
  end
  let(:public_project) do
    create(:project,
           public: true,
           active: project_active,
           enabled_module_names: enabled_modules)
  end
  let(:project_active) { true }

  let(:role) do
    build(:role,
          permissions: member_permissions)
  end
  let(:global_role) do
    build(:global_role,
          permissions: global_permissions)
  end
  let!(:anonymous_role) do
    create(:anonymous_role,
           permissions: anonymous_permissions)
  end
  let!(:non_member_role) do
    create(:non_member,
           permissions: non_member_permissions)
  end
  let(:member_permissions) { ['view_work_packages'] }
  let(:anonymous_permissions) { ['view_work_packages'] }
  let(:non_member_permissions) { ['view_work_packages'] }
  let(:global_permissions) { ['add_project'] }
  let(:enabled_modules) { %i[work_package_tracking news] }
  let(:member) do
    create(:member,
           user:,
           roles: [role],
           project: private_project)
  end
  let(:global_member) do
    create(:global_member,
           user:,
           roles: [global_role])
  end

  describe '#create_for_member_projects' do
    subject do
      described_class.create_for_member_projects

      described_class.pluck(:user_id, :project_id, :permission)
    end

    before do
      member
    end

    context 'for a member in a private project for a granted permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for a member in a private project for a not granted permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'add_work_packages'])
      end
    end

    context 'for a member in a private project for a granted permission of an inactive module' do
      let(:enabled_modules) { %i[news] }

      it 'has an entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for a member in a private project for the public permission not within a module' do
      it 'has an entry' do
        expect(subject)
          .to include([user.id, private_project.id, 'view_project'])
      end
    end

    context 'for a member in a private project for the public permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([user.id, private_project.id, 'view_news'])
      end
    end

    context 'for a member in a private project for the public permission of an inactive module' do
      let(:enabled_modules) { %i[work_package_tracking] }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'view_news'])
      end
    end

    context 'for a non member in a private project' do
      it 'has no entry' do
        expect(subject.select { |user_id, _, _| user_id == non_member_user })
          .to be_empty
      end
    end

    context 'for a member in a private project for a granted permission of an active module for an invited user' do
      before do
        user.invited!
      end

      it 'has an entry' do
        expect(subject)
          .to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for a member in a private project for a granted permission of an active module for a registered user' do
      before do
        user.registered!
      end

      it 'has an entry' do
        expect(subject)
          .to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for a member in a private project for a granted permission of an active module for a locked user' do
      before do
        user.locked!
      end

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for a member in a private project for the public and global permission not within a module' do
      # This should not happen as it is a global permission put there might be faulty data.
      let(:member_permissions) { ['add_project'] }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'add_project'])
      end
    end

    context 'for a member in a private but archived project for a granted permission of an active module' do
      let(:project_active) { false }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'view_work_packages'])
      end
    end
  end

  describe '#create_for_admins_in_project' do
    before do
      private_project
    end

    subject do
      described_class.create_for_admins_in_project

      described_class.pluck(:user_id, :project_id, :permission)
    end

    context 'for an admin who is a not a member in a private project of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([admin.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for an admin who is a not a member in a private project of an inactive module' do
      let(:enabled_modules) { %i[news] }

      it 'has no entry' do
        expect(subject)
          .not_to include([admin.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for an admin who is a not a member in a private project of a non module permission' do
      it 'has an entry' do
        expect(subject)
          .to include([admin.id, private_project.id, 'view_project'])
      end
    end

    context 'for an admin who is a not a member in a private project of a non module permission not granted to admins' do
      it 'has no entry' do
        expect(subject)
          .not_to include([admin.id, private_project.id, 'work_packages_assigned'])
      end
    end

    context 'for an non admin who is a not a member in a private project of an active module' do
      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for an admin who is a not a member in a private project of an active module with the admin being invited' do
      before { admin.invited! }

      it 'has an entry' do
        expect(subject)
          .to include([admin.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for an admin who is a not a member in a private project of an active module with the admin being registered' do
      before { admin.registered! }

      it 'has an entry' do
        expect(subject)
          .to include([admin.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for an admin who is a not a member in a private project of an active module with the admin being locked' do
      before { admin.locked! }

      it 'has no entry' do
        expect(subject)
          .not_to include([admin.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for an admin and a global permission' do
      it 'has an entry' do
        expect(subject)
          .not_to include([admin.id, nil, 'add_project'])
      end
    end
  end

  describe '#create_for_admins_global' do
    subject do
      described_class.create_for_admins_global

      described_class.pluck(:user_id, :project_id, :permission)
    end

    context 'for an admin and a global permission' do
      it 'has an entry' do
        expect(subject)
          .to include([admin.id, nil, 'add_project'])
      end
    end

    context 'for an non admin and a global permission' do
      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, nil, 'add_project'])
      end
    end

    context 'for an admin and a project permission' do
      it 'has no entry' do
        expect(subject)
          .not_to include([admin.id, nil, 'view_work_packages'])
      end
    end

    context 'for a locked admin and a global permission' do
      before do
        admin.locked!
      end

      it 'has no entry' do
        expect(subject)
          .not_to include([admin.id, nil, 'add_project'])
      end
    end

    context 'for an invited admin and a global permission' do
      before do
        admin.invited!
      end

      it 'has an entry' do
        expect(subject)
          .to include([admin.id, nil, 'add_project'])
      end
    end

    context 'for a registered admin and a global permission' do
      before do
        admin.registered!
      end

      it 'has an entry' do
        expect(subject)
          .to include([admin.id, nil, 'add_project'])
      end
    end
  end

  describe '#create_for_member_global' do
    subject do
      described_class.create_for_member_global

      described_class.pluck(:user_id, :project_id, :permission)
    end

    before do
      global_member
    end

    context 'for a user with a global membership granting the permission' do
      it 'has an entry' do
        expect(subject)
          .to include([user.id, nil, 'add_project'])
      end
    end

    context 'for a user with a global membership not granting the permission' do
      let(:global_member) { %i[manage_user] }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, nil, 'add_project'])
      end
    end

    context 'for a user without a global membership granting the permission' do
      let(:global_member) { nil }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, nil, 'add_project'])
      end
    end

    context 'for an invited user with a global membership granting the permission' do
      before { user.invited! }

      it 'has an entry' do
        expect(subject)
          .to include([user.id, nil, 'add_project'])
      end
    end

    context 'for a registered user with a global membership granting the permission' do
      before { user.registered! }

      it 'has an entry' do
        expect(subject)
          .to include([user.id, nil, 'add_project'])
      end
    end

    context 'for a locked user with a global membership granting the permission' do
      before { user.locked! }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, nil, 'add_project'])
      end
    end
  end

  describe '#create_for_public_project' do
    subject do
      described_class.create_for_public_project

      described_class.pluck(:user_id, :project_id, :permission)
    end

    before do
      public_project
    end

    # TODO: archived project

    context 'for a user not member in a public project for a granted permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for a user member in a public project for a granted permission of an active module' do
      before do
        create(:member,
               user:,
               roles: [role],
               project: public_project)
      end

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for the anonymous user in a public project for a granted permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([anonymous_user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for a user not member in a public project for a public permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([user.id, public_project.id, 'view_news'])
      end
    end

    context 'for the anonymous user in a public project for a public permission of an active module' do
      it 'has an entry' do
        expect(subject)
          .to include([anonymous_user.id, public_project.id, 'view_news'])
      end
    end

    context 'for a user not member in a public project for a non granted permission of an active module' do
      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, public_project.id, 'add_work_packages'])
      end
    end

    context 'for the anonymous user in a public project for a non granted permission of an active module' do
      it 'has no entry' do
        expect(subject)
          .not_to include([anonymous_user.id, public_project.id, 'add_work_packages'])
      end
    end

    context 'for a user not member in a public project for a granted permission of an inactive module' do
      let(:enabled_modules) { %i[news] }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for the anonymous user in a public project for a granted permission of an inactive module' do
      let(:enabled_modules) { %i[news] }

      it 'has no entry' do
        expect(subject)
          .not_to include([anonymous_user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for a user not member in a private project for a granted permission of an active module' do
      before do
        private_project
      end

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, private_project.id, 'view_work_packages'])
      end
    end

    context 'for a user not member in a public and archived project for a granted permission of an active module' do
      let(:project_active) { false }

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for an invited user not member in a public project for a granted permission of an active module' do
      before do
        user.invited!
      end

      it 'has an entry' do
        expect(subject)
          .to include([user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for a registered user not member in a public project for a granted permission of an active module' do
      before do
        user.registered!
      end

      it 'has an entry' do
        expect(subject)
          .to include([user.id, public_project.id, 'view_work_packages'])
      end
    end

    context 'for a locked user not member in a public projct for a granted permission of an active module' do
      before do
        user.locked!
      end

      it 'has no entry' do
        expect(subject)
          .not_to include([user.id, public_project.id, 'view_work_packages'])
      end
    end
  end
end
