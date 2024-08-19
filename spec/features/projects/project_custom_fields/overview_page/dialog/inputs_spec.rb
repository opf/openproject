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

  describe "with correct initialization and input behaviour" do
    describe "with input fields" do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a custom field checkbox" do
        it "shows the correct value if given" do
          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            if expected_initial_value
              expect(page).to have_checked_field(custom_field.name)
            else
              expect(page).to have_no_checked_field(custom_field.name)
            end
          end
        end

        it "is unchecked if no value and no default value is given" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            expect(page).to have_no_checked_field(custom_field.name)
          end
        end

        it "shows default value if no value is given" do
          custom_field.custom_values.destroy_all

          custom_field.update!(default_value: true)

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            expect(page).to have_checked_field(custom_field.name)
          end

          custom_field.update!(default_value: false)

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            expect(page).to have_no_checked_field(custom_field.name)
          end
        end
      end

      shared_examples "a custom field input" do
        it "shows the correct value if given" do
          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            expect(page).to have_field(custom_field.name, with: expected_initial_value)
          end
        end

        it "shows a blank input if no value or default value is given" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            expect(page).to have_field(custom_field.name, with: expected_blank_value)
          end
        end

        it "shows the default value if no value is given" do
          custom_field.custom_values.destroy_all
          custom_field.update!(default_value:)

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            expect(page).to have_field(custom_field.name, with: default_value)
          end
        end
      end

      shared_examples "a rich text custom field input" do
        it "shows the correct value if given" do
          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            field.expect_value(expected_initial_value)
          end
        end

        it "shows a blank input if no value or default value is given" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            field.expect_value(expected_blank_value)
          end
        end

        it "shows the default value if no value is given" do
          custom_field.custom_values.destroy_all
          custom_field.update!(default_value:)

          overview_page.open_edit_dialog_for_section(section)

          dialog.within_async_content(close_after_yield: true) do
            field.expect_value(default_value)
          end
        end
      end

      describe "with boolean CF" do
        let(:custom_field) { boolean_project_custom_field }
        let(:expected_initial_value) { true }

        it_behaves_like "a custom field checkbox"
      end

      describe "with string CF" do
        let(:custom_field) { string_project_custom_field }
        let(:default_value) { "Default value" }
        let(:expected_blank_value) { "" }
        let(:expected_initial_value) { "Foo" }

        it_behaves_like "a custom field input"
      end

      describe "with integer CF" do
        let(:custom_field) { integer_project_custom_field }
        let(:default_value) { 789 }
        let(:expected_blank_value) { "" }
        let(:expected_initial_value) { 123 }

        it_behaves_like "a custom field input"
      end

      describe "with float CF" do
        let(:custom_field) { float_project_custom_field }
        let(:default_value) { 789.123 }
        let(:expected_blank_value) { "" }
        let(:expected_initial_value) { 123.456 }

        it_behaves_like "a custom field input"
      end

      describe "with date CF" do
        let(:custom_field) { date_project_custom_field }
        let(:default_value) { Date.new(2026, 1, 1) }
        let(:expected_blank_value) { "" }
        let(:expected_initial_value) { Date.new(2024, 1, 1) }

        it_behaves_like "a custom field input"
      end

      describe "with link CF" do
        let(:custom_field) { link_project_custom_field }
        let(:default_value) { "https://openproject.org" }
        let(:expected_blank_value) { "" }
        let(:expected_initial_value) { "https://www.openproject.org" }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like "a custom field input"

        it "renders the custom field as a link" do
          page.within_test_selector "project-custom-field-#{link_project_custom_field.id}" do
            expect(page).to have_link("https://www.openproject.org", href: "https://www.openproject.org")
          end
        end
      end

      describe "with text CF" do
        let(:custom_field) { text_project_custom_field }
        let(:field) { FormFields::Primerized::EditorFormField.new(custom_field) }
        let(:default_value) { "Default value" }
        let(:expected_blank_value) { "" }
        let(:expected_initial_value) { "Lorem\nipsum" } # TBD: why is the second newline missing?

        it_behaves_like "a rich text custom field input"
      end
    end

    describe "with single select fields" do
      let(:section) { section_for_select_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a autocomplete single select field" do
        it "shows the correct value if given" do
          overview_page.open_edit_dialog_for_section(section)

          field.expect_selected(expected_initial_value)
        end

        it "shows a blank input if no value or default value is given" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          field.expect_blank
        end

        it "filters the list based on the input" do
          overview_page.open_edit_dialog_for_section(section)

          field.search(second_option)

          field.expect_option(second_option)
          field.expect_no_option(first_option)
          field.expect_no_option(third_option)
        end

        it "enables the user to select a single value from a list" do
          overview_page.open_edit_dialog_for_section(section)

          field.search(second_option)
          field.select_option(second_option)

          field.expect_selected(second_option)

          field.search(third_option)
          field.select_option(third_option)

          field.expect_selected(third_option)
          field.expect_not_selected(second_option)
        end

        it "clears the input if clicked on the clear button" do
          overview_page.open_edit_dialog_for_section(section)

          field.clear

          field.expect_blank
        end
      end

      describe "with single select list CF" do
        let(:custom_field) { list_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { custom_field.custom_options.first.value }

        let(:first_option) { custom_field.custom_options.first.value }
        let(:second_option) { custom_field.custom_options.second.value }
        let(:third_option) { custom_field.custom_options.third.value }

        it_behaves_like "a autocomplete single select field"

        it "shows the default value if no value is given" do
          custom_field.custom_values.destroy_all

          custom_field.custom_options.first.update!(default_value: true)

          overview_page.open_edit_dialog_for_section(section)

          field.expect_selected(custom_field.custom_options.first.value)
        end
      end

      describe "with single version select list CF" do
        let(:custom_field) { version_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { first_version.name }

        let(:first_option) { first_version.name }
        let(:second_option) { second_version.name }
        let(:third_option) { third_version.name }

        it_behaves_like "a autocomplete single select field"

        describe "with correct version scoping" do
          context "with a version on a different project" do
            let!(:version_in_other_project) do
              create(:version, name: "Version 1 in other project", project: other_project)
            end

            it "shows only versions that are associated with this project" do
              overview_page.open_edit_dialog_for_section(section)

              field.search("Version 1")

              field.expect_option(first_version.name)
              field.expect_no_option(version_in_other_project.name)
            end
          end

          context "with a closed version" do
            let!(:closed_version) { create(:version, name: "Closed version", project:, status: "closed") }

            before do
              custom_field.update(allow_non_open_versions:)
            end

            context "when non-open versions are not allowed" do
              let(:allow_non_open_versions) { false }

              it "does not shows closed version option" do
                overview_page.open_edit_dialog_for_section(section)
                field.open_options

                field.expect_option(first_version.name)
                field.expect_no_option(closed_version.name)
              end
            end

            context "when non-open versions are allowed" do
              let(:allow_non_open_versions) { true }

              it "shows closed version option" do
                overview_page.open_edit_dialog_for_section(section)
                field.open_options

                field.expect_option(first_version.name)
                field.expect_option(closed_version.name)
              end
            end
          end
        end
      end

      describe "with single user select list CF" do
        let(:custom_field) { user_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { member_in_project.name }

        let(:first_option) { member_in_project.name }
        let(:second_option) { another_member_in_project.name }
        let(:third_option) { one_more_member_in_project.name }

        it_behaves_like "a autocomplete single select field"

        describe "with correct user scoping" do
          let!(:member_in_other_project) do
            create(:user,
                   firstname: "Member 1",
                   lastname: "In other Project",
                   member_with_roles: { other_project => reader_role })
          end

          it "shows only users that are members of the project" do
            overview_page.open_edit_dialog_for_section(section)

            field.search("Member 1")

            field.expect_option(member_in_project.name)
            field.expect_no_option(member_in_other_project.name)
          end
        end

        describe "with support for user groups" do
          let!(:member_in_other_project) do
            create(:user,
                   firstname: "Member 1",
                   lastname: "In other Project",
                   member_with_roles: { other_project => reader_role })
          end
          let!(:group) do
            create(:group, name: "Group 1 in project",
                           member_with_roles: { project => reader_role })
          end
          let!(:group_in_other_project) do
            create(:group, name: "Group 1 in other project", members: [member_in_other_project],
                           member_with_roles: { other_project => reader_role })
          end

          it "shows only groups that are associated with this project" do
            overview_page.open_edit_dialog_for_section(section)

            field.search("Group 1")

            field.expect_option(group.name)
            field.expect_no_option(group_in_other_project.name)
          end
        end

        describe "with support for placeholder users" do
          let!(:placeholder_user) do
            create(:placeholder_user, name: "Placeholder User",
                                      member_with_roles: { project => reader_role })
          end

          it "shows the placeholder user" do
            overview_page.open_edit_dialog_for_section(section)

            field.search("Placeholder User")

            field.expect_option(placeholder_user.name)
          end
        end
      end
    end

    describe "with multi select fields" do
      let(:section) { section_for_multi_select_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples "a autocomplete multi select field" do
        it "shows the correct value if given" do
          overview_page.open_edit_dialog_for_section(section)

          field.expect_selected(*expected_initial_value)
        end

        it "shows a blank input if no value or default value is given" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          field.expect_blank
        end

        it "filters the list based on the input" do
          overview_page.open_edit_dialog_for_section(section)

          field.search(second_option)

          field.expect_option(second_option)
          field.expect_no_option(first_option)
          field.expect_no_option(third_option)
        end

        it "allows to select multiple values" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(second_option)
          field.select_option(third_option)

          field.expect_selected(second_option)
          field.expect_selected(third_option)
        end

        it "allows to remove selected values" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(second_option)
          field.select_option(third_option)

          field.deselect_option(third_option)

          field.expect_selected(second_option)
          field.expect_not_selected(third_option)
        end

        it "allows to remove all selected values at once" do
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          field.select_option(second_option)
          field.select_option(third_option)

          field.clear

          field.expect_not_selected(second_option)
          field.expect_not_selected(third_option)
        end
      end

      describe "with multi select list CF" do
        let(:custom_field) { multi_list_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { [custom_field.custom_options.first.value, custom_field.custom_options.second.value] }

        let(:first_option) { custom_field.custom_options.first.value }
        let(:second_option) { custom_field.custom_options.second.value }
        let(:third_option) { custom_field.custom_options.third.value }

        it_behaves_like "a autocomplete multi select field"

        it "shows the default value if no value is given" do
          multi_list_project_custom_field.custom_values.destroy_all

          multi_list_project_custom_field.custom_options.first.update!(default_value: true)
          multi_list_project_custom_field.custom_options.second.update!(default_value: true)

          overview_page.open_edit_dialog_for_section(section)

          field.expect_selected(multi_list_project_custom_field.custom_options.first.value)
          field.expect_selected(multi_list_project_custom_field.custom_options.second.value)
        end
      end

      describe "with multi version select list CF" do
        let(:custom_field) { multi_version_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { [first_version.name, second_version.name] }

        let(:first_option) { first_version.name }
        let(:second_option) { second_version.name }
        let(:third_option) { third_version.name }

        it_behaves_like "a autocomplete multi select field"

        describe "with correct version scoping" do
          context "with a version on a different project" do
            let!(:version_in_other_project) do
              create(:version, name: "Version 1 in other project", project: other_project)
            end

            it "shows only versions that are associated with this project" do
              overview_page.open_edit_dialog_for_section(section)

              field.search("Version 1")

              field.expect_option(first_version.name)
              field.expect_no_option(version_in_other_project.name)
            end
          end

          context "with a closed version" do
            let!(:closed_version) { create(:version, name: "Closed version", project:, status: "closed") }

            before do
              custom_field.update(allow_non_open_versions:)
            end

            context "when non-open versions are not allowed" do
              let(:allow_non_open_versions) { false }

              it "does not shows closed version option" do
                overview_page.open_edit_dialog_for_section(section)
                field.open_options

                field.expect_option(first_version.name)
                field.expect_no_option(closed_version.name)
              end
            end

            context "when non-open versions are allowed" do
              let(:allow_non_open_versions) { true }

              it "shows closed version option" do
                overview_page.open_edit_dialog_for_section(section)
                field.open_options

                field.expect_option(first_version.name)
                field.expect_option(closed_version.name)
              end
            end
          end
        end
      end

      describe "with multi user select list CF" do
        let(:custom_field) { multi_user_project_custom_field }
        let(:field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { [member_in_project.name, another_member_in_project.name] }

        let(:first_option) { member_in_project.name }
        let(:second_option) { another_member_in_project.name }
        let(:third_option) { one_more_member_in_project.name }

        it_behaves_like "a autocomplete multi select field"

        describe "with correct user scoping" do
          let!(:member_in_other_project) do
            create(:user,
                   firstname: "Member 1",
                   lastname: "In other Project",
                   member_with_roles: { other_project => reader_role })
          end

          it "shows only users that are members of the project" do
            overview_page.open_edit_dialog_for_section(section)

            field.search("Member 1")

            field.expect_option(member_in_project.name)
            field.expect_no_option(member_in_other_project.name)
          end
        end

        describe "with support for user groups" do
          let!(:member_in_other_project) do
            create(:user,
                   firstname: "Member 1",
                   lastname: "In other Project",
                   member_with_roles: { other_project => reader_role })
          end
          let!(:group) do
            create(:group, name: "Group 1 in project",
                           member_with_roles: { project => reader_role })
          end
          let!(:another_group) do
            create(:group, name: "Group 2 in project",
                           member_with_roles: { project => reader_role })
          end
          let!(:group_in_other_project) do
            create(:group, name: "Group 1 in other project", members: [member_in_other_project],
                           member_with_roles: { other_project => reader_role })
          end

          it "shows only groups that are associated with this project" do
            overview_page.open_edit_dialog_for_section(section)

            field.search("Group 1")
            field.expect_option(group.name)
            field.expect_no_option(group_in_other_project.name)
          end

          it "enables to select multiple user groups" do
            overview_page.open_edit_dialog_for_section(section)

            field.select_option("Group 1 in project")
            field.select_option("Group 2 in project")

            field.expect_selected("Group 1 in project")
            field.expect_selected("Group 2 in project")
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
          let!(:placeholder_user_in_other_project) do
            create(:placeholder_user, name: "Placeholder user in other project",
                                      member_with_roles: { other_project => reader_role })
          end

          it "shows only placeholder users from this project" do
            overview_page.open_edit_dialog_for_section(section)

            field.search("Placeholder User")

            field.expect_option(placeholder_user.name)
            field.expect_option(another_placeholder_user.name)
            field.expect_no_option(placeholder_user_in_other_project.name)
          end

          it "enables to select multiple placeholder users" do
            overview_page.open_edit_dialog_for_section(section)

            field.select_option(placeholder_user.name)
            field.select_option(another_placeholder_user.name)

            field.expect_selected(placeholder_user.name)
            field.expect_selected(another_placeholder_user.name)
          end
        end
      end
    end
  end
end
