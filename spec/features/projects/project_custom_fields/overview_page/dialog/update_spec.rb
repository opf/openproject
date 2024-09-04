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

  describe "with correct updating behaviour" do
    describe "with input fields" do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a custom field checkbox" do
        it "sets the value to true if checked" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content I18n.t("placeholders.default")
          end

          overview_page.open_edit_dialog_for_section(section)

          field.check

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content "Yes"
          end
        end

        it "sets the value to false if unchecked" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content "Yes"
          end

          overview_page.open_edit_dialog_for_section(section)

          field.uncheck

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content "No"
          end
        end

        it "does not change the value if untouched" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content "Yes"
          end

          overview_page.open_edit_dialog_for_section(section)

          # don't touch the input

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content "Yes"
          end
        end
      end

      shared_examples "a custom field input" do
        it "saves the value properly" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content I18n.t("placeholders.default")
          end

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: update_value)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content expected_updated_value
          end
        end

        it "does not change the value if untouched" do
          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content expected_initial_value
          end

          overview_page.open_edit_dialog_for_section(section)

          # don't touch the input

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content expected_initial_value
          end
        end

        it "removes the value properly" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content expected_initial_value
          end

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: "")

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content I18n.t("placeholders.default")
          end
        end
      end

      shared_examples "a rich text custom field input" do
        it "saves the value properly" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text(expected_updated_value)
          end

          overview_page.open_edit_dialog_for_section(section)

          field.set_value(update_value)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text(expected_updated_value)
          end
        end

        it "does not change the value if untouched" do
          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content expected_initial_value
          end

          overview_page.open_edit_dialog_for_section(section)

          # don't touch the input

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_content expected_initial_value
          end
        end

        it "removes the value properly" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text(expected_initial_value)
          end

          overview_page.open_edit_dialog_for_section(section)

          field.set_value("")

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text(expected_initial_value)
          end
        end
      end

      describe "with boolean CF" do
        let(:custom_field) { boolean_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field checkbox"
      end

      describe "with string CF" do
        let(:custom_field) { string_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }
        let(:expected_initial_value) { "Foo" }
        let(:update_value) { "Bar" }
        let(:expected_updated_value) { update_value }

        it_behaves_like "a custom field input"
      end

      describe "with integer CF" do
        let(:custom_field) { integer_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }
        let(:expected_initial_value) { 123 }
        let(:update_value) { 456 }
        let(:expected_updated_value) { update_value }

        it_behaves_like "a custom field input"
      end

      describe "with float CF" do
        let(:custom_field) { float_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }
        let(:expected_initial_value) { 123.456 }
        let(:update_value) { 456.789 }
        let(:expected_updated_value) { update_value }

        it_behaves_like "a custom field input"
      end

      describe "with date CF" do
        let(:custom_field) { date_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }
        let(:expected_initial_value) { "01/01/2024" }
        let(:update_value) { Date.new(2024, 1, 2) }
        let(:expected_updated_value) { "01/02/2024" }

        it_behaves_like "a custom field input"
      end

      describe "with text CF" do
        let(:custom_field) { text_project_custom_field }
        let(:field) { FormFields::Primerized::EditorFormField.new(custom_field) }
        let(:expected_initial_value) { "Lorem" }
        let(:update_value) { "Dolor sit" }
        let(:expected_updated_value) { "Dolor sit" }

        it_behaves_like "a rich text custom field input"
      end
    end

    describe "with select fields" do
      let(:section) { section_for_select_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a select field" do
        it "saves the value properly" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(first_option)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
          end
        end

        it "does not change the value if untouched" do
          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.expect_selected(first_option) # wait for proper initialization
          # don't touch the input

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
          end
        end

        it "removes the value properly" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.clear

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
          end
        end
      end

      describe "with list CF" do
        let(:custom_field) { list_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:first_option) { custom_field.custom_options.first.value }

        it_behaves_like "a select field"
      end

      describe "with version select CF" do
        let(:custom_field) { version_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:first_option) { first_version.name }

        it_behaves_like "a select field"
      end

      describe "with user select CF" do
        let(:custom_field) { user_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:first_option) { member_in_project.name }

        it_behaves_like "a select field"

        describe "with support for user groups" do
          let!(:group) do
            create(:group, name: "Group 1 in project",
                           member_with_roles: { project => reader_role })
          end

          it "saves selected user group properly" do
            custom_field.custom_values.destroy_all

            overview_page.visit_page

            overview_page.open_edit_dialog_for_section(section)

            field.select_option(group.name)

            dialog.submit
            dialog.expect_closed

            overview_page.within_custom_field_container(custom_field) do
              expect(page).to have_text group.name
            end
          end
        end

        describe "with support for placeholder users" do
          let!(:placeholder_user) do
            create(:placeholder_user, name: "Placeholder user",
                                      member_with_roles: { project => reader_role })
          end

          it "saves selected placeholer user properly" do
            custom_field.custom_values.destroy_all

            overview_page.visit_page

            overview_page.open_edit_dialog_for_section(section)

            field.select_option(placeholder_user.name)

            dialog.submit
            dialog.expect_closed

            overview_page.within_custom_field_container(custom_field) do
              expect(page).to have_text placeholder_user.name
            end
          end
        end
      end
    end

    describe "with multi select fields" do
      let(:section) { section_for_multi_select_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a autocomplete multi select field" do
        it "saves single selected values properly" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(first_option)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
          end
        end

        it "saves multi selected values properly" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
            expect(page).to have_no_text second_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(first_option)
          field.select_option(second_option)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_text second_option
          end
        end

        it "removes deselected values properly" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_text second_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.deselect_option(first_option)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
            expect(page).to have_text second_option
          end
        end

        it "does not remove values when not touching the init values" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_text second_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.expect_selected(first_option, second_option) # wait for proper initialization
          # don't touch the values

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_text second_option
          end
        end

        it "removes all values when clearing the input" do
          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_text second_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.clear

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
            expect(page).to have_no_text second_option
          end
        end

        it "adds values properly to init values" do
          custom_field.custom_values.destroy_all

          overview_page.visit_page

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_no_text first_option
            expect(page).to have_no_text second_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(first_option)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_no_text second_option
          end

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(second_option)

          dialog.submit
          dialog.expect_closed

          overview_page.within_custom_field_container(custom_field) do
            expect(page).to have_text first_option
            expect(page).to have_text second_option
          end
        end
      end

      describe "with multi select list CF" do
        let(:custom_field) { multi_list_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:first_option) { custom_field.custom_options.first.value }
        let(:second_option) { custom_field.custom_options.second.value }

        it_behaves_like "a autocomplete multi select field"
      end

      describe "with multi version select list CF" do
        let(:custom_field) { multi_version_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:first_option) { first_version.name }
        let(:second_option) { second_version.name }

        it_behaves_like "a autocomplete multi select field"
      end

      describe "with multi user select list CF" do
        let(:custom_field) { multi_user_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:first_option) { member_in_project.name }
        let(:second_option) { another_member_in_project.name }

        it_behaves_like "a autocomplete multi select field"

        describe "with support for user groups" do
          let!(:group) do
            create(:group, name: "Group 1 in project",
                           member_with_roles: { project => reader_role })
          end
          let!(:another_group) do
            create(:group, name: "Group 2 in project",
                           member_with_roles: { project => reader_role })
          end

          it "saves selected user groups properly" do
            custom_field.custom_values.destroy_all

            overview_page.visit_page

            overview_page.open_edit_dialog_for_section(section)

            field.select_option(group.name)
            field.select_option(another_group.name)

            dialog.submit
            dialog.expect_closed

            overview_page.within_custom_field_container(custom_field) do
              expect(page).to have_text group.name
              expect(page).to have_text another_group.name
            end
          end
        end

        describe "with support for placeholder users" do
          let!(:placeholder_user) do
            create(:placeholder_user, name: "Placeholder user",
                                      member_with_roles: { project => reader_role })
          end
          let!(:another_placeholder_user) do
            create(:placeholder_user, name: "Another placeholder User",
                                      member_with_roles: { project => reader_role })
          end

          it "shows only placeholder users from this project" do
            custom_field.custom_values.destroy_all

            overview_page.visit_page

            overview_page.open_edit_dialog_for_section(section)

            field.select_option(placeholder_user.name)
            field.select_option(another_placeholder_user.name)

            dialog.submit
            dialog.expect_closed

            overview_page.within_custom_field_container(custom_field) do
              expect(page).to have_text placeholder_user.name
              expect(page).to have_text another_placeholder_user.name
            end
          end
        end
      end
    end

    describe "with hidden fields" do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }
      let(:custom_field) { string_project_custom_field }
      let(:field) { FormFields::Primerized::InputField.new(custom_field) }

      before do
        all_fields.without(string_project_custom_field).each { |cf| cf.update(admin_only: true) }
      end

      it "does not clears them after a project admin updates" do
        # TODO: To make the expectations correct, we create an empty custom value for the other
        # project's custom field too. This would happen in the code anyway.
        # Due to the design of the acts_as_customizable plugin and the patch, it will create
        # empty custom values for all the existing custom fields, regardless if they are
        # enabled in the project or not. This happens, because we want to maintain backward
        # compatibility with the existing api, and allow the API to automatically enable
        # custom fields without being activated in the project. This implies in defining
        # all the custom field accessors on every project, and that leads to having the
        # empty custom values created. This is a compromise to avoid further patching the
        # aac plugin and increase complexity. We will also get rid of the patch and this
        # behaviour in a latter ticket https://community.openproject.org/wp/53729 .
        # An extra expectation is added to make sure we don't activate other custom fields,
        # so there are no unwanted side effects.

        create(:custom_value,
               custom_field: boolean_project_custom_field_activated_in_other_project,
               customized: project)

        expected_custom_values =
          project.custom_values.where.not(custom_field: string_project_custom_field)
          .pluck(:customized_type, :customized_id, :custom_field_id, :value)

        expected_custom_fields = project.project_custom_fields

        overview_page.visit_page

        overview_page.open_edit_dialog_for_section(section)

        field.fill_in(with: "new value")
        dialog.submit
        dialog.expect_closed

        custom_values =
          project.custom_values.where.not(custom_field: string_project_custom_field)
          .pluck(:customized_type, :customized_id, :custom_field_id, :value)

        expect(custom_values).to eq(expected_custom_values)
        expect(project.project_custom_fields.reload).to eq(expected_custom_fields)
      end
    end
  end
end
