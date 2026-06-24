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
  include_context "with seeded projects, members and project custom fields"

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    login_as admin
  end

  it "does show the project attributes sidebar" do
    overview_page.visit_page

    expect(page).to have_test_selector "project-custom-fields-sidebar"
  end

  describe "with correct order and scoping" do
    it "shows the project custom field sections in the correct order" do
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
      create(:string_project_custom_field, projects: [other_project], name: "String field enabled for other project")

      overview_page.visit_page

      overview_page.within_project_attributes_sidebar do
        expect(page).to have_no_text "String field enabled for other project"
      end
    end
  end

  describe "with correct values" do
    describe "with boolean CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(boolean_project_custom_field) do
              expect(page).to have_text "Boolean field"
              expect(page).to have_text "Yes"
            end
          end
        end
      end

      describe "with value unset by user" do
        # A boolean cannot be completely unset via UI, only toggle between true and false, no blank value possible
        before do
          boolean_project_custom_field.custom_values.where(customized: project).first.update!(value: false)
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(boolean_project_custom_field) do
              expect(page).to have_text "Boolean field"
              expect(page).to have_text "No"
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          boolean_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(boolean_project_custom_field) do
              expect(page).to have_text "Boolean field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        it "does show the default value for the project custom field if no value given" do
          boolean_project_custom_field.update!(default_value: true)

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(boolean_project_custom_field) do
              expect(page).to have_text "Boolean field"
              expect(page).to have_text "Yes"
            end
          end

          boolean_project_custom_field.update!(default_value: false)

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(boolean_project_custom_field) do
              expect(page).to have_text "Boolean field"
              expect(page).to have_text "No"
            end
          end
        end
      end
    end

    describe "with string CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(string_project_custom_field) do
              expect(page).to have_text "String field"
              expect(page).to have_text "Foo"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          string_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(string_project_custom_field) do
              expect(page).to have_text "String field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          string_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(string_project_custom_field) do
              expect(page).to have_text "String field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        it "does show the default value for the project custom field if no value given" do
          string_project_custom_field.update!(default_value: "Bar")

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(string_project_custom_field) do
              expect(page).to have_text "String field"
              expect(page).to have_text "Bar"
            end
          end
        end
      end
    end

    describe "with integer CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(integer_project_custom_field) do
              expect(page).to have_text "Integer field"
              expect(page).to have_text "123"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          integer_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(integer_project_custom_field) do
              expect(page).to have_text "Integer field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          integer_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(integer_project_custom_field) do
              expect(page).to have_text "Integer field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        it "does show the default value for the project custom field if no value given" do
          integer_project_custom_field.update!(default_value: 456)

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(integer_project_custom_field) do
              expect(page).to have_text "Integer field"
              expect(page).to have_text 456
            end
          end
        end
      end
    end

    describe "with date CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(date_project_custom_field) do
              expect(page).to have_text "Date field"
              expect(page).to have_text "01/01/2024"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          date_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(date_project_custom_field) do
              expect(page).to have_text "Date field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          date_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(date_project_custom_field) do
              expect(page).to have_text "Date field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        it "does show the default value for the project custom field if no value given" do
          date_project_custom_field.update!(default_value: Date.new(2024, 2, 2))

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(date_project_custom_field) do
              expect(page).to have_text "Date field"
              expect(page).to have_text "02/02/2024"
            end
          end
        end
      end
    end

    describe "with float CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(float_project_custom_field) do
              expect(page).to have_text "Float field"
              expect(page).to have_text "123.456"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          float_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(float_project_custom_field) do
              expect(page).to have_text "Float field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          float_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(float_project_custom_field) do
              expect(page).to have_text "Float field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        it "does show the default value for the project custom field if no value given" do
          float_project_custom_field.update!(default_value: 456.789)

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(float_project_custom_field) do
              expect(page).to have_text "Float field"
              expect(page).to have_text 456.789
            end
          end
        end
      end
    end

    describe "with text CF" do
      describe "with value set by user" do
        context "with a value that does not have a line break and spans less than 3 lines" do
          before do
            text_project_custom_field.custom_values.where(customized: project).first.update!(value: "Lorem ipsum")
          end

          it "shows the correct value for the project custom field if given without truncation and dialog button" do
            overview_page.visit_page

            overview_page.within_project_attributes_sidebar do
              overview_page.within_custom_field_container(text_project_custom_field) do
                expect(page).to have_text "Text field"
                expect(page).to have_text "Lorem ipsum"
              end

              overview_page.expect_text_not_truncated(text_project_custom_field)
            end
          end
        end

        context "with a value that spans more than three lines" do
          let(:cf_value) { ("lorem " * 100).strip }

          before do
            text_project_custom_field.custom_values.where(customized: project).first.update!(value: cf_value)
          end

          it "shows the correct value for the project custom field if given with truncation and dialog button" do
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
        end
      end

      describe "with value unset by user" do
        before do
          text_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(text_project_custom_field) do
              expect(page).to have_text "Text field"
              expect(page).to have_text I18n.t("placeholders.default")
            end

            overview_page.expect_text_not_truncated(text_project_custom_field)
          end
        end
      end

      describe "with no value set by user" do
        before do
          text_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(text_project_custom_field) do
              expect(page).to have_text "Text field"
              expect(page).to have_text I18n.t("placeholders.default")
            end

            overview_page.expect_text_not_truncated(text_project_custom_field)
          end
        end

        it "does show the default value for the project custom field if no value given" do
          text_project_custom_field.update!(default_value: "Dolor sit amet")

          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(text_project_custom_field) do
              expect(page).to have_text "Text field"
              expect(page).to have_text "Dolor sit amet"
            end

            overview_page.expect_text_not_truncated(text_project_custom_field)
          end
        end
      end
    end

    describe "with calculated value CFs", with_ee: %i[calculated_values] do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
              expect(page).to have_text "Calculated field using int"
              expect(page).to have_text "234"
            end

            overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
              expect(page).to have_text "Calculated field using int and float"
              expect(page).to have_text "15,185.088"
            end
          end
        end
      end

      describe "with an error present" do
        before do
          calculated_from_int_and_float_project_custom_field.custom_values.where(customized: project).first.update!(value: "")

          calculated_from_int_and_float_project_custom_field
            .calculated_value_errors.create!(customized: project, error_code: "ERROR_MATHEMATICAL")
        end

        it "shows the error message for the project custom field" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
              expect(page).to have_text I18n.t("calculated_values.errors.mathematical")
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          calculated_from_int_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
          calculated_from_int_and_float_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
              expect(page).to have_text "Calculated field using int"
              expect(page).to have_text I18n.t("placeholders.default")
            end

            overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
              expect(page).to have_text "Calculated field using int and float"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          calculated_from_int_project_custom_field.custom_values.where(customized: project).destroy_all
          calculated_from_int_and_float_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
              expect(page).to have_text "Calculated field using int"
              expect(page).to have_text I18n.t("placeholders.default")
            end

            overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
              expect(page).to have_text "Calculated field using int and float"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with errors caused by user input" do
        it "updates calculated values, creating and removing errors as needed" do
          overview_page.visit_page

          # Remove value that is used in a formula:
          field = overview_page.open_inplace_edit_field_for_custom_field(float_project_custom_field)
          field.fill_and_submit_value name: float_project_custom_field.name, val: ""

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
              expect(page).to have_text "Calculated field using int"
              expect(page).to have_text "234"
            end

            overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
              expect(page).to have_text "Calculated field using int and float"
              expect(page).to have_text I18n.t("calculated_values.errors.missing_value",
                                               custom_field_name: float_project_custom_field.name)
            end
          end

          # Change the value so that the calculation succeeds.
          field.open_field
          field.fill_and_submit_value name: float_project_custom_field.name, val: "0.2"

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(calculated_from_int_project_custom_field) do
              expect(page).to have_text "Calculated field using int"
              expect(page).to have_text "234"
            end

            # The error is gone:
            overview_page.within_custom_field_container(calculated_from_int_and_float_project_custom_field) do
              expect(page).to have_text "Calculated field using int and float"
              expect(page).to have_text "24.6"
            end
          end
        end
      end
    end

    describe "with list CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(list_project_custom_field) do
              expect(page).to have_text "List field"
              expect(page).to have_text "Option 1"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          list_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(list_project_custom_field) do
              expect(page).to have_text "List field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          list_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(list_project_custom_field) do
              expect(page).to have_text "List field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        context "with a new field" do
          # We need to create a completely new field, just deleting the options is not enough...
          let!(:new_list_project_custom_field) do
            create(:list_project_custom_field,
                   projects: [project],
                   name: "New list field",
                   project_custom_field_section: section_for_select_fields,
                   possible_values: ["Option 1", "Option 2", "Option 3"]) do |field|
              create(:custom_value, customized: project, custom_field: field, value: field.custom_options.first)
            end
          end

          it "does show the default value for the project custom field if no value given" do
            new_list_project_custom_field.custom_options.first.update!(default_value: true)
            overview_page.visit_page

            overview_page.within_project_attributes_sidebar do
              overview_page.within_custom_field_container(new_list_project_custom_field) do
                expect(page).to have_text "New list field"
                expect(page).to have_text "Option 1"
              end
            end
          end
        end
      end
    end

    describe "with version CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(version_project_custom_field) do
              expect(page).to have_text "Version field"
              expect(page).to have_text "Version 1"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          version_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(version_project_custom_field) do
              expect(page).to have_text "Version field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          version_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(version_project_custom_field) do
              expect(page).to have_text "Version field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end
    end

    describe "with user CF" do
      describe "with value set by user" do
        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(user_project_custom_field) do
              expect(page).to have_text "User field"
              expect(page).to have_css("opce-principal")
              expect(page).to have_text "Member 1 In Project"
            end
          end
        end
      end

      describe "with value unset by user" do
        before do
          user_project_custom_field.custom_values.where(customized: project).first.update!(value: "")
        end

        it "shows the correct value for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(user_project_custom_field) do
              expect(page).to have_text "User field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          user_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(user_project_custom_field) do
              expect(page).to have_text "User field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end
    end

    describe "with weighted item list CF", with_ee: %i[weighted_item_lists] do
      let!(:weighted_item_list) do
        create(:weighted_item_list_project_custom_field,
               projects: [project],
               name: "Weighted item list",
               project_custom_field_section: section_for_input_fields,
               possible_values: %w[Ten])
      end
      let!(:item) { create(:hierarchy_item, weight: 10, label: "Ten") }

      before do
        create(:custom_value, :skip_validations, customized: project, custom_field: weighted_item_list, value: item.id.to_s)
      end

      it "shows the correct value for the project custom field" do
        overview_page.visit_page

        overview_page.within_project_attributes_sidebar do
          overview_page.within_custom_field_container(weighted_item_list) do
            expect(page).to have_text "Ten"
          end
        end
      end
    end

    describe "with multi list CF" do
      describe "with value set by user" do
        it "shows the correct values for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(multi_list_project_custom_field) do
              expect(page).to have_text "Multi list field"
              expect(page).to have_text "Option 1, Option 2"
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          multi_list_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(multi_list_project_custom_field) do
              expect(page).to have_text "Multi list field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end

        context "with a new field" do
          # We need to create a completely new field, just deleting the options is not enough...
          let!(:new_multi_list_project_custom_field) do
            create(:list_project_custom_field,
                   projects: [project],
                   name: "New multi list field",
                   project_custom_field_section: section_for_multi_select_fields,
                   possible_values: ["Option 1", "Option 2", "Option 3"],
                   multi_value: true) do |field|
              create(:custom_value, customized: project, custom_field: field, value: field.custom_options.first.id)
              create(:custom_value, customized: project, custom_field: field, value: field.custom_options.second.id)
            end
          end

          it "does not show the default value(s) for the project custom field if no value given" do
            new_multi_list_project_custom_field.custom_options.first.update!(default_value: true)
            new_multi_list_project_custom_field.custom_options.second.update!(default_value: true)

            overview_page.visit_page

            overview_page.within_project_attributes_sidebar do
              overview_page.within_custom_field_container(new_multi_list_project_custom_field) do
                expect(page).to have_text "New multi list field"
                expect(page).to have_text "Option 1, Option 2"
              end
            end
          end
        end
      end
    end

    describe "with multi version CF" do
      describe "with value set by user" do
        it "shows the correct values for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(multi_version_project_custom_field) do
              expect(page).to have_text "Multi version field"
              expect(page).to have_text "Version 1, Version 2"
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          multi_version_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(multi_version_project_custom_field) do
              expect(page).to have_text "Multi version field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
        end
      end
    end

    describe "with multi user CF" do
      describe "with value set by user" do
        it "shows the correct values for the project custom field if given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(multi_user_project_custom_field) do
              expect(page).to have_text "Multi user field"
              expect(page).to have_css "opce-principal", count: 2
              expect(page).to have_text "Member 1 In Project"
              expect(page).to have_text "Member 2 In Project"
            end
          end
        end
      end

      describe "with no value set by user" do
        before do
          multi_user_project_custom_field.custom_values.where(customized: project).destroy_all
        end

        it "shows an N/A text for the project custom field if no value given" do
          overview_page.visit_page

          overview_page.within_project_attributes_sidebar do
            overview_page.within_custom_field_container(multi_user_project_custom_field) do
              expect(page).to have_text "Multi user field"
              expect(page).to have_text I18n.t("placeholders.default")
            end
          end
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
