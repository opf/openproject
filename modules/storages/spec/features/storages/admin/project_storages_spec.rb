# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
require_module_spec_helper

RSpec.describe "Admin lists project mappings for a storage",
               :js,
               :with_cuprite,
               with_flag: { enable_storage_for_multiple_projects: true } do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:non_admin) { create(:user) }

  shared_let(:project) { create(:project, name: "My active Project") }
  shared_let(:archived_project) do
    create(:project,
           active: false,
           name: "My archived Project")
  end
  shared_let(:storage) do
    create(:nextcloud_storage,
           :as_automatically_managed,
           name: "My Nextcloud Storage")
  end
  shared_let(:project_storage) do
    create(:project_storage,
           project:,
           storage:,
           project_folder_mode: "automatic")
  end
  shared_let(:archived_project_project_storage) do
    create(:project_storage,
           project: archived_project,
           storage:,
           project_folder_mode: "inactive")
  end

  let(:project_storages_index_page) { Pages::Admin::Storages::ProjectStorages::Index.new }

  current_user { admin }

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit admin_settings_storage_project_storages_path(storage)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit admin_settings_storage_project_storages_path(storage)
    end

    it "renders a list of projects linked to the storage" do
      aggregate_failures "shows a correct breadcrumb menu" do
        within ".PageHeader-breadcrumbs" do
          expect(page).to have_link("Administration")
          expect(page).to have_link("Files")
          expect(page).to have_link("My Nextcloud Storage")
        end
      end

      aggregate_failures "shows tab navigation" do
        within_test_selector("storage_detail_header") do
          expect(page).to have_link("Details")
          expect(page).to have_link("Enabled in projects")
        end
      end

      aggregate_failures "shows the correct table headers" do
        within "#project-table" do
          expect(page)
            .to have_css("th", text: "NAME")
          expect(page)
            .to have_css("th", text: "PROJECT FOLDER TYPE")
        end
      end

      aggregate_failures "shows the correct project mappings including archived projects and their configured folder modes" do
        within "#project-table" do
          project_storages_index_page.within_the_table_row_containing(project.name) do
            expect(page).to have_text("Automatically managed")
          end
          project_storages_index_page.within_the_table_row_containing(archived_project.name) do
            expect(page).to have_text("No specific folder")
          end
        end
      end
    end

    it "shows an error in the dialog when no project is selected before adding" do
      create(:project)
      expect(page).to have_no_css("dialog")
      click_on "Add projects"

      page.within("dialog") do
        click_on "Add"

        wait_for(page).to have_text("Please select a project.")
      end
    end

    it "allows linking a project to a storage" do
      project = create(:project)
      subproject = create(:project, parent: project)
      click_on "Add projects"

      within("dialog") do
        autocompleter = page.find(".op-project-autocompleter")
        autocompleter.fill_in with: project.name

        expect(page).to have_no_text(archived_project.name)

        find(".ng-option-label", text: project.name).click
        check "Include sub-projects"

        expect(page.find_by_id("storages_project_storage_project_folder_mode_automatic")).to be_checked

        click_on "Add"
      end

      expect(page).to have_text(project.name)
      expect(page).to have_text(subproject.name)

      aggregate_failures "pagination links maintain the correct url" do
        within ".op-pagination" do
          pagination_links = page.all(".op-pagination--item-link")
          expect(pagination_links.size).to be_positive

          pagination_links.each do |pagination_link|
            uri = URI.parse(pagination_link["href"])
            expect(uri.path).to eq(admin_settings_storage_project_storages_path(storage))
          end
        end
      end
    end

    describe "Removal of a project from a storage" do
      it "shows a warning dialog that can be aborted" do
        expect(page).to have_text(project.name)
        project_storages_index_page.click_menu_item_of("Remove project", project)

        page.within("dialog") do
          expect(page).to have_text("Remove project from Nextcloud")
          expect(page).to have_text("this storage has an automatically managed project folder")
          click_on "Close"
        end

        expect(page).to have_text(project.name)
      end

      it "is possible to remove the project after checking the confirmation checkbox in the dialog" do
        expect(page).to have_text(project.name)
        project_storages_index_page.click_menu_item_of("Remove project", project)

        page.within("dialog") do
          expect(page).to have_button("Remove", disabled: true)
          check "Please, confirm you understand and want to remove this file storage from this project"
          click_on "Remove"
        end

        expect(page).to have_no_text(project.name)
      end
    end
  end
end
