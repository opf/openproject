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

RSpec.describe "Edit", :js do
  let(:project) { create(:project) }
  let(:all_permissions) do
    %i[view_sprints add_work_packages view_work_packages create_sprints manage_sprint_items
       start_complete_sprint show_board_views manage_board_views save_queries
       manage_public_queries]
  end
  let(:permissions) { all_permissions }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:planning_page) { Pages::Backlog.new(project) }

  let!(:closed_sprint) do
    create(:sprint,
           project:,
           status: "completed",
           start_date: Date.new(2025, 8, 25),
           finish_date: Date.new(2025, 9, 4))
  end

  let!(:first_sprint) do
    create(:sprint,
           project:,
           start_date: Date.new(2025, 9, 5),
           finish_date: Date.new(2025, 9, 15))
  end

  let!(:second_sprint) do
    create(:sprint,
           project:,
           start_date: Date.new(2025, 9, 16),
           finish_date: Date.new(2025, 9, 26))
  end

  let!(:work_package) do
    create(:work_package, subject: "First work package", project:, sprint: first_sprint)
  end

  # Necessary so that work packages can be created via dialog
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }

  before do
    login_as(user)

    planning_page.visit!
  end

  it "lists all open sprints" do
    planning_page.expect_sprint_names_in_order(first_sprint.name, second_sprint.name)

    planning_page.expect_work_package_in_sprint(work_package, first_sprint)
    planning_page.expect_work_package_not_in_sprint(work_package, second_sprint)
  end

  it "adds a work package to a sprint" do
    planning_page.click_in_sprint_menu(first_sprint, "Add work package")
    planning_page.expect_create_work_package_dialog

    page.within("#create-work-package-dialog") do
      page.fill_in "Subject", with: "Story created in sprint"

      click_on "Create"
    end

    wait_for_reload

    expect_and_dismiss_flash type: :success, exact_message: "Successful creation."
    created_wp = first_sprint.reload.work_packages.last
    expect(created_wp.subject).to eq("Story created in sprint")
    planning_page.expect_work_package_in_sprint(created_wp, first_sprint)
  end

  context "with the 'create_sprints' permissions" do
    context "when editing a sprint" do
      it "displays all menu entries" do
        planning_page.within_sprint_menu(first_sprint) do |menu|
          expect(menu).to have_selector :menuitem, count: 2
          expect(menu).to have_selector :menuitem, "Edit sprint"
          expect(menu).to have_selector :menuitem, "Add work package"
        end
      end

      it "edits the sprint name" do
        planning_page.expect_sprint_names_in_order(first_sprint.name, second_sprint.name)

        planning_page.click_in_sprint_menu(first_sprint, "Edit sprint")
        planning_page.expect_sprint_dialog

        within_dialog "Edit sprint" do
          page.fill_in "Sprint name", with: "Changed name"
          page.click_button "Save"
        end

        wait_for_reload
        planning_page.expect_sprint_names_in_order("Changed name", second_sprint.name)
      end

      context "when lacking the 'manage_sprint_items' permission" do
        let(:permissions) { all_permissions - %i[manage_sprint_items] }

        it "has no menu entry for creating a new story" do
          planning_page.within_sprint_menu(first_sprint) do |menu|
            expect(menu).to have_selector :menuitem, count: 1
            expect(menu).to have_selector :menuitem, "Edit sprint"

            expect(menu).to have_no_selector :menuitem, "Add work package"
          end
        end
      end

      describe "validations" do
        context "when sprint status is active" do
          before { first_sprint.update!(status: "active") }

          it "validates required fields are present" do
            planning_page.click_in_sprint_menu(first_sprint, "Edit sprint")
            planning_page.expect_sprint_dialog

            within_dialog "Edit sprint" do
              page.fill_in "Sprint name", with: ""
              page.fill_in "Start date", with: ""
              page.fill_in "Finish date", with: ""

              page.click_button "Save"

              expect(page).to have_field "Sprint name", validation_error: "can't be blank"
              expect(page).to have_field "Start date", validation_error: "can't be blank"
              expect(page).to have_field "Finish date", validation_error: "can't be blank"
            end
          end
        end
      end
    end
  end

  context "without the necessary permissions" do
    let(:permissions) { all_permissions - %i[create_sprints start_complete_sprint] }

    it "is missing the 'new sprint' button" do
      expect(page).to have_no_button "Create"
      expect(page).not_to have_test_selector("op-sprints--new-sprint-button")
    end

    it "has no menu entry for editing a sprint" do
      planning_page.within_sprint_menu(first_sprint) do |menu|
        expect(menu).to have_no_selector :menuitem, "Edit sprint"
      end
    end
  end
end
