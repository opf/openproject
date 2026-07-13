# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

require "spec_helper"
require Rails.root.join("db/migrate/20250929070310_add_view_all_principals_permission_to_existing_roles")

RSpec.describe AddViewAllPrincipalsPermissionToExistingRoles, type: :model do
  let(:admin_user) { create(:admin) }
  let(:regular_user) { create(:user) }
  let(:project) { create(:project) }

  def migrate
    perform_enqueued_jobs do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
    end
  end

  describe "up migration" do
    context "when global roles have manage_user permission" do
      let(:global_role) { create(:global_role, name: "Staff Manager") }

      before do
        global_role.add_permission!(:manage_user)
      end

      it "adds view_all_users permission to global roles with manage_user" do
        expect(global_role.has_permission?(:view_all_principals)).to be false

        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        global_role.reload
        expect(global_role.has_permission?(:view_all_principals)).to be true
      end
    end

    context "when project roles have manage_members permission" do
      let(:project_role) { create(:project_role, name: "Project Manager") }
      let(:user_with_manage_members) { create(:user) }

      before do
        project_role.add_permission!(:manage_members)
        create(:member, project:, principal: user_with_manage_members, roles: [project_role])
      end

      it "creates a global role and assigns it to users with manage_members" do
        expect(GlobalRole.find_by(name: "View all users (migration)")).to be_nil
        expect(user_with_manage_members.members.where(project: nil)).to be_empty

        migrate

        migration_role = GlobalRole.find_by(name: "View all users (migration)")
        expect(migration_role).to be_present
        expect(migration_role.has_permission?(:view_all_principals)).to be true

        user_with_manage_members.reload
        global_membership = user_with_manage_members.members.find_by(project: nil)
        expect(global_membership.roles).to include(migration_role)
      end

      it "does not duplicate assignments for users already having the global role" do
        migrate

        # Run migration again
        migrate

        migration_role = GlobalRole.find_by(name: "View all users (migration)")
        user_with_manage_members.reload

        # Should only have one assignment
        expect(user_with_manage_members.members.where(project: nil).count).to eq(1)
        global_membership = user_with_manage_members.members.find_by(project: nil)
        expect(global_membership.roles).to include(migration_role)
      end
    end

    context "when users have manage_members in multiple projects" do
      let(:project_role) { create(:project_role, name: "Project Manager") }
      let(:user_with_multiple_projects) { create(:user) }
      let(:project2) { create(:project) }

      before do
        project_role.add_permission!(:manage_members)
        create(:member, project:, principal: user_with_multiple_projects, roles: [project_role])
        create(:member, project: project2, principal: user_with_multiple_projects, roles: [project_role])
      end

      it "assigns the global role only once per user" do
        migrate

        migration_role = GlobalRole.find_by(name: "View all users (migration)")
        user_with_multiple_projects.reload

        # Should have one global role assignment
        expect(user_with_multiple_projects.members.where(project: nil).count).to eq(1)
        global_membership = user_with_multiple_projects.members.find_by(project: nil)
        expect(global_membership.roles).to include(migration_role)
      end
    end

    context "when roles already have view_all_users permission" do
      let(:global_role) { create(:global_role, name: "Staff Manager") }

      before do
        global_role.add_permission!(:manage_user)
        global_role.add_permission!(:view_all_principals)
      end

      it "does not duplicate the permission" do
        initial_permissions = global_role.permissions.dup

        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        global_role.reload
        expect(global_role.permissions).to eq(initial_permissions)
      end
    end
  end

  describe "down migration" do
    let(:migration_role) { create(:global_role, name: "View all users (migration)") }
    let(:user_with_global_role) { create(:user) }

    before do
      migration_role.add_permission!(:view_all_principals)
      create(:member, project: nil, principal: user_with_global_role, roles: [migration_role])
    end

    it "removes the migration global role and its assignments" do
      expect(GlobalRole.find_by(name: "View all users (migration)")).to be_present
      expect(user_with_global_role.members.where(project: nil)).not_to be_empty

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(GlobalRole.find_by(name: "View all users (migration)")).to be_nil
      user_with_global_role.reload
      expect(user_with_global_role.members.where(project: nil)).to be_empty
    end

    it "removes view_all_users permission from global roles that had manage_user" do
      global_role = create(:global_role, name: "Staff Manager")
      global_role.add_permission!(:manage_user)
      global_role.add_permission!(:view_all_principals)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      global_role.reload
      expect(global_role.has_permission?(:view_all_principals)).to be false
      expect(global_role.has_permission?(:manage_user)).to be true
    end

    context "when migration role does not exist" do
      before do
        migration_role.destroy
      end

      it "does not raise an error" do
        expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) } }
          .not_to raise_error
      end
    end
  end

  describe "edge cases" do
    context "when user has both manage_user and manage_members permissions" do
      let(:global_role) { create(:global_role, name: "Staff Manager") }
      let(:project_role) { create(:project_role, name: "Project Manager") }
      let(:user_with_both) { create(:user) }

      before do
        global_role.add_permission!(:manage_user)
        project_role.add_permission!(:manage_members)

        create(:member, project: nil, principal: user_with_both, roles: [global_role])
        create(:member, project:, principal: user_with_both, roles: [project_role])
      end

      it "assigns the migration global role even if user already has view_all_users via global role" do
        migrate

        migration_role = GlobalRole.find_by(name: "View all users (migration)")
        user_with_both.reload

        # Should have both the original global role and the migration role
        global_membership = user_with_both.members.find_by(project: nil)
        expect(global_membership.roles).to include(global_role)
        expect(global_membership.roles).to include(migration_role)
      end
    end

    context "when project role has no permissions" do
      let(:empty_project_role) { create(:project_role, name: "Empty Role") }
      let(:user_with_empty_role) { create(:user) }

      before do
        create(:member, project:, principal: user_with_empty_role, roles: [empty_project_role])
      end

      it "does not assign the migration global role" do
        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        migration_role = GlobalRole.find_by(name: "View all users (migration)")
        user_with_empty_role.reload

        expect(user_with_empty_role.members.where(project: nil)).not_to include(migration_role) if migration_role
      end
    end
  end
end
