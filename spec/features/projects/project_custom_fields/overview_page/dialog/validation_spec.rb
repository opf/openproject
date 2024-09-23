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
require_relative "../shared_context"

RSpec.describe "Edit project custom fields on project overview page", :js do
  include_context "with seeded projects, members and project custom fields"

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    login_as member_with_project_attributes_edit_permissions
    overview_page.visit_page
  end

  describe "with correct validation behaviour" do
    describe "after validation" do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      it "keeps showing only activated custom fields (tricky regression)" do
        custom_field = string_project_custom_field
        custom_field.update!(is_required: true)
        field = FormFields::Primerized::InputField.new(custom_field)

        overview_page.open_edit_dialog_for_section(section)

        dialog.within_async_content do
          containers = dialog.input_containers

          expect(containers[0].text).to include("Boolean field")
          expect(containers[1].text).to include("String field")
          expect(containers[2].text).to include("Integer field")
          expect(containers[3].text).to include("Float field")
          expect(containers[4].text).to include("Date field")
          expect(containers[5].text).to include("Link field")
          expect(containers[6].text).to include("Text field")

          expect(page).to have_no_text(boolean_project_custom_field_activated_in_other_project.name)
        end

        field.fill_in(with: "") # this will trigger the validation

        dialog.submit

        field.expect_error(I18n.t("activerecord.errors.messages.blank"))

        dialog.within_async_content do
          containers = dialog.input_containers

          expect(containers[0].text).to include("Boolean field")
          expect(containers[1].text).to include("String field")
          expect(containers[2].text).to include("Integer field")
          expect(containers[3].text).to include("Float field")
          expect(containers[4].text).to include("Date field")
          expect(containers[5].text).to include("Link field")
          expect(containers[6].text).to include("Text field")

          expect(page).to have_no_text(boolean_project_custom_field_activated_in_other_project.name)
        end
      end

      describe "does not loose the unpersisted values of the custom fields" do
        context "with input fields" do
          let(:section) { section_for_input_fields }

          let(:invalid_custom_field) { string_project_custom_field }
          let(:valid_custom_field) { integer_project_custom_field }
          let(:invalid_field) { FormFields::Primerized::InputField.new(invalid_custom_field) }
          let(:valid_field) { FormFields::Primerized::InputField.new(valid_custom_field) }

          it "keeps the value" do
            invalid_custom_field.update!(is_required: true)
            overview_page.open_edit_dialog_for_section(section)

            invalid_field.fill_in(with: "")
            valid_field.fill_in(with: "123")

            dialog.submit

            invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

            invalid_field.expect_value("")
            valid_field.expect_value("123")
          end
        end

        context "with select fields" do
          let(:section) { section_for_select_fields }

          context "with version selected" do
            let(:invalid_custom_field) { list_project_custom_field }
            let(:valid_custom_field) { version_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }
            let(:valid_field) { FormFields::Primerized::AutocompleteField.new(valid_custom_field) }

            it "keeps the value" do
              invalid_custom_field.update!(is_required: true)
              overview_page.open_edit_dialog_for_section(section)

              invalid_field.clear
              valid_field.select_option(third_version.name)

              dialog.submit

              invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

              invalid_field.expect_blank
              valid_field.expect_selected(third_version.name)
            end
          end

          context "with user selected" do
            let(:invalid_custom_field) { list_project_custom_field }
            let(:valid_custom_field) { user_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }
            let(:valid_field) { FormFields::Primerized::AutocompleteField.new(valid_custom_field) }

            it "keeps the value" do
              invalid_custom_field.update!(is_required: true)
              overview_page.open_edit_dialog_for_section(section)

              invalid_field.clear
              valid_field.select_option(another_member_in_project.name)

              dialog.submit

              invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

              invalid_field.expect_blank
              valid_field.expect_selected(another_member_in_project.name)
            end
          end

          context "with list selected" do
            let(:invalid_custom_field) { user_project_custom_field }
            let(:valid_custom_field) { list_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }
            let(:valid_field) { FormFields::Primerized::AutocompleteField.new(valid_custom_field) }

            it "keeps the value" do
              invalid_custom_field.update!(is_required: true)
              overview_page.open_edit_dialog_for_section(section)

              invalid_field.clear
              valid_field.select_option("Option 3")

              dialog.submit

              invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

              invalid_field.expect_blank
              valid_field.expect_selected("Option 3")
            end
          end
        end

        context "with multi select fields" do
          let(:section) { section_for_multi_select_fields }

          context "with multi version selected" do
            let(:invalid_custom_field) { multi_list_project_custom_field }
            let(:valid_custom_field) { multi_version_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }
            let(:valid_field) { FormFields::Primerized::AutocompleteField.new(valid_custom_field) }

            it "keeps the values" do
              invalid_custom_field.update!(is_required: true)
              overview_page.open_edit_dialog_for_section(section)

              invalid_field.clear
              valid_field.close_autocompleter
              valid_field.clear
              valid_field.select_option(first_version.name, third_version.name)

              dialog.submit

              invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

              invalid_field.expect_blank
              valid_field.expect_selected(first_version.name, third_version.name)
            end
          end

          context "with multi user selected" do
            let(:invalid_custom_field) { multi_list_project_custom_field }
            let(:valid_custom_field) { multi_user_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }
            let(:valid_field) { FormFields::Primerized::AutocompleteField.new(valid_custom_field) }

            it "keeps the values" do
              invalid_custom_field.update!(is_required: true)
              overview_page.open_edit_dialog_for_section(section)

              invalid_field.clear
              valid_field.clear
              valid_field.select_option(member_in_project.name, one_more_member_in_project.name)

              dialog.submit

              invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

              invalid_field.expect_blank
              valid_field.expect_selected(member_in_project.name, one_more_member_in_project.name)
            end
          end

          context "with multi list selected" do
            let(:invalid_custom_field) { multi_user_project_custom_field }
            let(:valid_custom_field) { multi_list_project_custom_field }
            let(:invalid_field) { FormFields::Primerized::AutocompleteField.new(invalid_custom_field) }
            let(:valid_field) { FormFields::Primerized::AutocompleteField.new(valid_custom_field) }

            it "keeps the value" do
              invalid_custom_field.update!(is_required: true)
              overview_page.open_edit_dialog_for_section(section)

              invalid_field.clear
              valid_field.clear
              valid_field.select_option("Option 1", "Option 3")

              dialog.submit

              invalid_field.expect_error(I18n.t("activerecord.errors.messages.blank"))

              invalid_field.expect_blank
              valid_field.expect_selected("Option 1", "Option 3")
            end
          end
        end
      end
    end

    describe "editing multiple sections" do
      let(:input_fields_dialog) do
        Components::Projects::ProjectCustomFields::EditDialog.new(project, section_for_input_fields)
      end
      let(:select_fields_dialog) do
        Components::Projects::ProjectCustomFields::EditDialog.new(project, section_for_select_fields)
      end
      let(:field) { FormFields::Primerized::AutocompleteField.new(list_project_custom_field) }

      it "displays validation errors, when the previous section modal was canceled (Regression)" do
        list_project_custom_field.update!(is_required: true)
        list_project_custom_field.custom_values.destroy_all

        overview_page.open_edit_dialog_for_section(section_for_input_fields)
        input_fields_dialog.close
        overview_page.open_edit_dialog_for_section(section_for_select_fields)
        select_fields_dialog.submit

        field.expect_error(I18n.t("activerecord.errors.messages.blank"))
      end
    end

    describe "with input fields" do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a custom field input" do
        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.submit

          field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      # boolean CFs can not be validated

      describe "with string CF" do
        let(:custom_field) { string_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with integer CF" do
        let(:custom_field) { integer_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with float CF" do
        let(:custom_field) { float_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with date CF" do
        let(:custom_field) { date_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"
      end

      describe "with text CF" do
        let(:custom_field) { text_project_custom_field }
        let(:field) { FormFields::Primerized::EditorFormField.new(custom_field) }

        it_behaves_like "a custom field input"
      end
    end

    describe "with select fields" do
      let(:section) { section_for_select_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a custom field select" do
        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.submit

          field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      describe "with list CF" do
        let(:custom_field) { list_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field select"
      end

      describe "with version CF" do
        let(:custom_field) { version_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field select"
      end

      describe "with user CF" do
        let(:custom_field) { user_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field select"
      end
    end

    describe "with multi select fields" do
      let(:section) { section_for_multi_select_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a custom field multi select" do
        it "shows an error if the value is invalid" do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.submit

          field.expect_error(I18n.t("activerecord.errors.messages.blank"))
        end
      end

      describe "with multi list CF" do
        let(:custom_field) { multi_list_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field multi select"
      end

      describe "with multi version CF" do
        let(:custom_field) { multi_version_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field multi select"
      end

      describe "with multi user CF" do
        let(:custom_field) { multi_user_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        it_behaves_like "a custom field multi select"
      end
    end
  end
end
