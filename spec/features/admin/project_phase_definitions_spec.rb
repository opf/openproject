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

RSpec.describe "Projects phase definition settings", :js do
  shared_let(:initiating_stage) { create(:project_phase_definition, name: "Initiating") }
  shared_let(:executing_stage) do
    create(:project_phase_definition, name: "Executing", start_gate: true, start_gate_name: "Ready to Execute")
  end

  let(:definitions_page) { Pages::Admin::Settings::ProjectPhaseDefinitions.new }

  context "as non admin" do
    current_user { create(:user) }

    it "does not allow the user to access the page" do
      definitions_page.visit!

      definitions_page.expect_listed([])

      definitions_page.expect_flash(message: "You are not authorized to access this page", type: :error)
    end
  end

  context "as admin without activated enterprise token" do
    current_user { create(:admin) }

    it "allows viewing definitions" do
      definitions_page.visit!

      definitions_page.expect_listed(["Initiating", "Executing"])

      definitions_page.expect_no_controls
    end
  end

  context "as admin with activated enterprise token", with_ee: %i[customize_life_cycle] do
    current_user { create(:admin) }

    before do
      create(:color, name: "Azure", hexcode: "#0056b9")
      create(:color, name: "Gold", hexcode: "#ffd800")
    end

    it "allows managing definitions" do
      definitions_page.visit!
      definitions_page.expect_listed(["Initiating", "Executing"])

      # filtering
      definitions_page.filter_with("e")
      definitions_page.expect_listed(["Executing"])

      definitions_page.expect_no_ordering_controls

      definitions_page.clear_filter
      definitions_page.expect_listed(["Initiating", "Executing"])

      # editing steps
      definitions_page.click_definition("Initiating")

      definitions_page.expect_header_to_display("Initiating")

      fill_in "Name", with: "Starting"
      click_on "Update"

      definitions_page.click_definition_action("Executing", action: "Edit")
      fill_in "Name", with: "Processing"
      click_on "Update"

      definitions_page.expect_listed(["Starting", "Processing"])

      # creating steps
      definitions_page.add

      definitions_page.expect_header_to_display("New phase")

      fill_in "Name", with: "Imagining"
      definitions_page.select_color("Azure")
      click_on "Create"

      definitions_page.expect_and_dismiss_flash(message: "Successful creation.")

      definitions_page.expect_gates_mentioned_for("Imagining", "No gate")

      definitions_page.add
      fill_in "Name", with: "Initiating"
      definitions_page.select_color("Gold")

      check "Start phase gate"
      fill_in "Start phase gate name", with: "Ready to Initiate"
      check "Finish phase gate"
      fill_in "Finish phase gate name", with: "Finished initiating"

      click_on "Create"

      definitions_page.expect_and_dismiss_flash(message: "Successful creation.")

      definitions_page.expect_listed(["Starting", "Processing", "Imagining", "Initiating"])
      definitions_page.expect_gates_mentioned_for("Initiating", "Start and finish gate")

      # moving
      definitions_page.click_definition_action("Processing", action: "Move to bottom")
      wait_for_network_idle
      definitions_page.expect_listed(["Starting", "Imagining", "Initiating", "Processing"])

      definitions_page.click_definition_action("Initiating", action: "Move to top")
      wait_for_network_idle
      definitions_page.expect_listed(["Initiating", "Starting", "Imagining", "Processing"])

      definitions_page.click_definition_action("Starting", action: "Move down")
      wait_for_network_idle
      definitions_page.expect_listed(["Initiating", "Imagining", "Starting", "Processing"])

      definitions_page.click_definition_action("Starting", action: "Move up")
      wait_for_network_idle
      definitions_page.expect_listed(["Initiating", "Starting", "Imagining", "Processing"])

      definitions_page.drag_and_drop_list(from: 0, to: 3,
                                          elements: "[data-test-selector=project-phase-definition]",
                                          handler: ".DragHandle")
      wait_for_network_idle
      definitions_page.expect_listed(["Starting", "Imagining", "Processing", "Initiating"])

      definitions_page.reload!
      definitions_page.expect_listed(["Starting", "Imagining", "Processing", "Initiating"])

      # deleting
      accept_confirm I18n.t(:text_are_you_sure_with_project_life_cycle_step) do
        definitions_page.click_definition_action("Imagining", action: "Delete")
      end
      definitions_page.expect_listed(["Starting", "Processing", "Initiating"])
    end
  end
end
