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

RSpec.describe "Workflow usage banner", :js do
  include Workflows::EditHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:statuses) { create_list(:status, 2) }

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:other_type) { create(:type, name: "Task") }

  before { login_as admin }

  def workflow = type.default_variant.workflow

  context "when a single type uses the workflow" do
    it "says so on the workflow page, and the tab names the workflow" do
      visit edit_workflow_path(workflow)
      expect(page).to have_text("This workflow is used by 1 type. Changes apply to it.")

      visit_workflow_edit(roles: [role])
      within_test_selector("workflow-selector") { expect(page).to have_text(workflow.name) }
    end
  end

  context "when several types use the workflow" do
    before { other_type.default_variant.update!(workflow:) }

    it "counts the types" do
      visit edit_workflow_path(workflow)

      expect(page).to have_text("This workflow is used by 2 types. Changes apply to all of them.")
    end
  end

  context "when a named variant uses the workflow too" do
    before { create(:type_variant, type: other_type, variant_name: "Hardware").update!(workflow:) }

    it "says types and variants rather than types alone" do
      visit edit_workflow_path(workflow)

      expect(page).to have_text("This workflow is used by 2 types and variants.")
    end

    it "lists the dependent types and variants in a dialog that links to them" do
      visit edit_workflow_path(workflow)
      click_on "View dependent types"

      within("dialog#workflow-usage-dialog") do
        expect(page).to have_css("strong", text: workflow.name)

        within_test_selector("workflow-usage-types") do
          expect(page).to have_link("Bug")
          expect(page).to have_no_link("Task")
        end

        within_test_selector("workflow-usage-variants") do
          expect(page).to have_link("Hardware")
          expect(page).to have_text("Variant of Task")
        end

        click_on "Hardware"
      end

      expect(page).to have_current_path(/types\/#{other_type.id}\/variants\/\d+\/workflow\/edit/)
    end
  end

  context "when nothing uses the workflow" do
    it "says so" do
      visit edit_workflow_path(create(:named_workflow, name: "Spare flow"))

      expect(page).to have_text("No type or variant uses this workflow yet.")
    end
  end

  it "names the workflow on the type tab and shows its transitions read only" do
    other_type.default_variant.update!(workflow:)
    create(:workflow, workflow:, role:, old_status: statuses[0], new_status: statuses[1])

    visit_workflow_edit(roles: [role])

    within_test_selector("workflow-selector") { expect(page).to have_text(workflow.name) }
    expect(page).to have_no_button("Save")
    expect(page).to have_field(workflow_checkbox(0, 1), checked: true, disabled: true)
  end

  it "stays editable on its own page even when another type shares the workflow" do
    other_type.default_variant.update!(workflow:)
    create(:workflow, workflow:, role:, old_status: statuses[0], new_status: statuses[1])

    visit_workflow_page(roles: [role])

    expect(page).to have_button("Save")
    expect(page).to have_field(workflow_checkbox(0, 1), checked: true, disabled: false)

    uncheck workflow_checkbox(0, 1)
    click_on "Save"

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(workflow.reload.status_transitions).to be_empty
  end
end
