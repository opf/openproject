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

RSpec.describe "Edit project custom fields on project overview page", :js do
  include_context "with seeded projects, members and project custom fields"

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    login_as member_with_project_attributes_edit_permissions
    overview_page.visit_page
  end

  describe "with correct validation behaviour" do
    describe "after validation" do
      it "keeps showing only activated custom fields (tricky regression)" do
        custom_field = string_project_custom_field
        custom_field.update!(is_required: true)
        form_field = FormFields::Primerized::InputField.new(custom_field)

        field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)

        field.within_field do
          expect(page).to have_text("String field")
          expect(page).to have_no_text(boolean_project_custom_field_activated_in_other_project.name)
        end

        form_field.fill_in(with: "") # this will trigger the validation

        field.submit

        form_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

        field.within_field do
          expect(page).to have_text("String field")
          expect(page).to have_no_text(boolean_project_custom_field_activated_in_other_project.name)
        end
      end

      describe "does not loose the unpersisted values" do
        shared_examples "keeps the unpersisted values" do
          it "keeps the value" do
            invalid_custom_field.update!(is_required: true)
            refresh
            field = overview_page.open_inplace_edit_field_for_custom_field(invalid_custom_field)
            invalid_field.clear
            field.submit

            invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
            invalid_field.expect_blank
          end

          it "keeps the custom comment value" do
            invalid_custom_field.update!(is_required: true, has_comment: true)
            refresh
            dialog = overview_page.open_modal_for_custom_field(invalid_custom_field)
            invalid_field.clear
            fill_in "Comment", with: "A helpful comment"
            dialog.submit

            invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
            expect(page).to have_field("Comment", with: "A helpful comment")
          end
        end

        context "with input fields" do
          let(:invalid_custom_field) { string_project_custom_field }
          let(:invalid_field) { FormFields::Primerized::InputField.new(invalid_custom_field) }

          it_behaves_like "keeps the unpersisted values"
        end

        context "with select fields" do
          context "with version selected" do
            let(:invalid_custom_field) { version_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }

            it_behaves_like "keeps the unpersisted values"
          end

          context "with user selected" do
            let(:invalid_custom_field) { user_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }

            it_behaves_like "keeps the unpersisted values"
          end

          context "with list selected" do
            let(:invalid_custom_field) { list_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }

            it_behaves_like "keeps the unpersisted values"
          end
        end

        context "with multi select fields" do
          context "with multi version selected" do
            let(:invalid_custom_field) { multi_version_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }

            it_behaves_like "keeps the unpersisted values"
          end

          context "with multi user selected" do
            let(:invalid_custom_field) { multi_user_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }

            it_behaves_like "keeps the unpersisted values"
          end

          context "with multi list selected" do
            let(:invalid_custom_field) { multi_list_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }

            it_behaves_like "keeps the unpersisted values"
          end
        end
      end
    end

    describe "editing multiple fields" do
      let(:form_field) { FormFields::Primerized::AutocompleteField.new(list_project_custom_field) }

      it "displays validation errors, when the previous modal was canceled (Regression)" do
        list_project_custom_field.update!(is_required: true)
        list_project_custom_field.custom_values.destroy_all

        field = overview_page.open_inplace_edit_field_for_custom_field(string_project_custom_field)
        field.close

        field = overview_page.open_inplace_edit_field_for_custom_field(list_project_custom_field)
        field.submit

        form_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
      end

      context "with required custom fields in different sections" do
        let(:string_field) { FormFields::Primerized::InputField.new(string_project_custom_field) }
        let(:list_field) { FormFields::Primerized::AutocompleteField.new(list_project_custom_field) }
        let(:multi_list_field) { FormFields::Primerized::AutocompleteField.new(multi_list_project_custom_field) }

        before do
          # Make both custom fields required
          string_project_custom_field.update!(is_required: true)
          list_project_custom_field.update!(is_required: true)

          # Clear existing values
          string_project_custom_field.custom_values.destroy_all
          list_project_custom_field.custom_values.destroy_all
        end

        it "validates required fields only within their respective sections" do
          # Test 1: Multi-select field can be saved even when other required fields are invalid
          multi_list_inplace_field =
            overview_page.open_inplace_edit_field_for_custom_field(multi_list_project_custom_field)

          multi_list_inplace_field.submit
          multi_list_inplace_field.expect_close

          # Test 2: Edit the required string field
          string_field_inplace_field =
            overview_page.open_inplace_edit_field_for_custom_field(string_project_custom_field)

          # Submit without filling - should show error
          string_field_inplace_field.submit
          string_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
          string_field_inplace_field.close

          # Test 3: Edit the required list field
          list_field_inplace_field =
            overview_page.open_inplace_edit_field_for_custom_field(list_project_custom_field)

          # Submit without filling - should show error
          list_field_inplace_field.submit
          list_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

          # Test 4: Fill required field and submit successfully
          list_field.select_option("Option 1")
          list_field_inplace_field.submit
          list_field_inplace_field.expect_close

          # Test 5: The required string field dialog still fails validation when empty
          string_field_inplace_field =
            overview_page.open_inplace_edit_field_for_custom_field(string_project_custom_field)
          string_field_inplace_field.submit
          string_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

          # Test 6: Complete the required string field and expect to pass validation
          string_field.fill_in(with: "Test value")
          string_field_inplace_field.submit
          string_field_inplace_field.expect_close
        end
      end
    end

    describe "with input fields" do
      shared_examples "a custom field input" do
        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)

          field.submit

          form_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      # boolean CFs can not be validated

      describe "with string CF" do
        let(:custom_field) { string_project_custom_field }
        let(:form_field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with integer CF" do
        let(:custom_field) { integer_project_custom_field }
        let(:form_field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with float CF" do
        let(:custom_field) { float_project_custom_field }
        let(:form_field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with date CF" do
        let(:custom_field) { date_project_custom_field }
        let(:form_field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with text CF" do
        let(:custom_field) { text_project_custom_field }
        let(:form_field) do
          FormFields::Primerized::EditorFormField.new(
            custom_field,
            selector: "[data-test-selector='augmented-text-area-custom_field_#{custom_field.id}']"
          )
        end

        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          dialog = overview_page.open_modal_for_custom_field(custom_field).dialog

          dialog.submit

          form_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      describe "with calculated value CFs" do
        shared_examples "a calculated custom field input" do
          it "allows saving the dialog even if the calculated custom field is invalid" do
            custom_field.custom_values.destroy_all

            field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)

            field.submit

            field.expect_close
          end
        end

        describe "using int" do
          before do
            # prevent calculation from happening
            calculated_from_int_project_custom_field.custom_values.delete_all
            calculated_from_int_project_custom_field.update!(is_required: true)
          end

          let(:custom_field) { integer_project_custom_field }
          let(:calculated_field) { calculated_from_int_project_custom_field }

          it_behaves_like "a calculated custom field input"
        end

        describe "using int and float" do
          before do
            # prevent calculation from happening
            calculated_from_int_and_float_project_custom_field.custom_values.delete_all
            calculated_from_int_and_float_project_custom_field.update!(is_required: true)
          end

          let(:custom_field) { integer_project_custom_field }
          let(:calculated_field) { calculated_from_int_and_float_project_custom_field }

          it_behaves_like "a calculated custom field input"
        end
      end
    end

    describe "with select fields" do
      shared_examples "a custom field select" do
        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          dialog = overview_page.open_inplace_edit_field_for_custom_field(custom_field)

          dialog.submit

          form_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      describe "with list CF" do
        let(:custom_field) { list_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field select"
      end

      describe "with version CF" do
        let(:custom_field) { version_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field select"
      end

      describe "with user CF" do
        let(:custom_field) { user_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field select"
      end
    end

    describe "with multi select fields" do
      shared_examples "a custom field multi select" do
        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)

          field.submit

          form_field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      describe "with multi list CF" do
        let(:custom_field) { multi_list_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field multi select"
      end

      describe "with multi version CF" do
        let(:custom_field) { multi_version_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field multi select"
      end

      describe "with multi user CF" do
        let(:custom_field) { multi_user_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field multi select"
      end
    end
  end
end
