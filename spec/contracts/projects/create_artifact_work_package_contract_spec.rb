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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Projects::CreateArtifactWorkPackageContract, :check_errors_i18n do
  include_context "ModelContract shared context"

  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:status_in_progress) { create(:status, name: "In Progress") }
  shared_let(:type) { create(:type, name: "Project initiation") }
  shared_let(:user_custom_field) { create(:user_project_custom_field, name: "Project Manager") }
  shared_let(:user_assignee) { create(:user, firstname: "user_assignee") }
  shared_let(:current_user) { create(:user, lastname: "current_user") }
  shared_let(:role_for_user) { create(:project_role, permissions: %i[add_work_packages view_project_attributes]) }
  shared_let(:role_for_assignee) { create(:project_role, permissions: %i[work_package_assigned]) }
  shared_let(:project) do
    create(
      :project,
      types: [type],
      project_custom_fields: [user_custom_field],
      # project initiation request settings
      project_creation_wizard_enabled: true,
      project_creation_wizard_work_package_type_id: type.id,
      project_creation_wizard_status_when_submitted_id: status_new.id,
      project_creation_wizard_assignee_custom_field_id: user_custom_field.id,
      user_custom_field.attribute_name => user_assignee.id
    ).tap do |p|
      p.members << create(:member, principal: user_assignee, project: p, roles: [role_for_assignee])
      p.members << create(:member, principal: current_user, project: p, roles: [role_for_user])
    end
  end
  shared_let(:workflow_type_new_to_in_progress) do
    create(:workflow, type:, role: role_for_assignee, old_status: status_new, new_status: status_in_progress)
  end

  let(:contract) { described_class.new(project, current_user) }

  before do
    login_as current_user
  end

  context "with all project initiation request information filled correctly" do
    it_behaves_like "contract is valid"

    context "when the assignee is an admin" do
      before do
        user_assignee.update(admin: true)
      end

      it_behaves_like "contract is valid"
    end
  end

  context "with project initiation request disabled" do
    before do
      project.update(project_creation_wizard_enabled: false)
    end

    it_behaves_like "contract is invalid", base: :project_initiation_request_disabled

    context "without any project initiation request settings set" do
      before do
        project.update(project_creation_wizard_work_package_type_id: nil,
                       project_creation_wizard_status_when_submitted_id: nil,
                       project_creation_wizard_assignee_custom_field_id: nil)
      end

      # no other errors than 'project_initiation_request_disabled' are shown
      it_behaves_like "contract is invalid", base: :project_initiation_request_disabled,
                                             project_creation_wizard_work_package_type_id: [],
                                             project_creation_wizard_status_when_submitted_id: [],
                                             project_creation_wizard_assignee_custom_field_id: []
    end
  end

  context "with missing :add_work_packages permission" do
    before do
      role_for_user.role_permissions.where(permission: "add_work_packages").delete_all
    end

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with unset work package type" do
    before do
      project.update!(project_creation_wizard_work_package_type_id: nil)
      project.project_creation_wizard_default_work_package_type.destroy!
    end

    it_behaves_like "contract is invalid", project_creation_wizard_work_package_type_id: :blank
  end

  context "with unallowed work package type for the project" do
    let(:other_type) { create(:type, name: "Other type") }

    before do
      project.update(project_creation_wizard_work_package_type_id: other_type.id)
    end

    it_behaves_like "contract is invalid", project_creation_wizard_work_package_type_id: :inclusion
  end

  context "with unset work package status" do
    before do
      project.update!(project_creation_wizard_status_when_submitted_id: nil)
      project.project_creation_wizard_default_status_when_submitted.destroy!
    end

    it_behaves_like "contract is invalid", project_creation_wizard_status_when_submitted_id: :blank
  end

  context "with unallowed work package status for the type" do
    let(:other_status) { create(:status, name: "Other status") }

    before do
      project.update(project_creation_wizard_status_when_submitted_id: other_status.id)
    end

    it_behaves_like "contract is invalid", project_creation_wizard_status_when_submitted_id: :inclusion

    context "with unset work_package_type" do
      before do
        project.update!(project_creation_wizard_work_package_type_id: nil)
        project.project_creation_wizard_default_work_package_type.destroy!
      end

      it_behaves_like "contract is invalid", project_creation_wizard_work_package_type_id: :blank
    end
  end

  context "with 'Assignee when submitted' not set" do
    before do
      project.update(project_creation_wizard_assignee_custom_field_id: nil)
    end

    it_behaves_like "contract is valid"
  end

  context "with project attribute pointed by 'Assignee when submitted' not set" do
    before do
      project.send(user_custom_field.attribute_setter, nil)
      project.save!
    end

    it "has invalid contract with :blank error for the assignee custom field" do
      expect_contract_invalid(user_custom_field.attribute_name => :blank)
    end
  end

  context "with assignee not having the :work_package_assigned permission (cannot be assigned to a wp)" do
    before do
      role_for_assignee.role_permissions.where(permission: "work_package_assigned").delete_all
    end

    it "has invalid contract with :cannot_be_assigned_to_artifact_work_package error for the assignee custom field" do
      expect_contract_invalid(user_custom_field.attribute_name => :cannot_be_assigned_to_artifact_work_package)
    end
  end
end
