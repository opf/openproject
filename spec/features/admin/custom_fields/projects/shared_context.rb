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

RSpec.shared_context "with seeded project custom fields" do
  using CustomFieldFormulaReferencing

  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }

  shared_let(:section_for_input_fields, refind: true) do
    create(:project_custom_field_section, name: "Input fields")
  end
  shared_let(:section_for_select_fields, refind: true) do
    create(:project_custom_field_section, name: "Select fields")
  end
  shared_let(:section_for_multi_select_fields, refind: true) do
    create(:project_custom_field_section, name: "Multi select fields")
  end

  shared_let(:boolean_project_custom_field, refind: true) do
    create(:boolean_project_custom_field, name: "Boolean field",
                                          project_custom_field_section: section_for_input_fields)
  end

  shared_let(:string_project_custom_field, refind: true) do
    create(:string_project_custom_field, name: "String field",
                                         project_custom_field_section: section_for_input_fields)
  end

  shared_let(:integer_project_custom_field, refind: true) do
    create(:integer_project_custom_field, name: "Integer field",
                                          project_custom_field_section: section_for_input_fields)
  end

  shared_let(:float_project_custom_field, refind: true) do
    create(:float_project_custom_field, name: "Float field",
                                        project_custom_field_section: section_for_input_fields)
  end

  shared_let(:date_project_custom_field, refind: true) do
    create(:date_project_custom_field,  name: "Date field",
                                        project_custom_field_section: section_for_input_fields)
  end

  shared_let(:text_project_custom_field, refind: true) do
    create(:text_project_custom_field,  name: "Text field",
                                        project_custom_field_section: section_for_input_fields)
  end

  shared_let(:calculated_from_int_project_custom_field, refind: true) do
    create(
      :calculated_value_project_custom_field,
      :skip_validations,
      name: "Calculated field using int",
      formula: "#{integer_project_custom_field} * 2",
      project_custom_field_section: section_for_input_fields
    )
  end

  shared_let(:calculated_from_int_and_float_project_custom_field, refind: true) do
    create(
      :calculated_value_project_custom_field,
      :skip_validations,
      name: "Calculated field using int and float",
      formula: "#{float_project_custom_field} * #{integer_project_custom_field}",
      project_custom_field_section: section_for_input_fields
    )
  end

  shared_let(:list_project_custom_field, refind: true) do
    create(:list_project_custom_field, name: "List field",
                                       project_custom_field_section: section_for_select_fields,
                                       possible_values: ["Option 1", "Option 2", "Option 3"])
  end

  shared_let(:version_project_custom_field, refind: true) do
    create(:version_project_custom_field, name: "Version field",
                                          project_custom_field_section: section_for_select_fields)
  end

  shared_let(:user_project_custom_field, refind: true) do
    create(:user_project_custom_field, name: "User field",
                                       project_custom_field_section: section_for_select_fields)
  end

  shared_let(:multi_list_project_custom_field, refind: true) do
    create(:multi_list_project_custom_field, name: "Multi list field",
                                             project_custom_field_section: section_for_multi_select_fields,
                                             possible_values: ["Option 1", "Option 2", "Option 3"])
  end

  shared_let(:multi_version_project_custom_field, refind: true) do
    create(:multi_version_project_custom_field, name: "Multi version field",
                                                project_custom_field_section: section_for_multi_select_fields)
  end

  shared_let(:multi_user_project_custom_field, refind: true) do
    create(:multi_user_project_custom_field, name: "Multi user field",
                                             project_custom_field_section: section_for_multi_select_fields)
  end

  let(:input_fields) do
    [
      boolean_project_custom_field,
      string_project_custom_field,
      integer_project_custom_field,
      float_project_custom_field,
      date_project_custom_field,
      text_project_custom_field
    ]
  end

  let(:select_fields) do
    [
      list_project_custom_field,
      version_project_custom_field,
      user_project_custom_field
    ]
  end

  let(:multi_select_fields) do
    [
      multi_list_project_custom_field,
      multi_version_project_custom_field,
      multi_user_project_custom_field
    ]
  end
end

RSpec.shared_examples "prevents access on insufficient permissions" do
  current_user { non_admin }

  before do
    visit edit_admin_settings_project_custom_field_path(custom_field)
  end

  it "is not accessible" do
    expect(page).to have_text("You are not authorized to access this page.")
  end
end

RSpec.shared_examples "has breadcrumb and tabs" do
  current_user { admin }

  before do
    visit edit_admin_settings_project_custom_field_path(custom_field)
  end

  it "shows a correct breadcrumb menu" do
    within ".PageHeader-breadcrumbs" do
      expect(page).to have_link("Administration")
      expect(page).to have_link("Projects")
      expect(page).to have_link("Project attributes")
      expect(page).to have_text(custom_field.name)
    end
  end

  it "shows tab navigation" do
    within_test_selector("project_attribute_detail_header") do
      expect(page).to have_link("Details")
      expect(page).to have_link("Projects")
    end
  end
end

RSpec.shared_examples "shows checkboxes for configuration" do
  current_user { admin }

  let(:required_supported) do
    super()
  rescue NoMethodError
    true
  end

  before do
    visit edit_admin_settings_project_custom_field_path(custom_field)
  end

  it "shows checkboxes for 'Required', 'Admin-only' and 'For all projects' attributes" do
    if required_supported
      expect(page).to have_unchecked_field("Required")

      check("Required")
    else
      expect(page).to have_no_field("Required")
    end

    expect(page).to have_unchecked_field("Admin-only")
    check("Admin-only")

    expect(page).to have_unchecked_field("For all projects")
    check("For all projects")

    click_on("Save")

    expect(page).to have_text("Successful update")

    custom_field.reload
    expect(custom_field.is_required).to eq required_supported
    expect(custom_field.admin_only).to be_truthy
    expect(custom_field.is_for_all).to be_truthy
  end
end

RSpec.shared_examples "editing the field" do
  current_user { admin }

  before do
    visit edit_admin_settings_project_custom_field_path(custom_field)
  end

  it "allows to change name and the section of the project custom field" do
    # TODO: reuse specs for classic custom field form in order to test for other attribute manipulations
    expect(page).to have_css(".PageHeader-title", text: custom_field.name)

    fill_in("Name", with: "Updated name", fill_options: { clear: :backspace })
    select(section_for_select_fields.name, from: "custom_field_custom_field_section_id")

    click_on("Save")

    expect(page).to have_text("Successful update")

    expect(page).to have_css(".PageHeader-title", text: "Updated name")

    expect(custom_field.reload.name).to eq("Updated name")
    expect(custom_field.reload.project_custom_field_section).to eq(section_for_select_fields)

    within ".PageHeader-breadcrumbs" do
      expect(page).to have_link("Administration")
      expect(page).to have_link("Projects")
      expect(page).to have_link("Project attributes")
      expect(page).to have_text("Updated name")
    end
  end

  it "prevents saving a project custom field with an empty name" do
    original_name = custom_field.name

    fill_in("Name", with: "")
    click_on("Save")

    expect(page).to have_field("custom_field_name", with: "", validation_error: "Name can't be blank")

    expect(page).to have_no_text("Successful update")

    expect(page).to have_css(".PageHeader-title", text: original_name)
    expect(custom_field.reload.name).to eq(original_name)
  end
end
