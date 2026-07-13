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

RSpec.describe "Project creation wizard from a template",
               :js,
               :with_cuprite,
               with_good_job_batches: [CopyProjectJob, SendCopyProjectStatusEmailJob] do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  # Role for template access - only copy_projects permission
  shared_let(:template_role) do
    create(:project_role, permissions: %i[copy_projects])
  end

  # Role assigned to users in newly created projects - only wizard permissions, NO add_work_packages
  shared_let(:new_project_role) do
    create(:project_creator_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end

  # Role for the assignee user - assigned via the user custom field role assignment
  # This role gives work_package_assigned permission needed for artifact WP creation
  shared_let(:assignee_role) do
    create(:project_role, permissions: %i[work_package_assigned view_work_packages])
  end

  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:status_in_progress) { create(:status, name: "In Progress") }
  shared_let(:type) { create(:type, name: "Project initiation") }
  shared_let(:default_priority) { create(:default_priority) }

  shared_let(:workflow) do
    create(:workflow,
           type:,
           role: assignee_role,
           old_status: status_new,
           new_status: status_in_progress)
  end

  shared_let(:section) do
    create(:project_custom_field_section, name: "Project Information")
  end

  shared_let(:string_custom_field) do
    create(:string_project_custom_field,
           name: "Project Code",
           project_custom_field_section: section)
  end

  shared_let(:user_custom_field) do
    create(:user_project_custom_field,
           name: "Project Validator",
           project_custom_field_section: section,
           role_id: assignee_role.id)
  end

  shared_let(:user_assignee) do
    create(:user, firstname: "Assignee", lastname: "User")
  end

  shared_let(:template) do
    create(:template_project,
           name: "Wizard Template",
           types: [type],
           project_creation_wizard_enabled: true,
           project_creation_wizard_work_package_type_id: type.id,
           project_creation_wizard_status_when_submitted_id: status_new.id,
           project_creation_wizard_assignee_custom_field_id: user_custom_field.id)
  end

  # Enable custom fields for the template with wizard enabled
  shared_let(:string_cf_mapping) do
    create(:project_custom_field_project_mapping,
           project: template,
           project_custom_field: string_custom_field,
           creation_wizard: true)
  end

  shared_let(:user_cf_mapping) do
    create(:project_custom_field_project_mapping,
           project: template,
           project_custom_field: user_custom_field,
           creation_wizard: true)
  end

  # User with only copy_projects on template, and add_project globally
  # Will get new_project_role in the created project (which lacks add_work_packages)
  current_user do
    create(:user,
           firstname: "Regular",
           lastname: "User",
           member_with_roles: { template => template_role },
           global_permissions: %i[add_project view_all_principals])
  end

  before do
    # Configure the role that new project creators get
    allow(Setting)
      .to receive(:new_project_user_role_id)
            .and_return(new_project_role.id.to_s)
  end

  it "creates a project from template and completes the wizard, " \
     "creating an artifact work package despite lacking add_work_packages permission" do
    # Verify user does NOT have add_work_packages permission through their role
    expect(new_project_role.permissions).not_to include(:add_work_packages)

    # Verify the user custom field has role assignment configured
    expect(user_custom_field.role_id).to eq(assignee_role.id)

    # Start project creation from template
    visit new_project_path(template_id: template.id)

    # Step 2: Project details
    expect(page).to have_heading "New project"
    fill_in "Name", with: "My New Project"

    click_on "Complete"

    # Background job dialog appears
    expect(page).to have_dialog "Background job status"

    within_dialog "Background job status" do
      expect(page).to have_heading "Applying template"
    end

    # Run background jobs
    GoodJob.perform_inline

    # Should redirect to the creation wizard (because project_creation_wizard_enabled is true)
    expect(page).to have_current_path(/\/projects\/my-new-project\/creation_wizard/, wait: 20)

    # Verify we're on the wizard page
    expect(page).to have_css("h3", text: "Project Information")

    # Find the created project
    project = Project.find_by(identifier: "my-new-project")
    expect(project).to be_present

    # Verify user is a member with the new_project_role (no add_work_packages)
    user_member = project.members.find_by(user_id: current_user.id)
    expect(user_member).to be_present
    expect(user_member.roles).to include(new_project_role)
    expect(current_user).not_to be_allowed_in_project(:add_work_packages, project)

    # Fill in the wizard fields
    fill_in "Project Code", with: "NEW-001"

    # Select the assignee user - this should also assign them the assignee_role
    # via the CustomFieldsRole mechanism since user_custom_field has role_id set
    select_autocomplete page.find("[data-custom-field-id='#{user_custom_field.id}']"),
                        results_selector: "body",
                        query: user_assignee.name

    # Complete the wizard - this should create the artifact work package
    # via User.execute_as_admin despite lacking add_work_packages permission
    click_button "Complete"

    expect(page).to have_text("Project attributes saved and artifact work package created successfully.")

    # Verify we're redirected to the artifact work package
    project.reload
    expect(project.project_creation_wizard_artifact_work_package_id).to be_present
    artifact_wp = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
    artifact_page = Pages::FullWorkPackage.new(artifact_wp)
    artifact_page.expect_current_path

    # Verify the work package was created correctly
    expect(artifact_wp).to be_present
    expect(artifact_wp.type).to eq(type)
    expect(artifact_wp.status).to eq(status_new)
    expect(artifact_wp.assigned_to).to eq(user_assignee)

    # Verify custom field values were saved
    expect(project.typed_custom_value_for(string_custom_field)).to eq("NEW-001")
    expect(project.typed_custom_value_for(user_custom_field)).to eq(user_assignee)

    # Verify the assignee was added as a member via the role assignment from the custom field
    assignee_member = project.members.find_by(user_id: user_assignee.id)
    expect(assignee_member).to be_present
    expect(assignee_member.roles).to include(assignee_role)

    expect(Attachment.count)
      .to be 1
    artifact = artifact_wp.attachments.first
    pdf_timestamp = artifact_wp.updated_at.strftime("%Y-%m-%d_%H-%M")
    expect(artifact.filename)
      .to eq("#{project.identifier}_Project_creation_wizard_#{status_new.name}_#{pdf_timestamp}.pdf")
  end
end
