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
require_relative "shared_context"

RSpec.describe "Show project custom fields on project overview page", :js do
  include TestSelectorFinders

  include_context "with seeded projects, members and project custom fields"

  let(:overview_page) { Pages::Projects::Show.new(project) }

  describe "as user with permissions" do
    before do
      login_as admin
    end

    describe "within the Administration" do
      before do
        visit admin_settings_project_custom_fields_path
      end

      it "shows an ActionMenu for each section" do
        sections.each do |section|
          within_test_selector("project-custom-field-section-container-#{section.id}") do
            # Per default, the section is shown in the side panel
            expect(page).to have_test_selector("section-position-selector", text: "Side panel")
          end
        end
      end

      it "can change the position to main section" do
        within_test_selector("project-custom-field-section-container-#{section_for_input_fields.id}") do
          # Change it to main section
          page.find_test_selector("section-position-selector").click
          expect(page).to have_test_selector("section-position-selector--side-panel-option")
          expect(page).to have_test_selector("section-position-selector--main-section-option")

          page.find_test_selector("section-position-selector--main-section-option").click
          wait_for_network_idle

          # The section is updated directly
          section = CustomFieldSection.find(section_for_input_fields.id)
          expect(section.shown_in_overview_main_area?).to be(true)
          expect(page).to have_test_selector("section-position-selector", text: "Main area")
        end
      end

      it "can add a new section which is shown per default in the sidebar" do
        within "#settings-project-custom-fields-header-component" do
          page.find_test_selector("project-attributes-add-menu-button").click
          click_on("dialog-show-project-custom-field-section-dialog")
        end

        fill_in("project_custom_field_section_name", with: "An awesome new section")

        click_on("Save")

        expect(page).to have_text("An awesome new section")

        # The section is shown in the sidebar per default
        section = CustomFieldSection.last
        expect(section.shown_in_overview_sidebar?).to be(true)
        within_test_selector("project-custom-field-section-container-#{section.id}") do
          expect(page).to have_test_selector("section-position-selector", text: "Side panel")
        end
      end
    end

    describe "within the Overview page" do
      before do
        # Move one section to the main section
        section = CustomFieldSection.find(section_for_input_fields.id)
        section.display_representation = { overview: "main_area" }
        section.save!

        overview_page.visit!
      end

      it "shows the sections in either the sidebar or the main section" do
        # The section is shown in the main section of the overview page ...
        overview_page.within_main_area do
          sections = page.all(".op-project-custom-field-section-container")

          expect(sections.size).to eq(1)

          expect(sections[0].text).to include("Input fields")
        end

        # ... while the others remain in the sidebar
        overview_page.within_project_attributes_sidebar do
          sections = page.all(".op-project-custom-field-section-container")

          expect(sections.size).to eq(2)

          expect(sections[0].text).to include("Select fields")
          expect(sections[1].text).to include("Multi select fields")
        end
      end

      it "shows the project custom fields in the correct order within the widget" do
        overview_page.within_main_area do
          overview_page.within_custom_field_section_widget(section_for_input_fields) do
            fields = page.all(".op-project-custom-field-container")

            expect(fields.size).to eq(9)

            expect(fields[0].text).to include("Boolean field")
            expect(fields[1].text).to include("String field")
            expect(fields[2].text).to include("Integer field")
            expect(fields[3].text).to include("Float field")
            expect(fields[4].text).to include("Date field")
            expect(fields[5].text).to include("Link field")
            expect(fields[6].text).to include("Text field")
            expect(fields[7].text).to include("Calculated field using int")
            expect(fields[8].text).to include("Calculated field using int and float")
          end
        end
      end

      it "does not show project custom fields not enabled for this project in a widget" do
        create(:string_project_custom_field, projects: [other_project], name: "String field enabled for other project")

        overview_page.visit_page

        overview_page.within_main_area do
          expect(page).to have_no_text "String field enabled for other project"
        end
      end

      it "can edit a project custom field from within the widget" do
        field = overview_page.open_inplace_edit_field_for_custom_field(string_project_custom_field)
        field.fill_and_submit_value name: string_project_custom_field.name, val: "My super awesome new value"

        # The new value is shown in the widget
        overview_page.within_main_area do
          overview_page.within_custom_field_section_widget(section_for_input_fields) do
            expect(page).to have_text "My super awesome new value"
          end
        end

        expect(project.reload.custom_value_for(string_project_custom_field).value).to eq("My super awesome new value")
      end
    end
  end

  describe "as user without view_project_attributes permission" do
    before do
      # Move one section to the main section
      section = CustomFieldSection.find(section_for_input_fields.id)
      section.display_representation = { overview: "main_area" }
      section.save!
    end

    context "when user has no view_project_attributes permission in any project" do
      before do
        login_as member_without_view_project_attributes_permission
        overview_page.visit!
      end

      it "does not show the fields" do
        sections = page.all(".op-project-custom-field-section-container")
        expect(sections.size).to eq(0)

        fields = page.all(".op-project-custom-field-container")
        expect(fields.size).to eq(0)

        expect(page).to have_no_text("Boolean field")
        expect(page).to have_no_text("String field")
        expect(page).to have_no_text("Integer field")
        expect(page).to have_no_text("Float field")
        expect(page).to have_no_text("Date field")
        expect(page).to have_no_text("Link field")
        expect(page).to have_no_text("Text field")
        expect(page).to have_no_text("Calculated field using int")
        expect(page).to have_no_text("Calculated field using int and float")
      end
    end

    context "when user has view_project_attributes in another project but not in this project" do
      let!(:member_with_permission_only_in_other_project) do
        create(:user,
               firstname: "Member 5",
               lastname: "In Both Projects",
               member_with_roles: {
                 project => reader_role_without_project_attributes,
                 other_project => reader_role
               })
      end

      before do
        # Enable a CF for both projects so the cross-project permission scenario is meaningful
        string_project_custom_field.projects << other_project

        login_as member_with_permission_only_in_other_project
        overview_page.visit!
      end

      it "does not show fields from this project" do
        sections = page.all(".op-project-custom-field-section-container")
        expect(sections.size).to eq(0)

        fields = page.all(".op-project-custom-field-container")
        expect(fields.size).to eq(0)

        expect(page).to have_no_text("String field")
      end
    end
  end
end
