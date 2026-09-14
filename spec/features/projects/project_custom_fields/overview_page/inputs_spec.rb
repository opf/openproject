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
  include_context "with seeded projects, members and project custom fields", seed_all: false

  let(:overview_page) { Pages::Projects::Show.new(project) }
  let(:user) { member_with_project_attributes_edit_permissions }

  before do
    login_as user

    custom_field
    case custom_field.field_format
    when "version"
      first_version
      second_version
      third_version
    when "user"
      member_in_project
      another_member_in_project
      one_more_member_in_project
    end

    overview_page.visit_page
  end

  describe "with correct initialization and input behaviour" do
    def field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)

    describe "with single select fields" do
      shared_examples "an autocomplete single select field" do |widget_interactions: true|
        it "shows the correct value if given" do
          field.within_field do
            form_field.expect_selected(expected_initial_value)
          end
        end

        if widget_interactions
          it "shows a blank input if no value or default value is given" do
            custom_field.custom_values.destroy_all

            field.within_field do
              form_field.expect_blank
            end
          end

          it "filters the list based on the input" do
            field.within_field do
              form_field.search(second_option)

              form_field.expect_option(second_option)
              form_field.expect_no_option(first_option)
              form_field.expect_no_option(third_option)
            end
          end

          it "enables the user to select a single value from a list" do
            field.within_field do
              form_field.search(second_option)
              form_field.select_option(second_option)

              form_field.expect_selected(second_option)

              form_field.search(third_option)
              form_field.select_option(third_option)

              form_field.expect_selected(third_option)
              form_field.expect_not_selected(second_option)
            end
          end

          it "clears the input if clicked on the clear button" do
            field.within_field do
              form_field.clear
              form_field.expect_blank
            end
          end
        end

      end

      describe "with single select list CF" do
        let(:custom_field) { list_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { custom_field.custom_options.first.value }

        let(:first_option) { custom_field.custom_options.first.value }
        let(:second_option) { custom_field.custom_options.second.value }
        let(:third_option) { custom_field.custom_options.third.value }

        it_behaves_like "an autocomplete single select field"
      end

      describe "with single version select list CF" do
        let(:custom_field) { version_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { first_version.name }

        let(:first_option) { first_version.name }
        let(:second_option) { second_version.name }
        let(:third_option) { third_version.name }

        it_behaves_like "an autocomplete single select field", widget_interactions: false

        describe "with correct version scoping" do
          context "with a version on a different project" do
            let!(:version_in_other_project) do
              create(:version, name: "Version 1 in other project", project: other_project)
            end

            it "shows only versions that are associated with this project" do
              field.within_field do
                form_field.search("Version 1")
                form_field.expect_option(first_version.name, grouping: project.name)
                form_field.expect_no_option(version_in_other_project.name)
              end
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
                field.within_field do
                  form_field.open_options

                  form_field.expect_option(first_version.name)
                  form_field.expect_no_option(closed_version.name)
                end
              end
            end

            context "when non-open versions are allowed" do
              let(:allow_non_open_versions) { true }

              it "shows closed version option" do
                field.within_field do
                  form_field.open_options

                  form_field.expect_option(first_version.name)
                  form_field.expect_option(closed_version.name)
                end
              end
            end
          end
        end
      end

      describe "with single user select list CF" do
        let(:custom_field) { user_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { member_in_project.name }

        let(:first_option) { member_in_project.name }
        let(:second_option) { another_member_in_project.name }
        let(:third_option) { one_more_member_in_project.name }

        it_behaves_like "an autocomplete single select field", widget_interactions: false

        describe "with correct user scoping" do
          let!(:member_in_other_project) do
            create(:user,
                   firstname: "Member 1",
                   lastname: "In other Project",
                   member_with_roles: { other_project => reader_role })
          end

          it "shows only users that are members of the project" do
            field.within_field do
              form_field.search("Member 1")

              form_field.expect_option(member_in_project.name)
              form_field.expect_no_option(member_in_other_project.name)
            end
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
            field.within_field do
              form_field.search("Group 1")

              form_field.expect_option(group.name)
              form_field.expect_no_option(group_in_other_project.name)
            end
          end
        end

        describe "with support for placeholder users" do
          let!(:placeholder_user) do
            create(:placeholder_user, name: "Placeholder User",
                                      member_with_roles: { project => reader_role })
          end

          it "shows the placeholder user" do
            field.within_field do
              form_field.search("Placeholder User")

              form_field.expect_option(placeholder_user.name)
            end
          end
        end
      end
    end

    describe "with multi select fields" do
      shared_examples "an autocomplete multi select field" do
        it "shows the correct value if given" do
          field.within_field do
            form_field.expect_selected(*expected_initial_value)
          end
        end

        it "shows a blank input if no value or default value is given" do
          custom_field.custom_values.destroy_all

          field.within_field do
            form_field.expect_blank
          end
        end

        it "filters the list based on the input" do
          field.within_field do
            form_field.search(second_option)

            form_field.expect_option(second_option)
            form_field.expect_no_option(first_option)
            form_field.expect_no_option(third_option)
          end
        end

        it "allows to select multiple values" do
          custom_field.custom_values.destroy_all

          field.within_field do
            form_field.select_option(second_option)
            form_field.select_option(third_option)

            form_field.expect_selected(second_option)
            form_field.expect_selected(third_option)
          end
        end

        it "allows to remove selected values" do
          custom_field.custom_values.destroy_all

          field.within_field do
            form_field.select_option(second_option)
            form_field.select_option(third_option)

            form_field.deselect_option(third_option)

            form_field.expect_selected(second_option)
            form_field.expect_not_selected(third_option)
          end
        end

        it "allows to remove all selected values at once" do
          custom_field.custom_values.destroy_all

          field.within_field do
            form_field.select_option(second_option)
            form_field.select_option(third_option)

            form_field.clear

            form_field.expect_not_selected(second_option)
            form_field.expect_not_selected(third_option)
          end
        end
      end

      describe "with multi select list CF" do
        let(:custom_field) { multi_list_project_custom_field }
        let(:form_field) { FormFields::Primerized::AutocompleteField.new(custom_field) }

        let(:expected_initial_value) { [custom_field.custom_options.first.value, custom_field.custom_options.second.value] }

        let(:first_option) { custom_field.custom_options.first.value }
        let(:second_option) { custom_field.custom_options.second.value }
        let(:third_option) { custom_field.custom_options.third.value }

        it_behaves_like "an autocomplete multi select field"
      end

    end
  end
end
