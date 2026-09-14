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

RSpec.describe "Project templates", :js, with_good_job_batches: [CopyProjectJob, SendCopyProjectStatusEmailJob] do
  describe "making project a template" do
    let(:project) { create(:project) }

    shared_let(:admin) { create(:admin) }

    before do
      login_as admin
    end

    it "can make the project a template from settings" do
      visit project_settings_general_path(project)

      # Make a template
      page.find_test_selector("project-settings-more-menu").click
      page.find_test_selector("project-settings--mark-template", text: "Set as template").click
      expect_and_dismiss_flash(message: "Successful update.")

      project.reload
      expect(project).to be_templated

      # unset template
      page.find_test_selector("project-settings-more-menu").click
      page.find_test_selector("project-settings--mark-template", text: "Remove from templates").click

      project.reload
      expect(project).not_to be_templated
    end
  end

  describe "instantiating templates" do
    let!(:template) do
      create(:template_project,
             :with_internal_wiki,
             status_code: "on_track",
             status_explanation: "some explanation",
             name: "My template",
             enabled_module_names: %w[work_package_tracking])
    end
    let!(:other_project) { create(:project, name: "Some other project") }
    let!(:work_package) { create(:work_package, project: template) }
    let!(:wiki_page) { create(:wiki_page, wiki: template.wiki) }

    let!(:role) do
      create(:project_role, permissions: %i[view_project view_work_packages copy_projects add_subprojects])
    end
    let!(:global_permissions) do
      %i[add_project]
    end
    let(:status_field_selector) { 'ckeditor-augmented-textarea[textarea-selector="#project_status_explanation"]' }
    let(:status_description) { Components::WysiwygEditor.new status_field_selector }

    let!(:other_user) do
      create(:user, member_with_roles: { template => role })
    end

    current_user do
      create(:user,
             member_with_roles: { template => role, other_project => role },
             global_permissions:)
    end

    it "does not show a special heading when the project initiation feature is enabled" do
      visit new_project_path(template_id: template.id)
      expect(page).to have_heading "New project"
    end

    it "can instantiate the project with the copy permission" do
      visit new_project_path(template_id: template.id)

      # Step 2: Project details
      expect(page).to have_heading "New project"
      expect(page).to have_text("2 of 2")
      fill_in "Name", with: "Foo bar"

      click_on "Complete"

      expect(page).to have_dialog "Background job status"

      within_dialog "Background job status" do
        expect(page).to have_heading "Applying template"
        expect(page).to have_text "The job has been queued and will be processed shortly."
      end

      # Run background jobs twice: the background job which itself enqueues the mailer job
      GoodJob.perform_inline

      mail = ActionMailer::Base
        .deliveries
        .detect { |mail| mail.subject == "Created project Foo bar" }

      expect(mail).not_to be_nil

      expect(page).to have_current_path /\/projects\/foo-bar\/?/, wait: 20

      project = Project.find_by identifier: "foo-bar"
      expect(project.name).to eq "Foo bar"
      expect(project).not_to be_templated
      # Members are copied by default from the template
      expect(project.users).to contain_exactly(current_user, other_user)
      expect(project.enabled_module_names.sort).to eq(template.enabled_module_names.sort)

      wp_source = template.work_packages.first.attributes.except(*%w[id author_id project_id updated_at created_at])
      wp_target = project.work_packages.first.attributes.except(*%w[id author_id project_id updated_at created_at])
      expect(wp_target).to eq(wp_source)

      wiki_source = template.wiki.pages.first
      wiki_target = project.wiki.pages.first
      expect(wiki_source.title).to eq(wiki_target.title)
      expect(wiki_source.text).to eq(wiki_target.text)
    end

    it "skips custom field validation when creating from template" do
      # Create a required custom field on the template
      custom_field = create(:string_project_custom_field, is_required: true)
      template.project_custom_field_ids = [custom_field.id]

      visit new_project_path(template_id: template.id)

      # Step 2: Project details
      expect(page).to have_text("2 of 2")
      fill_in "Name", with: "Project from template"

      click_on "Complete"

      # Step 3: Custom fields - should not show custom field form when creating from template
      expect(page).to have_no_field custom_field.name

      # Templates submit automatically on step 3 since custom fields are skipped
      expect(page).to have_dialog "Background job status"

      GoodJob.perform_inline

      expect(page).to have_current_path /\/projects\/project-from-template\/?/, wait: 20

      # Project should be created successfully even though required custom field is empty
      project = Project.find_by(identifier: "project-from-template")
      expect(project).to be_present
      expect(project.template).to eq(template)
      expect(project.send(custom_field.attribute_getter)).to be_blank
    end
  end
end
