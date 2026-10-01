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

RSpec.describe "Project creation wizard submission settings", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  let!(:status1) { create(:status, name: "New") }
  let!(:status2) { create(:status, name: "In Progress") }
  let!(:role) { create(:project_role) }
  let!(:type) { create(:type, name: "Task") }
  let!(:type2) { create(:type, name: "Bug") }
  let!(:user_custom_field) { create(:user_project_custom_field, name: "Project Manager", multi_value: false) }
  let!(:multi_value_user_custom_field) { create(:user_project_custom_field, name: "Project Teams", multi_value: true) }
  let!(:project) do
    create(:project, types: [type, type2], project_creation_wizard_enabled: true).tap do |p|
      p.project_custom_fields << user_custom_field
      p.project_custom_fields << multi_value_user_custom_field
    end
  end
  let(:submission_page) { Pages::Projects::Settings::CreationWizard.new(project, tab: "submission") }

  current_user { admin }

  before do
    create(:workflow, type:, role:, old_status: status1, new_status: status2)
    create(:workflow, type:, role:, old_status: status2, new_status: status1)
    create(:workflow, type: type2, role:, old_status: status1, new_status: status1)
  end

  describe "configuring submission settings" do
    it "allows admin to configure submission form settings" do
      submission_page.visit!

      comment_field = TextEditorField.new(
        page,
        "Work package comment",
        selector: test_selector("augmented-text-area-project_creation_wizard_work_package_comment")
      )
      notification_field = TextEditorField.new(
        page,
        "Confirmation email text",
        selector: test_selector("augmented-text-area-project_creation_wizard_notification_text")
      )

      expect(page).to have_select("Work package type")
      expect(page).to have_select("Status when submitted")
      expect(page).to have_field("Assignee when submitted")
      expect(page).to have_field("Send confirmation email to the user who submitted the project initiation request")

      select "Task", from: "Work package type"

      sleep 1 # wait_for_network_idle is flaky

      select "In Progress", from: "Status when submitted"

      autocompleter = page.find("opce-autocompleter")
      select_autocomplete(autocompleter, query: user_custom_field.name)

      comment_field.set_value("A project initiation request has been submitted.")

      check "Send confirmation email to the user who submitted the project initiation request"
      notification_field.set_value("Thank you for submitting your project request.")

      click_button "Save"

      expect_and_dismiss_flash(message: "Successful update.")

      project.reload
      expect(project.project_creation_wizard_work_package_type_id).to eq(type.id)
      expect(project.project_creation_wizard_status_when_submitted_id).to eq(status2.id)
      expect(project.project_creation_wizard_assignee_custom_field_id).to eq(user_custom_field.id)
      expect(project.project_creation_wizard_work_package_comment).to include("A project initiation request has been submitted.")
      expect(project.project_creation_wizard_send_confirmation_email).to be true
      expect(project.project_creation_wizard_notification_text).to include("Thank you for submitting your project request.")
    end

    it "shows and hides confirmation email text based on checkbox" do
      submission_page.visit!

      expect(page).to have_css(".ck-content", visible: :visible, count: 1)

      check "Send confirmation email to the user who submitted the project initiation request"
      expect(page).to have_css(".ck-content", visible: :visible, count: 2)

      uncheck "Send confirmation email to the user who submitted the project initiation request"
      expect(page).to have_css(".ck-content", visible: :visible, count: 1)
    end

    it "only shows single-select user custom fields in assignee dropdown" do
      submission_page.visit!

      autocompleter = page.find("opce-autocompleter")
      autocompleter.click

      expect(page).to have_text(user_custom_field.name)
      expect(page).to have_no_text(multi_value_user_custom_field.name)
    end
  end
end
