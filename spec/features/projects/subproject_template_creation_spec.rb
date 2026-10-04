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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Creating subproject with predefined template from quick add menu",
               :js,
               with_good_job_batches: [CopyProjectJob, SendCopyProjectStatusEmailJob] do
  let(:quick_add) { Components::QuickAddMenu.new }
  let(:field) { FormFields::SelectFormField.new :parent }

  shared_let(:project_template) do
    create(:project,
           name: "Project Template",
           description: "A template for projects",
           templated: true,
           workspace_type: :project)
  end

  current_user do
    create(:user,
           member_with_permissions: {
             parent_project => %i[add_subprojects],
             project_template => %i[view_project copy_projects]
           })
  end

  describe "from a regular project" do
    let(:parent_project) { create(:project, workspace_type: :project) }

    context "when parent project has a subitem template configured" do
      before do
        create(:subproject_template_assignment,
               project: parent_project,
               template: project_template,
               workspace_type: :project)
      end

      it "skips step 1 and lands on step 2 with template pre-selected" do
        visit project_path(parent_project)

        quick_add.expect_visible
        quick_add.toggle
        quick_add.expect_add_project

        quick_add.click_link "Project"

        # Should have parent_id and workspace_type in URL
        expect(page).to have_current_path new_project_path(parent_id: parent_project.id, workspace_type: "project")

        # Should skip template selection (step 1) and go directly to step 2
        expect(page).to have_field("Name")
        expect(page).to have_no_text("Template project")

        # Parent field should be hidden, as it's prefilled
        field.expect_not_visible

        # Fill in project details and create
        fill_in "Name", with: "New Subproject"
        click_on "Complete"

        within_dialog "Background job status" do
          expect(page).to have_heading "Applying template"
          expect(page).to have_text "The job has been queued and will be processed shortly."
        end

        # Run background jobs twice: the background job which itself enqueues the mailer job
        GoodJob.perform_inline

        mail = ActionMailer::Base
          .deliveries
          .detect { |mail| mail.subject == "Created project New Subproject" }

        expect(mail).not_to be_nil
        expect(page).to have_current_path /\/projects\/new-subproject\/?/, wait: 20

        subproject = Project.find_by identifier: "new-subproject"
        expect(subproject.name).to eq "New Subproject"
        expect(subproject).not_to be_templated
        expect(subproject.parent).to eq(parent_project)
      end
    end

    context "when parent project has no subitem template configured" do
      it "shows step 1 for template selection" do
        visit project_path(parent_project)

        quick_add.expect_visible
        quick_add.toggle
        quick_add.click_link "Project"

        expect(page).to have_current_path new_project_path(parent_id: parent_project.id)

        expect(page).to have_text("Select a project template to work with the most common project management methods, or create a project from scratch.") # rubocop:disable Layout/LineLength
        expect(page).to have_text("Blank project")
        expect(page).to have_text("Project Template")
        click_on "Continue"

        expect(page).to have_field "Name"
        field.expect_not_visible
      end
    end
  end
end
