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

RSpec.describe Capabilities::Scopes::Default do
  # we focus on the non current user capabilities to make the tests easier to understand
  subject(:scope) { Capability.default.where(principal_id: user.id) }

  shared_let(:project) { create(:project, enabled_module_names: []) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) { create(:user) }

  let(:member_permissions) { %i[] }
  let(:global_permissions) { %i[] }
  let(:work_package_permissions) { %i[] }
  let(:non_member_permissions) { %i[] }
  let(:anonymous_permissions) { %i[] }
  let(:role) do
    create(:project_role, permissions: member_permissions)
  end
  let(:global_role) do
    create(:global_role, permissions: global_permissions)
  end
  let(:global_member) do
    create(:global_member,
           principal: user,
           roles: [global_role])
  end
  let(:work_package_role) { create(:work_package_role, permissions: work_package_permissions) }
  let(:work_package_member) do
    create(:member, principal: user, project:, entity: work_package, roles: [work_package_role])
  end

  let(:member) do
    create(:member,
           principal: user,
           roles: [role],
           project:)
  end
  let(:non_member_role) do
    create(:non_member,
           permissions: non_member_permissions)
  end
  let(:anonymous_role) do
    create(:anonymous_role,
           permissions: anonymous_permissions)
  end
  let(:members) { [] }

  shared_current_user do
    create(:admin)
  end

  shared_examples_for "consists of contract actions" do |with: "the expected actions"|
    it "includes #{with} for the scoped to user" do
      expect(scope.pluck(:action, :principal_id, :context_id))
        .to match_array(expected)
    end
  end

  shared_examples_for "is empty" do
    it "is empty for the scoped to user" do
      expect(scope)
        .to be_empty
    end
  end

  describe ".default" do
    before do
      members
    end

    context "without any members and non member roles" do
      include_examples "is empty"
    end

    context "with a member without any permissions" do
      let(:members) { [member] }

      include_examples "is empty"

      context "with a module being activated with a public permission" do
        before do
          project.enabled_module_names = ["activity"]
        end

        include_examples "consists of contract actions", with: "the actions of the public permission" do
          let(:expected) do
            [
              ["activities/read", user.id, project.id]
            ]
          end
        end
      end
    end

    context "with a global member without any permissions" do
      let(:members) { [global_member] }

      include_examples "is empty"
    end

    context "with a non member role without any permissions" do
      let(:members) { [non_member_role] }

      include_examples "is empty"

      context "with the project being public and having a module activated with a public permission" do
        before do
          project.update(public: true)
          project.enabled_module_names = ["activity"]
        end

        include_examples "consists of contract actions", with: "the actions of the public permission" do
          let(:expected) do
            [
              ["activities/read", user.id, project.id]
            ]
          end
        end
      end
    end

    context "with a global member with a global permission" do
      let(:global_permissions) { %i[manage_user] }
      let(:members) { [global_member] }

      include_examples "consists of contract actions", with: "the actions of the global permission" do
        let(:expected) do
          [
            ["users/read", user.id, nil],
            ["users/update", user.id, nil]
          ]
        end
      end

      context "with the user being locked" do
        before do
          user.locked!
        end

        include_examples "is empty"
      end
    end

    context "with a member with a project permission" do
      let(:member_permissions) { %i[manage_members] }
      let(:members) { [member] }

      include_examples "consists of contract actions", with: "the actions of the project permission" do
        let(:expected) do
          [["memberships/create", user.id, project.id],
           ["memberships/destroy", user.id, project.id],
           ["memberships/update", user.id, project.id]]
        end
      end

      context "with the user being locked" do
        before do
          user.locked!
        end

        include_examples "is empty"
      end
    end

    context "with the non member role with a project permission" do
      let(:non_member_permissions) { %i[view_members] }
      let(:members) { [non_member_role] }

      context "with the project being private" do
        include_examples "is empty"
      end

      context "with the project being public" do
        before do
          project.update(public: true)
        end

        include_examples "consists of contract actions", with: "the actions of the project permission" do
          let(:expected) do
            [
              ["memberships/read", user.id, project.id]
            ]
          end
        end

        context "with the user being locked" do
          before do
            user.locked!
          end

          include_examples "is empty"
        end
      end
    end

    context "with the anonymous role having a project permission in a public project" do
      let(:anonymous_permissions) { %i[view_members] }
      let(:members) { [anonymous_role] }

      before do
        project.update(public: true)
      end

      include_examples "is empty"
    end

    context "with the anonymous user without any permissions with a public project" do
      let(:anonymous_permissions) { %i[] }
      let!(:user) { create(:anonymous) }
      let(:members) { [anonymous_role] }

      before do
        project.update(public: true)
      end

      include_examples "is empty"

      context "with the project having a module activated with a public permission" do
        before do
          project.enabled_module_names = ["activity"]
        end

        include_examples "consists of contract actions", with: "the actions of the public permission" do
          let(:expected) do
            [
              ["activities/read", user.id, project.id]
            ]
          end
        end
      end
    end

    context "with the anonymous user with a project permission" do
      let(:anonymous_permissions) { %i[view_members] }
      let!(:user) { create(:anonymous) }
      let(:members) { [anonymous_role] }

      context "with the project being private" do
        include_examples "is empty"
      end

      context "with the project being public" do
        before do
          project.update(public: true)
        end

        include_examples "consists of contract actions", with: "the actions of the project permission" do
          let(:expected) do
            [
              ["memberships/read", user.id, project.id]
            ]
          end
        end
      end
    end

    context "with a member without any permissions and with the non member having a project permission" do
      let(:non_member_permissions) { %i[view_members] }
      let(:members) { [member, non_member_role] }

      context "when the project is private" do
        include_examples "is empty"
      end

      context "when the project is public" do
        before do
          project.update(public: true)
        end

        include_examples "is empty"
      end
    end

    context "with a member with a project permission and with the non member having another project permission" do
      # This setup is not possible as having the manage_members permission requires to have view_members via the dependency
      # but it is convenient to test.
      let(:non_member_permissions) { %i[view_members] }
      let(:member_permissions) { %i[manage_members] }
      let(:members) { [member, non_member_role] }

      context "when the project is private" do
        include_examples "consists of contract actions", with: "the capabilities granted by the user`s membership" do
          let(:expected) do
            [
              ["memberships/create", user.id, project.id],
              ["memberships/update", user.id, project.id],
              ["memberships/destroy", user.id, project.id]
            ]
          end
        end
      end

      context "when the project is public" do
        before do
          project.update(public: true)
        end

        include_examples "consists of contract actions", with: "the capabilities granted by the user`s membership" do
          let(:expected) do
            [
              ["memberships/create", user.id, project.id],
              ["memberships/update", user.id, project.id],
              ["memberships/destroy", user.id, project.id]
            ]
          end
        end
      end
    end

    context "with an admin" do
      before do
        user.update(admin: true)
      end

      context "with modules activated" do
        before do
          project.enabled_module_names = OpenProject::AccessControl.available_project_modules
        end

        include_examples "consists of contract actions",
                         with: "all actions of all permissions (project and global) grantable to admin" do
          let(:expected) do
            # This complicated and programmatic way is chosen so that the test can deal with additional actions being defined
            item = ->(namespace, action, global, module_name) {
              # We only expect contract actions for project modules that are enabled by default. In the
              # default edition the Bim module is not enabled by default for instance and thus it's contract
              # actions are not expected to be part of the default capabilities.
              return if module_name.present? && project.enabled_module_names.exclude?(module_name.to_s)

              ["#{API::Utilities::PropertyNameConverter.from_ar_name(namespace.to_s.singularize).pluralize.underscore}/#{action}",
               user.id,
               global ? nil : project.id]
            }

            OpenProject::AccessControl
              .contract_actions_map
              .select { |_, v| v[:grant_to_admin] }
              .map { |_, v| v[:actions].map { |vk, vv| vv.map { |vvv| item.call(vk, vvv, v[:global], v[:module_name]) } } }
              .flatten(2)
              .compact
              .uniq { |v| v.join(",") }
          end

          it "does not include actions of permissions non-grantable to admin" do
            expect(scope.pluck(:action)).not_to include("work_packages/assigned")
          end

          it "include actions from public permissions of activated modules" do
            expect(scope.pluck(:action)).to include("activities/read")
          end
        end
      end

      context "with modules deactivated" do
        before do
          project.enabled_modules = []
        end

        include_examples "consists of contract actions",
                         with: "all actions of all core permissions without the ones from modules" do
          let(:expected) do
            # This complicated and programmatic way is chosen so that the test can deal with additional actions being defined
            item = ->(namespace, action, global, module_name) {
              return if module_name.present?

              ["#{API::Utilities::PropertyNameConverter.from_ar_name(namespace.to_s.singularize).pluralize.underscore}/#{action}",
               user.id,
               global ? nil : project.id]
            }

            OpenProject::AccessControl
              .contract_actions_map
              .select { |_, v| v[:grant_to_admin] }
              .map { |_, v| v[:actions].map { |vk, vv| vv.map { |vvv| item.call(vk, vvv, v[:global], v[:module_name]) } } }
              .flatten(2)
              .compact
              .uniq { |v| v.join(",") }
          end
        end
      end

      context "with admin user being locked" do
        before do
          user.locked!
        end

        include_examples "is empty"
      end
    end

    context "without the current user being member in a project" do
      let(:member_permissions) { %i[manage_members] }
      let(:global_permissions) { %i[manage_user] }
      let(:members) { [member, global_member] }

      before do
        current_user.update(admin: false)
      end

      include_examples "is empty"
    end

    context "with the current user being member in a project" do
      let(:member_permissions) { %i[manage_members] }
      let(:global_permissions) { %i[manage_user] }
      let(:own_role) { create(:project_role, permissions: []) }
      let(:own_member) do
        create(:member,
               principal: current_user,
               roles: [own_role],
               project:)
      end
      let(:members) { [own_member, member, global_member] }

      before do
        current_user.update(admin: false)
      end

      include_examples "consists of contract actions" do
        let(:expected) do
          [
            ["memberships/create", user.id, project.id],
            ["memberships/destroy", user.id, project.id],
            ["memberships/update", user.id, project.id],
            ["users/read", user.id, nil],
            ["users/update", user.id, nil]
          ]
        end
      end
    end

    context "with a member with an action permission that is not granted to admin" do
      let(:member_permissions) { %i[work_package_assigned] }
      let(:members) { [member] }

      before do
        project.enabled_module_names = ["work_package_tracking"]
      end

      include_examples "consists of contract actions", with: "the actions of the permission" do
        let(:expected) do
          [
            ["work_packages/assigned", user.id, project.id]
          ]
        end
      end
    end

    context "with a member with a project permission and the project being archived" do
      let(:member_permissions) { %i[manage_members] }
      let(:members) { [member] }

      before do
        project.update(active: false)
      end

      include_examples "is empty"
    end

    context "with a work package membership" do
      before do
        project.enabled_module_names = ["work_package_tracking"]
      end

      let(:members) { [work_package_member] }

      context "when no permissions are associated with the role" do
        include_examples "is empty"
      end

      # TODO: This is temporary, we do not want the capabilities of the entity specific memberships to
      # show up in the capabilities API for now. This will change in the future
      context "when a permission is granted to the role" do
        let(:work_package_permissions) { [:view_work_packages] }

        include_examples "is empty"
      end

      context "for a public project" do
        let(:non_member_permissions) { %i[view_members] }
        let(:members) { [work_package_member, non_member_role] }

        before do
          project.update(public: true)
        end

        include_examples "consists of contract actions", with: "the actions of the non member role`s permission" do
          let(:expected) do
            [
              ["memberships/read", user.id, project.id]
            ]
          end
        end
      end
    end
  end
end
