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

RSpec.describe "Project Custom Field Mappings", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:archived_project) { create(:project, active: false) }
  shared_let(:project_custom_field) { create(:project_custom_field) }
  shared_let(:project_custom_field_mapping) { create(:project_custom_field_project_mapping, project_custom_field:, project:) }

  shared_let(:archived_project_custom_field_mapping) do
    create(:project_custom_field_project_mapping, project_custom_field:, project: archived_project)
  end

  let(:project_custom_field_mappings_page) { Pages::Admin::Settings::ProjectCustomFields::ProjectCustomFieldMappingsIndex.new }

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit project_mappings_admin_settings_project_custom_field_path(project_custom_field)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit project_mappings_admin_settings_project_custom_field_path(project_custom_field)
    end

    it "renders a list of projects linked to the custom field" do
      aggregate_failures "shows a correct breadcrumb menu" do
        within ".PageHeader-breadcrumbs" do
          expect(page).to have_link("Administration")
          expect(page).to have_link("Projects")
          expect(page).to have_link("Project attributes")
          expect(page).to have_text(project_custom_field.name)
        end
      end

      aggregate_failures "shows tab navigation" do
        within_test_selector("project_attribute_detail_header") do
          expect(page).to have_link("Details")
          expect(page).to have_link("Enabled in projects")
        end
      end

      aggregate_failures "shows the correct project mappings" do
        within "#project-table" do
          expect(page).to have_text(project.name)
          expect(page).to have_text(archived_project.name)

          within("tr#settings-project-custom-fields-project-custom-field-mapping-row-component-project-#{archived_project.id}") do
            expect(page.find(".buttons")).not_to have_test_selector("project-list-row--action-menu")
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

        expect(page).to have_text("Please select a project.")
      end
    end

    it "allows linking a project to a custom field" do
      project = create(:project)
      subproject = create(:project, parent: project)
      click_on "Add projects"

      within_test_selector("settings--new-project-custom-field-mapping-component") do
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
        within ".op-pagination" do
          pagination_links = page.all(".op-pagination--item-link")
          expect(pagination_links.size).to be_positive

          pagination_links.each do |pagination_link|
            uri = URI.parse(pagination_link["href"])
            expect(uri.path).to eq(project_mappings_admin_settings_project_custom_field_path(project_custom_field))
          end
        end
      end
    end

    it "allows unlinking a project from a custom field" do
      project = create(:project)
      create(:project_custom_field_project_mapping, project_custom_field:, project:)

      visit project_mappings_admin_settings_project_custom_field_path(project_custom_field)

      project_custom_field_mappings_page.click_menu_item_of("Remove from project", project)

      expect(page).to have_no_text(project.name)

      aggregate_failures "pagination links maintain the correct url after unlinking is done" do
        within ".op-pagination" do
          pagination_links = page.all(".op-pagination--item-link")
          expect(pagination_links.size).to be_positive

          pagination_links.each do |pagination_link|
            uri = URI.parse(pagination_link["href"])
            expect(uri.path).to eq(project_mappings_admin_settings_project_custom_field_path(project_custom_field))
          end
        end
      end
    end

    context "and the project custom field is required" do
      shared_let(:project_custom_field) { create(:project_custom_field, is_required: true) }

      it "renders a blank slate" do
        expect(page).to have_text("Required in all projects")
      end
    end
  end
end
