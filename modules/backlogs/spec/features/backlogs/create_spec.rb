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
require_relative "../../support/pages/backlog"

RSpec.describe "Create", :js do
  shared_let(:project) { create(:project) }
  shared_let(:initial_sprint) do
    create(:sprint,
           project:,
           name: "Initial sprint",
           start_date: Date.new(2025, 9, 5),
           finish_date: Date.new(2025, 9, 15))
  end

  let(:planning_page) { Pages::Backlog.new(project) }
  let(:all_permissions) { %i[view_sprints view_work_packages create_sprints] }
  let(:permissions) { all_permissions }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "shows the correct breadcrumb menu" do
    planning_page.visit!

    within ".PageHeader-breadcrumbs" do
      expect(page).to have_link(href: project_path(project), text: project.name)
      expect(page).to have_link(href: project_backlogs_backlog_path(project), text: "Backlogs")
      expect(page).to have_text("Backlog and sprints")
    end
  end

  it "renders the menu" do
    planning_page.visit!

    within "#main-menu" do
      expect(page).to have_css(".selected", text: "Backlog and sprints")
    end
  end

  context "with the 'create_sprints' permissions" do
    let(:start_date) { Date.new(2025, 10, 5) }
    let(:start_date_fmt) { start_date.strftime("%Y-%m-%d") }
    let(:finish_date) { Date.new(2025, 10, 20) }
    let(:finish_date_fmt) { finish_date.strftime("%Y-%m-%d") }

    it "allows creating a new sprint" do
      planning_page.visit!

      planning_page.expect_sprint_names_in_order(initial_sprint.name)

      planning_page.open_create_sprint_dialog

      within_dialog "New sprint" do
        page.fill_in "Sprint name", with: "Created sprint"
        page.fill_in "Start date", with: start_date_fmt
        page.fill_in "Finish date", with: finish_date_fmt

        click_on "Create"
      end

      expect_and_dismiss_flash(exact_message: "Successful creation.")
      planning_page.expect_sprint_names_in_order(initial_sprint.name, "Created sprint")

      sprint = project.reload.sprints.last
      expect(sprint).to be_present
      expect(sprint.name).to eq "Created sprint"
      expect(sprint.start_date).to eq start_date
      expect(sprint.finish_date).to eq finish_date
    end

    it "allows creating a new sprint with a sprint goal" do
      planning_page.visit!

      planning_page.open_create_sprint_dialog

      within_dialog "New sprint" do
        fill_in "Sprint name", with: "Created sprint"
        fill_in "Start date", with: start_date_fmt
        fill_in "Finish date", with: finish_date_fmt
        fill_in "Sprint goal", with: "Deliver the first MVP scope."

        click_on "Create"
      end

      expect_and_dismiss_flash(exact_message: "Successful creation.")
      planning_page.expect_sprint_heading_with_goal("Created sprint", "Deliver the first MVP scope.")
    end

    it "previews the sprint duration when changing the dates" do
      planning_page.visit!

      planning_page.open_create_sprint_dialog

      within_dialog "New sprint" do
        expect(page).to have_field "Duration", with: "", readonly: true

        page.fill_in "Start date", with: start_date_fmt
        page.fill_in "Finish date", with: finish_date_fmt

        expect(page).to have_field "Duration", with: "16 days", readonly: true
      end
    end

    describe "validations" do
      let(:too_early_finish_date) { start_date - 1.day }

      it "validates required fields are present" do
        planning_page.visit!

        planning_page.open_create_sprint_dialog

        within_dialog "New sprint" do
          page.fill_in "Sprint name", with: ""

          click_on "Create"

          expect(page).to have_field "Sprint name", validation_error: "can't be blank"
          expect(page).to have_field "Start date", validation_error: false
          expect(page).to have_field "Finish date", validation_error: false
        end
      end

      it "validates finish date is not before start date" do
        planning_page.visit!

        planning_page.open_create_sprint_dialog

        within_dialog "New sprint" do
          page.fill_in "Start date", with: start_date_fmt
          page.fill_in "Finish date", with: too_early_finish_date.strftime("%Y-%m-%d")

          # Shows duration as zero if finish date is before start date:
          expect(page).to have_field "Duration", with: "0 days", readonly: true

          click_on "Create"

          expect(page).to have_field("Finish date",
                                     validation_error: "must be greater than or equal to #{start_date_fmt}")
        end
      end
    end

    describe "proposed sprint names" do
      before do
        Sprint.delete_all
      end

      it "prefilled with 'Sprint 1' if there are no previous sprints" do
        planning_page.visit!

        planning_page.open_create_sprint_dialog

        within_dialog "New sprint" do
          expect(page).to have_field "Sprint name *", with: "Sprint 1", required: true, focused: true
        end
      end

      context "with a previous sprint" do
        before do
          create(:sprint, name: "Be ambitious 42", project:)

          planning_page.visit!
          planning_page.open_create_sprint_dialog
        end

        it "offers the next sprint name with a number increment" do
          within_dialog "New sprint" do
            expect(page).to have_field "Sprint name *", with: "Be ambitious 43"
          end
        end
      end
    end
  end

  context "without the necessary permissions" do
    let(:permissions) { all_permissions - [:create_sprints] }

    it "is missing the 'new sprint' button" do
      planning_page.visit!

      expect(page).to have_no_button "Create"
      expect(page).not_to have_test_selector("op-sprints--new-sprint-button")
    end
  end

  context "with the project receiving sprints from another project" do
    let(:project) { create(:project, sprint_sharing: Projects::SprintSharing::RECEIVE_SHARED) }

    it "is missing the 'new sprint' button" do
      planning_page.visit!

      expect(page).to have_no_button "Create"
      expect(page).not_to have_test_selector("op-sprints--new-sprint-button")
    end
  end
end
