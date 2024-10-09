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

RSpec.describe "Custom Fields Multi-Project Activation", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:archived_project) { create(:project, active: false) }
  shared_let(:custom_field) { create(:wp_custom_field) }
  shared_let(:custom_field_project) { create(:custom_fields_project, custom_field:, project:) }

  shared_let(:archived_project_custom_field) do
    create(:custom_fields_project, custom_field:, project: archived_project)
  end

  let(:custom_field_projects_page) { Pages::Admin::CustomFields::CustomFieldsProjects::CustomFieldProjectsIndex.new }

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit custom_field_projects_path(custom_field)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit custom_field_projects_path(custom_field)
    end

    it "renders a list of projects linked to the custom field" do
      aggregate_failures "shows a correct breadcrumb menu" do
        within ".PageHeader-breadcrumbs" do
          expect(page).to have_link("Administration")
          expect(page).to have_link("Custom fields")
          expect(page).to have_link("Work packages")
          expect(page).to have_text(custom_field.name)
        end
      end

      aggregate_failures "shows tab navigation" do
        within_test_selector("custom_field_detail_header") do
          expect(page).to have_link("Details")
          expect(page).to have_link("Projects")
        end
      end

      aggregate_failures "shows the correct project mappings" do
        within "#project-table" do
          expect(page).to have_text(project.name)
          expect(page).to have_text(archived_project.name)
        end
      end
    end

    it "shows an error in the dialog when no project is selected before adding" do
      create(:project)
      expect(page).to have_no_css("dialog")
      click_on "Add projects"

      page.within("dialog") do
        click_on "Add"

        expect(page).to have_text("Please select a project.")
      end
    end

    it "allows linking a project to a custom field" do
      project = create(:project)
      subproject = create(:project, parent: project)
      click_on "Add projects"

      within_test_selector("new-custom-field-projects-modal") do
        autocompleter = page.find(".op-project-autocompleter")
        autocompleter.fill_in with: project.name

        expect(page).to have_no_text(archived_project.name)

        find(".ng-option-label", text: project.name).click
        check "Include sub-projects"

        click_on "Add"
      end

      expect(page).to have_text(project.name)
      expect(page).to have_text(subproject.name)

      aggregate_failures "pagination links maintain the correct url" do
        custom_field_projects_page.expect_page_sizes(model: custom_field)
      end
    end

    it "allows unlinking a project from a custom field", with_settings: { per_page_options: "2,5" } do
      projects = create_list(:project, 4)
      projects.each { |project| create(:custom_fields_project, custom_field:, project:) }

      current_page = 3
      visit custom_field_projects_path(custom_field, page: current_page)

      project = custom_field_projects_page.project_in_first_row
      custom_field_projects_page.click_menu_item_of("Remove from project", project)

      expect(page).to have_no_text(project.name)

      aggregate_failures "pagination links maintain the correct url after unlinking is done" do
        custom_field_projects_page.expect_page_links(model: custom_field, current_page:)
        custom_field_projects_page.expect_current_page_number(current_page)
      end
    end

    context "and the project custom field is for all projects" do
      shared_let(:custom_field) { create(:user_custom_field, is_for_all: true) }

      it "renders a blank slate" do
        expect(page).to have_text("For all projects")
        expect(page).not_to have_test_selector("add-projects-sub-header")
      end
    end
  end
end
