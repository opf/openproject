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

RSpec.describe "Work package type project attributes", :js do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type, name: "Project order") }
  let(:other_type) { create(:type, name: "Milestone") }

  let!(:input_section) { create(:project_custom_field_section, name: "Input fields") }
  let!(:select_section) { create(:project_custom_field_section, name: "Select fields") }

  let!(:boolean_project_custom_field) do
    create(:boolean_project_custom_field,
           name: "Boolean field",
           project_custom_field_section: input_section)
  end

  let!(:string_project_custom_field) do
    create(:string_project_custom_field,
           name: "String field",
           project_custom_field_section: input_section)
  end

  let!(:list_project_custom_field) do
    create(:list_project_custom_field,
           name: "List field",
           project_custom_field_section: select_section,
           possible_values: ["Option 1", "Option 2"])
  end

  before do
    login_as(admin)
  end

  it "shows all project attributes deactivated by default" do
    visit edit_type_project_attributes_path(type)

    expect(page).to have_link("Project attributes")

    within_project_attribute_section_container(input_section) do
      within_project_attribute_container(boolean_project_custom_field) do
        expect(page).to have_text("Boolean field")
        expect_type("Bool")
        expect_unchecked_state
      end

      within_project_attribute_container(string_project_custom_field) do
        expect(page).to have_text("String field")
        expect_type("Text")
        expect_unchecked_state
      end
    end

    within_project_attribute_section_container(select_section) do
      within_project_attribute_container(list_project_custom_field) do
        expect(page).to have_text("List field")
        expect_type("List")
        expect_unchecked_state
      end
    end
  end

  it "toggles a project attribute for the current type" do
    visit edit_type_project_attributes_path(type)

    within_project_attribute_container(boolean_project_custom_field) do
      expect_unchecked_state

      toggle_type_project_attribute(boolean_project_custom_field)

      expect_checked_state
    end

    visit edit_type_project_attributes_path(type)

    within_project_attribute_container(boolean_project_custom_field) do
      expect_checked_state
    end

    visit edit_type_project_attributes_path(other_type)

    within_project_attribute_container(boolean_project_custom_field) do
      expect_unchecked_state
    end
  end

  it "enables and disables all project attributes of a section" do
    visit edit_type_project_attributes_path(type)

    within_project_attribute_section_container(input_section) do
      page.find_test_selector("enable-all-type-project-attributes-#{input_section.id}").click

      within_project_attribute_container(boolean_project_custom_field) do
        expect_checked_state
      end

      within_project_attribute_container(string_project_custom_field) do
        expect_checked_state
      end
    end

    within_project_attribute_section_container(select_section) do
      within_project_attribute_container(list_project_custom_field) do
        expect_unchecked_state
      end
    end

    expect(type.reload.project_custom_fields).to contain_exactly(boolean_project_custom_field, string_project_custom_field)

    within_project_attribute_section_container(input_section) do
      page.find_test_selector("disable-all-type-project-attributes-#{input_section.id}").click

      within_project_attribute_container(boolean_project_custom_field) do
        expect_unchecked_state
      end

      within_project_attribute_container(string_project_custom_field) do
        expect_unchecked_state
      end
    end

    expect(type.reload.project_custom_fields).to be_empty
  end

  it "filters the project attributes by name with given user input" do
    visit edit_type_project_attributes_path(type)

    fill_in "border-box-filter", with: "Boolean"

    within_project_attribute_section_container(input_section) do
      expect(page).to have_text("Boolean field")
      expect(page).to have_no_text("String field")
    end

    within_project_attribute_section_container(select_section) do
      expect(page).to have_no_text("List field")
    end
  end

  it "shows sections and project attributes in the configured order" do
    visit edit_type_project_attributes_path(type)

    sections = page.all(".op-project-custom-field-section")

    expect(sections.size).to eq(2)
    expect(sections[0].text).to include("Input fields")
    expect(sections[1].text).to include("Select fields")

    within_project_attribute_section_container(input_section) do
      custom_fields = page.all(".op-project-custom-field")

      expect(custom_fields.size).to eq(2)
      expect(custom_fields[0].text).to include("Boolean field")
      expect(custom_fields[1].text).to include("String field")
    end

    input_section.move_to_bottom
    boolean_project_custom_field.move_to_bottom

    visit edit_type_project_attributes_path(type)

    sections = page.all(".op-project-custom-field-section")

    expect(sections.size).to eq(2)
    expect(sections[0].text).to include("Select fields")
    expect(sections[1].text).to include("Input fields")

    within_project_attribute_section_container(input_section) do
      custom_fields = page.all(".op-project-custom-field")

      expect(custom_fields.size).to eq(2)
      expect(custom_fields[0].text).to include("String field")
      expect(custom_fields[1].text).to include("Boolean field")
    end
  end

  def toggle_type_project_attribute(project_custom_field)
    page
      .find("[data-test-selector='toggle-type-project-attribute-#{project_custom_field.id}'] > button")
      .click
  end

  def expect_type(type)
    within "[data-test-selector='custom-field-type']" do
      expect(page).to have_text(type)
    end
  end

  def expect_checked_state
    expect(page).to have_css(".ToggleSwitch-statusOn")
  end

  def expect_unchecked_state
    expect(page).to have_css(".ToggleSwitch-statusOff")
  end

  def within_project_attribute_section_container(section, &)
    within("[data-test-selector='type-project-attribute-section-#{section.id}']", &)
  end

  def within_project_attribute_container(project_custom_field, &)
    within("[data-test-selector='type-project-attribute-#{project_custom_field.id}']", &)
  end
end
