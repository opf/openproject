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

RSpec.describe "Projects", "creation",
               :js,
               :with_cuprite do
  shared_let(:name_field) { FormFields::InputFormField.new :name }
  shared_let(:project_custom_field_section) { create(:project_custom_field_section, name: "Section A") }

  current_user { create(:admin) }

  shared_let(:project) { create(:project, name: "Foo project", identifier: "foo-project") }

  let(:projects_page) { Pages::Projects::Index.new }

  before do
    projects_page.visit!
  end

  context "with the button on the toolbar items" do
    it "can navigate to the create project page" do
      projects_page.navigate_to_new_project_page_from_toolbar_items

      expect(page).to have_current_path(new_project_path)
    end
  end

  it "can create a project" do
    projects_page.navigate_to_new_project_page_from_toolbar_items

    name_field.set_value "Foo bar"
    click_button "Save"

    expect(page).to have_current_path /\/projects\/foo-bar\/?/
    expect(page).to have_content "Foo bar"
  end

  it "does not create a project with an already existing identifier" do
    projects_page.navigate_to_new_project_page_from_toolbar_items

    name_field.set_value "Foo project"
    click_on "Save"

    expect(page).to have_current_path /\/projects\/foo-project-1\/?/

    project = Project.last
    expect(project.identifier).to eq "foo-project-1"
  end

  context "with a multi-select custom field" do
    let!(:list_custom_field) do
      create(:list_project_custom_field, name: "List CF", multi_value: true, project_custom_field_section:)
    end
    let(:list_field) { FormFields::SelectFormField.new list_custom_field }

    it "can create a project" do
      projects_page.navigate_to_new_project_page_from_toolbar_items

      name_field.set_value "Foo bar"

      find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

      list_field.select_option "A", "B"

      click_button "Save"

      expect(page).to have_current_path /\/projects\/foo-bar\/?/
      expect(page).to have_content "Foo bar"

      project = Project.last
      expect(project.name).to eq "Foo bar"
      cvs = project.custom_value_for(list_custom_field)
      expect(cvs.count).to eq 2
      expect(cvs.map(&:typed_value)).to contain_exactly "A", "B"
    end
  end

  it "hides the active field and the identifier" do
    visit new_project_path

    find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

    expect(page).to have_no_content "Active"
    expect(page).to have_no_content "Identifier"
  end

  context "with optional and required custom fields" do
    let!(:optional_custom_field) do
      create(:project_custom_field, name: "Optional Foo",
                                    field_format: "string",
                                    is_for_all: true,
                                    project_custom_field_section:)
    end
    let!(:required_custom_field) do
      create(:project_custom_field, name: "Required Foo",
                                    field_format: "string",
                                    is_for_all: true,
                                    is_required: true,
                                    project_custom_field_section:)
    end

    it "separates optional and required custom fields for new" do
      visit new_project_path

      expect(page).to have_content "Required Foo"

      click_on "Advanced settings"

      within(".op-fieldset") do
        expect(page).to have_text "Optional Foo"
        expect(page).to have_no_text "Required Foo"
      end
    end

    context "with correct validations" do
      before do
        visit new_project_path
      end

      it "requires the required custom field" do
        click_on "Save"

        expect(page).to have_content "Required Foo can't be blank"
        expect(page).to have_no_content "Optional Foo can't be blank"
      end
    end

    context "with correct custom field activation" do
      let!(:unused_custom_field) do
        create(:project_custom_field, name: "Unused Foo",
                                      field_format: "string",
                                      project_custom_field_section:)
      end

      before do
        visit new_project_path
        fill_in "Name", with: "Foo bar"
        fill_in "Required Foo", with: "Required value"

        click_on "Advanced settings"
      end

      it "enables custom fields with provided values for this project" do
        fill_in "Optional Foo", with: "Optional value"
        fill_in "Unused Foo", with: ""

        click_on "Save"

        expect(page).to have_current_path /\/projects\/foo-bar\/?/

        project = Project.last

        # unused custom field should not be activated
        expect(project.project_custom_field_ids).to contain_exactly(
          optional_custom_field.id, required_custom_field.id
        )
      end

      context "with correct handling of default values" do
        let!(:custom_field_with_default_value) do
          create(:project_custom_field, name: "Foo with default value",
                                        field_format: "string",
                                        default_value: "Default value",
                                        project_custom_field_section:)
        end

        before do
          visit new_project_path
          fill_in "Name", with: "Foo bar"
          fill_in "Required Foo", with: "Required value"

          click_on "Advanced settings"
        end

        it "enables custom fields with default values if not set to blank explicitly" do
          # don't touch the default value
          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          # custom_field_with_default_value should be activated and contain the default value
          expect(project.project_custom_field_ids).to contain_exactly(
            custom_field_with_default_value.id, required_custom_field.id
          )

          expect(project.custom_value_for(custom_field_with_default_value).value).to eq("Default value")
        end

        it "does not enable custom fields with default values if set to blank explicitly" do
          # native blank input does not work with this input, using support class here
          field = FormFields::InputFormField.new(custom_field_with_default_value)
          field.set_value("")

          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          # custom_field_with_default_value should not be activated
          expect(project.project_custom_field_ids).to contain_exactly(
            required_custom_field.id
          )
        end

        it "does enable custom fields with default values if overwritten with a new value" do
          fill_in "Foo with default value", with: "foo"

          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          # custom_field_with_default_value should be activated and contain the overwritten value
          expect(project.project_custom_field_ids).to contain_exactly(
            custom_field_with_default_value.id, required_custom_field.id
          )

          expect(project.custom_value_for(custom_field_with_default_value).value).to eq("foo")
        end
      end

      context "with correct handling of optional boolean values" do
        let!(:custom_boolean_field_default_true) do
          create(:project_custom_field, name: "Boolean with default true",
                                        field_format: "bool",
                                        default_value: true,
                                        project_custom_field_section:)
        end

        let!(:custom_boolean_field_default_false) do
          create(:project_custom_field, name: "Boolean with default false",
                                        field_format: "bool",
                                        default_value: false,
                                        project_custom_field_section:)
        end

        let!(:custom_boolean_field_with_no_default) do
          create(:project_custom_field, name: "Boolean with no default",
                                        field_format: "bool",
                                        project_custom_field_section:)
        end

        before do
          visit new_project_path
          fill_in "Name", with: "Foo bar"
          fill_in "Required Foo", with: "Required value"

          click_on "Advanced settings"
        end

        it "only enables boolean custom fields with default values if untouched" do
          # do not touch any of the boolean fields
          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          expect(project.project_custom_field_ids).to contain_exactly(
            required_custom_field.id,
            custom_boolean_field_default_true.id,
            custom_boolean_field_default_false.id
          )

          expect(project.custom_value_for(custom_boolean_field_default_true).typed_value).to be_truthy
          expect(project.custom_value_for(custom_boolean_field_default_false).typed_value).to be_falsy
        end

        it "enables boolean custom fields without default values if set to true explicitly" do
          check "Boolean with no default"

          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          expect(project.project_custom_field_ids).to contain_exactly(
            required_custom_field.id,
            custom_boolean_field_default_true.id,
            custom_boolean_field_default_false.id,
            custom_boolean_field_with_no_default.id
          )

          expect(project.custom_value_for(custom_boolean_field_with_no_default).typed_value).to be_truthy
        end

        it "enables boolean custom fields with default values if set to false explicitly" do
          uncheck "Boolean with default true"

          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          expect(project.project_custom_field_ids).to contain_exactly(
            required_custom_field.id,
            custom_boolean_field_default_true.id,
            custom_boolean_field_default_false.id
          )

          expect(project.custom_value_for(custom_boolean_field_default_true).typed_value).to be_falsy
        end
      end
    end

    context "with correct handling of invisible values" do
      let!(:invisible_field) do
        create(:string_project_custom_field, name: "Text for Admins only",
                                             admin_only: true,
                                             project_custom_field_section:)
      end

      before do
        visit new_project_path
        fill_in "Name", with: "Foo bar"
        fill_in "Required Foo", with: "Required value"

        click_on "Advanced settings"
      end

      context "with an admin user" do
        it "shows invisible fields in the form and allows their activation" do
          expect(page).to have_content "Text for Admins only"

          fill_in "Text for Admins only", with: "foo"

          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          expect(project.project_custom_field_ids).to contain_exactly(
            required_custom_field.id, invisible_field.id
          )

          expect(project.custom_value_for(invisible_field).typed_value).to eq("foo")
        end
      end

      context "with a non-admin user" do
        current_user { create(:user, global_permissions: %i[add_project]) }

        it "does not show invisible fields in the form and thus not activates the invisible field" do
          expect(page).to have_no_content "Text for Admins only"

          click_on "Save"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          expect(project.project_custom_field_ids).to contain_exactly(
            required_custom_field.id
          )
        end
      end
    end
  end
end
