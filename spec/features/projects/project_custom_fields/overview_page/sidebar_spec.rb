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
  include_context "with seeded projects, members and project custom fields", seed_all: false

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    login_as admin
  end

  it "does show the project attributes sidebar" do
    boolean_project_custom_field
    overview_page.visit_page

    expect(page).to have_test_selector "project-custom-fields-sidebar"
  end

  describe "with correct order and scoping" do
    it "shows the project custom field sections in the correct order" do
      all_fields
      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        sections = page.all(".op-project-custom-field-section-container")

        expect(sections.size).to eq(3)

        expect(sections[0].text).to include("Input fields")
        expect(sections[1].text).to include("Select fields")
        expect(sections[2].text).to include("Multi select fields")
      end

      section_for_input_fields.move_to_bottom

      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        sections = page.all(".op-project-custom-field-section-container")

        expect(sections.size).to eq(3)

        expect(sections[0].text).to include("Select fields")
        expect(sections[1].text).to include("Multi select fields")
        expect(sections[2].text).to include("Input fields")
      end
    end

    it "shows the project custom fields in the correct order within the sections" do
      all_fields
      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        overview_page.within_custom_field_section_container(section_for_input_fields) do
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

        overview_page.within_custom_field_section_container(section_for_select_fields) do
          fields = page.all(".op-project-custom-field-container")

          expect(fields.size).to eq(3)

          expect(fields[0].text).to include("List field")
          expect(fields[1].text).to include("Version field")
          expect(fields[2].text).to include("User field")
        end

        overview_page.within_custom_field_section_container(section_for_multi_select_fields) do
          fields = page.all(".op-project-custom-field-container")

          expect(fields.size).to eq(3)

          expect(fields[0].text).to include("Multi list field")
          expect(fields[1].text).to include("Multi version field")
          expect(fields[2].text).to include("Multi user field")
        end
      end

      section_for_input_fields.reload.move_in_order(string_project_custom_field.column_name, :lowest)

      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        overview_page.within_custom_field_section_container(section_for_input_fields) do
          fields = page.all(".op-project-custom-field-container")

          expect(fields.size).to eq(9)

          expect(fields[0].text).to include("Boolean field")
          expect(fields[1].text).to include("Integer field")
          expect(fields[2].text).to include("Float field")
          expect(fields[3].text).to include("Date field")
          expect(fields[4].text).to include("Link field")
          expect(fields[5].text).to include("Text field")
          expect(fields[6].text).to include("Calculated field using int")
          expect(fields[7].text).to include("Calculated field using int and float")
          expect(fields[8].text).to include("String field")
        end
      end
    end

    it "does not show project custom fields not enabled for this project in a sidebar" do
      boolean_project_custom_field
      create(:string_project_custom_field, projects: [other_project], name: "String field enabled for other project")

      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        expect(page).to have_no_text "String field enabled for other project"
      end
    end
  end

  describe "with interactive values" do
    it "expands long text in a dialog" do
      cf_value = ("lorem " * 100).strip
      text_project_custom_field.custom_values.where(customized: project).first.update!(value: cf_value)

      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        overview_page.within_custom_field_container(text_project_custom_field) do
          expect(page).to have_text "Text field"
          expect(page).to have_text (("lorem " * 5).to_s)
        end

        overview_page.expect_text_truncated(text_project_custom_field)
        overview_page.expand_text(text_project_custom_field)
      end

      overview_page.expect_full_text_in_dialog(cf_value)
    end

    it "updates calculated values and their errors", with_ee: %i[calculated_values] do
      calculated_value_fields
      overview_page.visit_page

      field = overview_page.open_inplace_edit_field_for_custom_field(float_project_custom_field)
      field.fill_and_submit_value name: float_project_custom_field.name, val: ""

      overview_page.within_project_attributes_sidebar do
        overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
          expect(page).to have_text "234"
        end

        overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
          expect(page).to have_text I18n.t("calculated_values.errors.missing_value",
                                           custom_field_name: float_project_custom_field.name)
        end
      end

      field.open_field
      field.fill_and_submit_value name: float_project_custom_field.name, val: "0.2"

      overview_page.within_project_attributes_sidebar do
        overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
          expect(page).to have_text "234"
        end

        overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
          expect(page).to have_text "24.6"
        end
      end
    end
  end

  describe "with attribute helper texts" do
    let!(:instance) do
      create :project_help_text,
             attribute_name: boolean_project_custom_field.attribute_name
    end

    it "displays when active" do
      overview_page.visit_page

      # Open help text modal
      page.find("[data-qa-help-text-for='#{instance.attribute_name.camelize(:lower)}']").click

      within_modal "Boolean field" do
        expect(page).to have_text "Attribute help text"

        expect(page).to have_button "Close"
        expect(page).to have_link "Edit"

        click_on "Close"
      end

      expect(page).to have_no_modal "Boolean field"
    end
  end
end
