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
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }

  shared_let(:section_for_input_fields) { create(:project_custom_field_section, name: "Input fields") }
  shared_let(:section_for_select_fields) { create(:project_custom_field_section, name: "Select fields") }
  shared_let(:section_for_multi_select_fields) { create(:project_custom_field_section, name: "Multi select fields") }

  let!(:boolean_project_custom_field) do
    create(:boolean_project_custom_field, name: "Boolean field",
                                          project_custom_field_section: section_for_input_fields)
  end

  let!(:string_project_custom_field) do
    create(:string_project_custom_field, name: "String field",
                                         project_custom_field_section: section_for_input_fields)
  end

  let!(:integer_project_custom_field) do
    create(:integer_project_custom_field, name: "Integer field",
                                          project_custom_field_section: section_for_input_fields)
  end

  let!(:float_project_custom_field) do
    create(:float_project_custom_field, name: "Float field",
                                        project_custom_field_section: section_for_input_fields)
  end

  let!(:date_project_custom_field) do
    create(:date_project_custom_field,  name: "Date field",
                                        project_custom_field_section: section_for_input_fields)
  end

  let!(:text_project_custom_field) do
    create(:text_project_custom_field,  name: "Text field",
                                        project_custom_field_section: section_for_input_fields)
  end

  let!(:list_project_custom_field) do
    create(:list_project_custom_field,  name: "List field",
                                        project_custom_field_section: section_for_select_fields,
                                        possible_values: ["Option 1", "Option 2", "Option 3"])
  end

  let!(:version_project_custom_field) do
    create(:version_project_custom_field, name: "Version field",
                                          project_custom_field_section: section_for_select_fields)
  end

  let!(:user_project_custom_field) do
    create(:user_project_custom_field,  name: "User field",
                                        project_custom_field_section: section_for_select_fields)
  end

  let!(:multi_list_project_custom_field) do
    create(:list_project_custom_field,  name: "Multi list field",
                                        project_custom_field_section: section_for_multi_select_fields,
                                        possible_values: ["Option 1", "Option 2", "Option 3"],
                                        multi_value: true)
  end

  let!(:multi_version_project_custom_field) do
    create(:version_project_custom_field, name: "Multi version field",
                                          project_custom_field_section: section_for_multi_select_fields,
                                          multi_value: true)
  end

  let!(:multi_user_project_custom_field) do
    create(:user_project_custom_field, name: "Multi user field",
                                       project_custom_field_section: section_for_multi_select_fields,
                                       multi_value: true)
  end

  let!(:input_fields) do
    [
      boolean_project_custom_field,
      string_project_custom_field,
      integer_project_custom_field,
      float_project_custom_field,
      date_project_custom_field,
      text_project_custom_field
    ]
  end

  let!(:select_fields) do
    [
      list_project_custom_field,
      version_project_custom_field,
      user_project_custom_field
    ]
  end

  let!(:multi_select_fields) do
    [
      multi_list_project_custom_field,
      multi_version_project_custom_field,
      multi_user_project_custom_field
    ]
  end
end
