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

RSpec.describe Authorization do
  let(:user) { build_stubbed(:user) }
  let(:action) { :view_work_packages }

  describe ".users" do
    it "calls Authorization::UserAllowedQuery" do
      expect(Authorization::UserAllowedQuery).to receive(:query).with(action, user)
      described_class.users(action, user)
    end
  end

  describe ".projects" do
    it "uses the .allowed_to scope on Project" do
      expect(Project).to receive(:allowed_to).with(user, action)
      described_class.projects(action, user)
    end
  end

  describe ".work_packages" do
    it "uses the .allowed_to scope on WorkPackage" do
      expect(WorkPackage).to receive(:allowed_to).with(user, action)
      described_class.work_packages(action, user)
    end
  end

  describe ".roles" do
    context "with a project" do
      let(:context) { build_stubbed(:project) }

      it "calls Authorization::UserProjectRolesQuery" do
        expect(Authorization::UserProjectRolesQuery).to receive(:query).with(user, context)
        described_class.roles(user, context)
      end
    end

    context "with a WorkPackage" do
      let(:context) { build_stubbed(:work_package) }

      it "calls Authorization::UserEntityRolesQuery" do
        expect(Authorization::UserEntityRolesQuery).to receive(:query).with(user, context)
        described_class.roles(user, context)
      end
    end

    context "without a context" do
      let(:context) { nil }

      it "calls Authorization::UserGlobalRolesQuery" do
        expect(Authorization::UserGlobalRolesQuery).to receive(:query).with(user)
        described_class.roles(user, context)
      end
    end
  end

  describe ".permissions_for" do
    let(:raise_on_unknown) { false }

    subject { described_class.permissions_for(action, raise_on_unknown:) }

    context "when called with a Permission object" do
      let(:action) { OpenProject::AccessControl.permission(:view_work_packages) }

      it "returns the Permission object wrapped in an array" do
        expect(subject).to eq([action])
      end
    end

    context "when called with an array of Permission objects" do
      let(:action) do
        [
          OpenProject::AccessControl.permission(:view_work_packages),
          OpenProject::AccessControl.permission(:edit_work_packages)
        ]
      end

      it "returns the Permission array" do
        expect(subject).to eq(action)
      end
    end

    context "when action is a Hash where controller starts with a slash" do
      let(:action) do
        { controller: "/work_packages", action: "show" }
      end

      it "returns all permissions that grant the permission to this URL" do
        # there might be more permissions granting access to this URL, we check for a known one
        expect(subject).to include(OpenProject::AccessControl.permission(:view_work_packages))
      end
    end

    context "when action is a Hash where controller does not start with a slash" do
      let(:action) do
        { controller: "work_packages", action: "show" }
      end

      it "returns all permissions that grant the permission to this URL" do
        # there might be more permissions granting access to this URL, we check for a known one
        expect(subject).to include(OpenProject::AccessControl.permission(:view_work_packages))
      end
    end

    context "when action is a permission name" do
      let(:action) { :view_work_packages }

      it "returns the Permission object wrapped in an array" do
        expect(subject).to eq([OpenProject::AccessControl.permission(:view_work_packages)])
      end
    end

    context "when action is an array of permission names" do
      let(:action) { %i[view_work_packages edit_work_packages] }

      it "returns the Permission object wrapped in an array" do
        expect(subject).to eq([
                                OpenProject::AccessControl.permission(:view_work_packages),
                                OpenProject::AccessControl.permission(:edit_work_packages)
                              ])
      end
    end

    context "when there is a permission but it is disabled" do
      let(:permission_object) { OpenProject::AccessControl.permission(:manage_user) }
      let(:action) { permission_object.name }

      around do |example|
        permission_object.disable!
        OpenProject::AccessControl.clear_caches
        example.run
      ensure
        permission_object.enable!
        OpenProject::AccessControl.clear_caches
      end

      it "returns an empty array and does not warn or raise" do
        expect(Rails.logger).not_to receive(:debug)
        expect do
          expect(subject).to be_empty
        end.not_to raise_error
      end
    end

    context "when there is no permission" do
      let(:action) { :this_permission_does_not_exist }

      context "and raise_on_unknown is false" do
        let(:raise_on_unknown) { false }

        it "warns and returns an empty array" do
          allow(Rails.logger).to receive(:debug)

          expect(subject).to be_empty

          expect(Rails.logger).to have_received(:debug) do |_, &block|
            expect(block.call).to include("Used permission \"#{action}\" that is not defined.")
          end
        end
      end

      context "and raise_on_unknown is true" do
        let(:raise_on_unknown) { true }

        it "warns and raises" do
          allow(Rails.logger).to receive(:debug)

          expect { subject }.to raise_error(Authorization::UnknownPermissionError)

          expect(Rails.logger).to have_received(:debug) do |_, &block|
            expect(block.call).to include("Used permission \"#{action}\" that is not defined.")
          end
        end
      end
    end

    describe ".contextual_permissions" do
      subject { described_class.contextual_permissions(action, context, raise_on_unknown:) }

      let(:raise_on_unknown) { false }
      let(:context) { nil }

      let(:global_permission) { OpenProject::AccessControl.permission(:manage_user) }
      let(:project_permission) { OpenProject::AccessControl.permission(:manage_members) }
      let(:project_and_work_package_permission) { OpenProject::AccessControl.permission(:view_work_packages) }

      let(:returned_permissions) do
        [
          global_permission,
          project_permission,
          project_and_work_package_permission
        ]
      end

      before do
        allow(described_class).to receive(:permissions_for).and_return(returned_permissions)
      end

      context "with global context" do
        let(:context) { :global }

        context "when a global permission is part of the returned permissions" do
          it "returns only the global permission" do
            expect(subject).to eq([global_permission])
          end
        end

        context "when no global permission is part of the returned permissions" do
          let(:returned_permissions) { [project_permission, project_and_work_package_permission] }

          it "raises an IllegalPermissionContextError" do
            expect { subject }.to raise_error(Authorization::IllegalPermissionContextError)
          end
        end
      end

      context "with project context" do
        let(:context) { :project }

        context "when a project permission is part of the returned permissions" do
          it "returns only the project permissions" do
            expect(subject).to eq([project_permission, project_and_work_package_permission])
          end
        end

        context "when no project permission is part of the returned permissions" do
          let(:returned_permissions) { [global_permission] }

          it "raises an IllegalPermissionContextError" do
            expect { subject }.to raise_error(Authorization::IllegalPermissionContextError)
          end
        end
      end

      context "with work package context" do
        let(:context) { :work_package }

        context "when a work package permission is part of the returned permissions" do
          it "returns only the work package permission" do
            expect(subject).to eq([project_and_work_package_permission])
          end
        end

        context "when no work package permission is part of the returned permissions" do
          let(:returned_permissions) { [global_permission, project_permission] }

          it "raises an IllegalPermissionContextError" do
            expect { subject }.to raise_error(Authorization::IllegalPermissionContextError)
          end
        end
      end
    end
  end
end
