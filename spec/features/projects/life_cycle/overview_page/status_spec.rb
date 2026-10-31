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
require_relative "shared_context"

RSpec.describe "Change project phase status on project overview page", :js do
  include_context "with seeded projects and phases"

  let(:overview_page) { Pages::Projects::Show.new(project) }
  let(:permissions) { %i[view_project view_project_phases edit_project_phases] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:initial_statuses) { %w[open open open open] }
  let(:inactive_phases) { [] }

  current_user { user }

  before do
    project_life_cycles.zip(initial_statuses) { |phase, status| phase.update_columns(status:) }
    inactive_phases.each { it.update_columns(active: false) }

    overview_page.visit_page
  end

  def stored_statuses
    project_life_cycles.map { it.reload.status }
  end

  describe "permissions" do
    context "with permission to edit project phases" do
      it "shows enabled status buttons" do
        overview_page.within_life_cycle_sidebar do
          expect(page).to have_button("Open", disabled: false, count: 4)
        end
      end
    end

    context "with permission to view project phases only" do
      let(:permissions) { %i[view_project view_project_phases] }

      it "shows the phases without status buttons" do
        overview_page.within_life_cycle_sidebar do
          expect(page).to have_text(life_cycle_initiating.name)
          expect(page).to have_no_button("Open")
          expect(page).to have_no_css("action-menu")
        end
      end
    end

    context "with permission to edit the project but not its phases" do
      let(:permissions) { %i[view_project view_project_phases edit_project] }

      it "shows the phases without status buttons" do
        overview_page.within_life_cycle_sidebar do
          expect(page).to have_text(life_cycle_initiating.name)
          expect(page).to have_no_button("Open")
          expect(page).to have_no_css("action-menu")
        end
      end
    end
  end

  describe "changing the status of a phase" do
    context "when setting a phase to in progress" do
      it "completes the earlier phases, opens the later ones and refreshes all buttons" do
        overview_page.change_phase_status(life_cycle_executing, from: "Open", to: "In progress")

        expect_flash(message: I18n.t(:notice_successful_update))
        overview_page.expect_phase_status_buttons(project_life_cycles, "Completed", "Completed", "In progress", "Open")
        expect(stored_statuses).to eq %w[completed completed in_progress open]
      end
    end

    context "when setting a phase to completed" do
      let(:initial_statuses) { %w[completed in_progress open open] }

      it "completes the earlier phases and leaves the later ones untouched" do
        overview_page.change_phase_status(life_cycle_executing, from: "Open", to: "Completed")

        expect_flash(message: I18n.t(:notice_successful_update))
        overview_page.expect_phase_status_buttons(project_life_cycles, "Completed", "Completed", "Completed", "Open")
        expect(stored_statuses).to eq %w[completed completed completed open]
      end
    end

    context "when setting a phase to open" do
      let(:initial_statuses) { %w[completed completed in_progress open] }

      it "reopens the later phases and leaves the earlier ones untouched" do
        overview_page.change_phase_status(life_cycle_planning, from: "Completed", to: "Open")

        expect_flash(message: I18n.t(:notice_successful_update))
        overview_page.expect_phase_status_buttons(project_life_cycles, "Completed", "Open", "Open", "Open")
        expect(stored_statuses).to eq %w[completed open open open]
      end
    end

    context "when a phase is inactive for this project" do
      let(:inactive_phases) { [life_cycle_planning] }

      it "does not change the inactive phase" do
        overview_page.change_phase_status(life_cycle_closing, from: "Open", to: "In progress")

        expect_flash(message: I18n.t(:notice_successful_update))
        expect(stored_statuses).to eq %w[completed open completed in_progress]
      end
    end
  end

  describe "activity page" do
    let(:user) { admin }
    let(:activity_page) { Pages::Projects::Activity.new(project) }

    it "lists the status change of every affected phase in a single entry" do
      overview_page.change_phase_status(life_cycle_executing, from: "Open", to: "In progress")
      expect_flash(message: I18n.t(:notice_successful_update))

      activity_page.visit!
      activity_page.show_details

      activity_page.within_journal(number: 1) do
        activity_page.expect_activity("Initiating changed from Open to Completed")
        activity_page.expect_activity("Planning changed from Open to Completed")
        activity_page.expect_activity("Executing changed from Open to In progress")

        activity_page.expect_no_activity("Closing changed")
      end
    end
  end
end
