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
  let(:project_attributes_page) { Pages::Types::ProjectAttributes.new(type) }

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
    project_attributes_page.visit!
  end

  it "shows all project attributes deactivated by default" do
    expect(page).to have_link("Project attributes")

    project_attributes_page.within_section(input_section) do
      project_attributes_page.within_attribute(boolean_project_custom_field) do
        expect(page).to have_text("Boolean field")
        project_attributes_page.expect_type("Bool")
        project_attributes_page.expect_unchecked_state
      end

      project_attributes_page.within_attribute(string_project_custom_field) do
        expect(page).to have_text("String field")
        project_attributes_page.expect_type("Text")
        project_attributes_page.expect_unchecked_state
      end
    end

    project_attributes_page.within_section(select_section) do
      project_attributes_page.within_attribute(list_project_custom_field) do
        expect(page).to have_text("List field")
        project_attributes_page.expect_type("List")
        project_attributes_page.expect_unchecked_state
      end
    end
  end

  it "toggles a project attribute for the current type" do
    project_attributes_page.within_attribute(boolean_project_custom_field) do
      project_attributes_page.expect_unchecked_state

      project_attributes_page.toggle(boolean_project_custom_field)

      project_attributes_page.expect_checked_state
    end

    project_attributes_page.visit!

    project_attributes_page.within_attribute(boolean_project_custom_field) do
      project_attributes_page.expect_checked_state
    end

    other_type_page = Pages::Types::ProjectAttributes.new(other_type)
    other_type_page.visit!

    other_type_page.within_attribute(boolean_project_custom_field) do
      other_type_page.expect_unchecked_state
    end
  end

  it "enables and disables all project attributes of a section" do
    project_attributes_page.within_section(input_section) do
      page.find_test_selector("enable-all-type-project-attributes-#{input_section.id}").click
    end

    project_attributes_page.within_section(input_section) do
      project_attributes_page.within_attribute(boolean_project_custom_field) do
        project_attributes_page.expect_checked_state
      end

      project_attributes_page.within_attribute(string_project_custom_field) do
        project_attributes_page.expect_checked_state
      end
    end

    project_attributes_page.within_section(select_section) do
      project_attributes_page.within_attribute(list_project_custom_field) do
        project_attributes_page.expect_unchecked_state
      end
    end

    expect(type.reload.project_custom_fields).to contain_exactly(boolean_project_custom_field, string_project_custom_field)

    project_attributes_page.within_section(input_section) do
      page.find_test_selector("disable-all-type-project-attributes-#{input_section.id}").click
    end

    project_attributes_page.within_section(input_section) do
      project_attributes_page.within_attribute(boolean_project_custom_field) do
        project_attributes_page.expect_unchecked_state
      end

      project_attributes_page.within_attribute(string_project_custom_field) do
        project_attributes_page.expect_unchecked_state
      end
    end

    expect(type.reload.project_custom_fields).to be_empty
  end

  it "filters the project attributes by name with given user input" do
    fill_in "border-box-filter", with: "Boolean"

    project_attributes_page.within_section(input_section) do
      expect(page).to have_text("Boolean field")
      expect(page).to have_no_text("String field")
    end

    project_attributes_page.within_section(select_section) do
      expect(page).to have_no_text("List field")
    end
  end

  it "shows sections and project attributes in the configured order" do
    sections = page.all(".op-project-custom-field-section")

    expect(sections.size).to eq(2)
    expect(sections[0].text).to include("Input fields")
    expect(sections[1].text).to include("Select fields")

    project_attributes_page.within_section(input_section) do
      custom_fields = page.all(".op-project-custom-field")

      expect(custom_fields.size).to eq(2)
      expect(custom_fields[0].text).to include("Boolean field")
      expect(custom_fields[1].text).to include("String field")
    end

    input_section.move_to_bottom
    input_section.move_in_order(boolean_project_custom_field.column_name, :lowest)

    project_attributes_page.visit!

    sections = page.all(".op-project-custom-field-section")

    expect(sections.size).to eq(2)
    expect(sections[0].text).to include("Select fields")
    expect(sections[1].text).to include("Input fields")

    project_attributes_page.within_section(input_section) do
      custom_fields = page.all(".op-project-custom-field")

      expect(custom_fields.size).to eq(2)
      expect(custom_fields[0].text).to include("String field")
      expect(custom_fields[1].text).to include("Boolean field")
    end
  end
end
