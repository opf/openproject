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

RSpec.describe "Create work package in sprint", :js do
  let!(:project) do
    create(:project,
           types: [type, type2],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let!(:project2) { create(:project) }
  let(:create_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           view_work_packages
                           manage_sprint_items
                           add_work_packages))
  end
  let(:non_create_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           view_work_packages))
  end

  let(:type) { create(:type) }
  let(:type2) { create(:type) }

  let!(:priority) { create(:default_priority) }
  let!(:status) { create(:default_status) }

  let!(:sprint1) { create(:sprint, project:) }
  let!(:sprint2) { create(:sprint, project:) }

  let!(:sprint1_wp1) { create(:work_package, sprint: sprint1, type:, project:) }
  let!(:sprint1_wp2) { create(:work_package, sprint: sprint1, type:, project:) }
  let!(:sprint1_other_project_wp1) { create(:work_package, sprint: sprint1, type:, project: project2) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_roles: {
             project => create_role,
             project2 => create_role
           })
  end

  before do
    backlogs_page.visit!
  end

  context "in a non shared sprint" do
    it "allows creating a new story" do
      backlogs_page.click_in_sprint_menu(sprint1, "Add work package")

      within_dialog "New work package" do
        fill_in "Subject", with: "The new item"
        # TODO: removed in OP #57688, to be reimplemented
        # fill_in "Story Points", with: "5"

        select_combo_box_option type2.name, from: "Type"

        # saving the new story
        click_on "Create"
      end

      expect_and_dismiss_flash type: :success, exact_message: "Successful creation."

      created_work_package = WorkPackage.last

      # velocity should be summed up immediately
      # TODO: removed in OP #57688, to be reimplemented
      # xpect(page).to have_css(".velocity", text: "12")

      # this will ensure that the page refresh is through before we check the order
      backlogs_page.click_in_sprint_menu(sprint1, "Add work package")

      within_dialog "New work package" do
        fill_in "Subject", with: "Another story"
      end

      # the order is kept even after a page refresh -> it is persisted in the db
      page.driver.refresh

      expect(page)
        .to have_no_text "Another story"

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_wp1,
                                                                 sprint1_wp2,
                                                                 created_work_package])

      # created with the selected type (HighlightedTypeComponent renders type name in uppercase)
      backlogs_page.within_work_package(created_work_package) do
        expect(page).to have_text(type2.name.upcase)
      end
    end
  end

  context "in an empty non shared sprint" do
    it "allows creating a new story" do
      backlogs_page.click_in_sprint_menu(sprint2, "Add work package")

      within_dialog "New work package" do
        fill_in "Subject", with: "The new item"

        click_on "Create"
      end

      expect_and_dismiss_flash type: :success, exact_message: "Successful creation."

      created_work_package = WorkPackage.last

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint2,
                                                 work_packages: [created_work_package])
    end
  end

  context "in a shared sprint" do
    let(:backlogs_page) { Pages::Backlog.new(project2) }

    it "allows creating a new story" do
      backlogs_page.click_in_sprint_menu(sprint1, "Add work package")

      within_dialog "New work package" do
        fill_in "Subject", with: "The new item"

        click_on "Create"
      end

      expect_and_dismiss_flash type: :success, exact_message: "Successful creation."

      created_work_package = WorkPackage.last

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_other_project_wp1,
                                                                 created_work_package])
    end
  end

  context "when lacking the permission to create work packages" do
    current_user do
      create(:user,
             member_with_roles: {
               project => non_create_role
             })
    end

    it "does not show a menu (item for creating a new work package)" do
      # At the moment, since there's no menu item, the entire menu will not be visible.
      # Once we add more and more menu items back, the menu will be rendered, but the action
      # will be missing. When that happens, the expectation has to be adjusted for something like
      # this:
      # backlogs_page.expect_no_sprint_menu_item(sprint1, "Add work package")

      backlogs_page.expect_no_sprint_menu(sprint1)
    end
  end
end
