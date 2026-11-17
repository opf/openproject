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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Project settings for the values of a work package custom field",
               :skip_csrf,
               type: :rails_request,
               with_ee: %i[project_specific_list_values custom_field_hierarchies] do
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:project) { create(:project, types: [feature]) }
  shared_let(:other_project) { create(:project, types: [feature]) }

  let(:project_level_value_management) { true }
  let(:allow_additional_project_values) { true }
  let(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist,
           types: [feature], possible_values: %w[A B], project_level_value_management:, allow_additional_project_values:)
  end
  let(:global_option) { custom_field.custom_options.find_by!(value: "A") }
  let(:values_path) { project_settings_work_packages_custom_field_values_path(project, custom_field) }
  let(:value_path) do
    ->(value) { project_settings_work_packages_custom_field_value_path(project, custom_field, value.id) }
  end
  let(:user) do
    create(:user, member_with_permissions: { project => %i[manage_work_package_custom_field_values] })
  end

  before { login_as user }

  it "adds a value to the project" do
    post values_path, params: { label: "Own" }

    expect(response).to redirect_to(values_path)
    expect(custom_field.custom_options.find_by!(value: "Own").project).to eq(project)
  end

  it "renames a value of the project" do
    own_option = create(:custom_option, custom_field:, value: "Own", project:)

    patch value_path.call(own_option), params: { label: "Renamed" }

    expect(response).to redirect_to(values_path)
    expect(own_option.reload.value).to eq("Renamed")
  end

  it "deletes a value of the project" do
    own_option = create(:custom_option, custom_field:, value: "Own", project:)

    delete value_path.call(own_option)

    expect(response).to redirect_to(values_path)
    expect(CustomOption.exists?(own_option.id)).to be(false)
  end

  it "does not find a value of another project" do
    foreign_option = create(:custom_option, custom_field:, value: "Foreign", project: other_project)

    delete value_path.call(foreign_option)

    expect(response).to have_http_status(:not_found)
    expect(CustomOption.exists?(foreign_option.id)).to be(true)
  end

  it "enables a global value in the project" do
    post toggle_project_settings_work_packages_custom_field_value_path(project, custom_field, global_option.id),
         params: { value: "1" }

    expect(response).to have_http_status(:ok)
    expect(custom_field.usable_values_in(project)).to include(global_option)
  end

  it "enables all global values in the project" do
    post enable_all_project_settings_work_packages_custom_field_values_path(project, custom_field)

    expect(response).to redirect_to(values_path)
    expect(custom_field.usable_values_in(project)).to include(*custom_field.custom_options)
  end

  it "does not make a value of the project available to all projects" do
    own_option = create(:custom_option, custom_field:, value: "Own", project:)

    post make_global_project_settings_work_packages_custom_field_value_path(project, custom_field, own_option.id)

    expect(response).to redirect_to(values_path)
    expect(own_option.reload.project).to eq(project)
  end

  context "for a hierarchy custom field" do
    let(:custom_field) do
      create(:hierarchy_wp_custom_field, :project_specific_allowlist,
             types: [feature], project_level_value_management:, allow_additional_project_values:)
    end
    let!(:global_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Global") }

    it "adds a sub-value to the project" do
      post values_path, params: { label: "Own", parent_id: global_item.id }

      expect(response).to redirect_to(values_path)
      expect(global_item.children.find_by!(label: "Own").project).to eq(project)
    end

    it "deletes a value of the project" do
      own_item = create(:hierarchy_item, parent: global_item, label: "Own", project:)

      delete value_path.call(own_item)

      expect(response).to redirect_to(values_path)
      expect(CustomField::Hierarchy::Item.exists?(own_item.id)).to be(false)
    end
  end

  context "when project admins may only manage the global values" do
    let(:allow_additional_project_values) { false }

    it "does not add a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to have_http_status(:not_found)
    end

    it "enables a global value in the project" do
      post toggle_project_settings_work_packages_custom_field_value_path(project, custom_field, global_option.id),
           params: { value: "1" }

      expect(response).to have_http_status(:ok)
    end
  end

  context "when project admins may only add values" do
    let(:project_level_value_management) { false }

    it "adds a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to redirect_to(values_path)
    end

    it "does not enable a global value in the project" do
      post toggle_project_settings_work_packages_custom_field_value_path(project, custom_field, global_option.id),
           params: { value: "1" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(custom_field.usable_values_in(project)).not_to include(global_option)
    end
  end

  context "when project admins may not manage the values" do
    let(:project_level_value_management) { false }
    let(:allow_additional_project_values) { false }

    it "is not found" do
      post enable_all_project_settings_work_packages_custom_field_values_path(project, custom_field)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "for a custom field the project does not use" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist,
             possible_values: %w[A], project_level_value_management:, allow_additional_project_values:)
    end

    it "is not found" do
      post values_path, params: { label: "Own" }

      expect(response).to have_http_status(:not_found)
    end
  end

  context "without the permission to manage custom field values" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "is forbidden" do
      post values_path, params: { label: "Own" }

      expect(response).to have_http_status(:forbidden)
      expect(custom_field.custom_options.where(project:)).to be_empty
    end
  end
end
