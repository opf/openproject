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
  let(:own_option) { create(:custom_option, custom_field:, value: "Own", project:) }

  let(:values_path) { project_settings_work_packages_custom_field_values_path(project, custom_field) }
  let(:new_value_path) { new_project_settings_work_packages_custom_field_value_path(project, custom_field) }
  let(:value_path) do
    ->(value) { project_settings_work_packages_custom_field_value_path(project, custom_field, value.id) }
  end
  let(:edit_value_path) do
    ->(value) { edit_project_settings_work_packages_custom_field_value_path(project, custom_field, value.id) }
  end
  let(:deletion_dialog_path) do
    ->(value) { deletion_dialog_project_settings_work_packages_custom_field_value_path(project, custom_field, value.id) }
  end
  let(:toggle_path) do
    ->(value) { toggle_project_settings_work_packages_custom_field_value_path(project, custom_field, value.id) }
  end
  let(:make_global_path) do
    ->(value) { make_global_project_settings_work_packages_custom_field_value_path(project, custom_field, value.id) }
  end
  let(:enable_all_path) { enable_all_project_settings_work_packages_custom_field_values_path(project, custom_field) }
  let(:disable_all_path) { disable_all_project_settings_work_packages_custom_field_values_path(project, custom_field) }

  let(:user) do
    create(:user, member_with_permissions: { project => %i[manage_work_package_custom_field_values] })
  end

  before { login_as user }

  context "when project admins may manage and add values" do
    it "shows the values of the custom field in the project" do
      get values_path

      expect(response).to have_http_status(:ok)
      expect(page).to have_link(I18n.t(:label_custom_field_plural),
                                href: project_settings_work_packages_custom_fields_path(project.id))
      expect(page).to have_text(
        I18n.t("projects.settings.custom_fields.values_description", custom_field: custom_field.name, project: project.name)
      )
      expect(page).to have_test_selector("custom-field-project-value-#{global_option.id}")
    end

    it "asks for a new value in a dialog" do
      get new_value_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("custom-field-project-value-dialog")
    end

    it "adds a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to redirect_to(values_path)
      expect(custom_field.custom_options.find_by!(value: "Own").project).to eq(project)
    end

    it "edits a value of the project in a dialog" do
      get edit_value_path.call(own_option), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("custom-field-project-value-dialog")
    end

    it "renames a value of the project" do
      patch value_path.call(own_option), params: { label: "Renamed" }

      expect(response).to redirect_to(values_path)
      expect(own_option.reload.value).to eq("Renamed")
    end

    it "asks for confirmation before deleting a value of the project" do
      get deletion_dialog_path.call(own_option), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("custom-field-project-value-delete-dialog")
    end

    it "deletes a value of the project" do
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
      post toggle_path.call(global_option), params: { value: "1" }

      expect(response).to have_http_status(:ok)
      expect(custom_field.usable_values_in(project)).to include(global_option)
    end

    it "enables all global values in the project" do
      post enable_all_path

      expect(response).to redirect_to(values_path)
      expect(custom_field.usable_values_in(project)).to include(*custom_field.custom_options)
    end

    it "disables all global values in the project" do
      create(:project_specific_value_restriction, project:, custom_option: global_option)

      post disable_all_path

      expect(response).to redirect_to(values_path)
      expect(custom_field.usable_values_in(project)).not_to include(global_option)
    end

    it "does not make a value of the project available to all projects" do
      post make_global_path.call(own_option)

      expect(response).to redirect_to(values_path)
      expect(flash[:error]).to be_present
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

      it "does not find a value of another project as parent" do
        foreign_item = create(:hierarchy_item, parent: global_item, label: "Foreign", project: other_project)

        get new_value_path, params: { parent_id: foreign_item.id }, as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end

      it "deletes a value of the project" do
        own_item = create(:hierarchy_item, parent: global_item, label: "Own", project:)

        delete value_path.call(own_item)

        expect(response).to redirect_to(values_path)
        expect(CustomField::Hierarchy::Item.exists?(own_item.id)).to be(false)
      end
    end
  end

  context "when project admins may only manage the global values" do
    let(:allow_additional_project_values) { false }

    it "shows the values of the custom field in the project" do
      get values_path

      expect(response).to have_http_status(:ok)
    end

    it "does not ask for a new value" do
      get new_value_path, as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "does not add a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to have_http_status(:not_found)
      expect(custom_field.custom_options.where(project:)).to be_empty
    end

    it "does not edit a value the project added before" do
      get edit_value_path.call(own_option), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "does not rename a value the project added before" do
      patch value_path.call(own_option), params: { label: "Renamed" }

      expect(response).to have_http_status(:not_found)
      expect(own_option.reload.value).to eq("Own")
    end

    it "deletes a value the project added before" do
      delete value_path.call(own_option)

      expect(response).to redirect_to(values_path)
      expect(CustomOption.exists?(own_option.id)).to be(false)
    end

    it "enables a global value in the project" do
      post toggle_path.call(global_option), params: { value: "1" }

      expect(response).to have_http_status(:ok)
      expect(custom_field.usable_values_in(project)).to include(global_option)
    end

    it "enables all global values in the project" do
      post enable_all_path

      expect(response).to redirect_to(values_path)
      expect(custom_field.usable_values_in(project)).to include(*custom_field.custom_options)
    end
  end

  context "when project admins may only add values" do
    let(:project_level_value_management) { false }

    it "adds a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to redirect_to(values_path)
      expect(custom_field.custom_options.find_by!(value: "Own").project).to eq(project)
    end

    it "does not enable a global value in the project" do
      post toggle_path.call(global_option), params: { value: "1" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(custom_field.usable_values_in(project)).not_to include(global_option)
    end

    it "does not enable all global values in the project" do
      post enable_all_path

      expect(response).to redirect_to(values_path)
      expect(flash[:error]).to be_present
      expect(custom_field.usable_values_in(project)).not_to include(global_option)
    end

    it "does not disable all global values in the project" do
      create(:project_specific_value_restriction, project:, custom_option: global_option)

      post disable_all_path

      expect(response).to redirect_to(values_path)
      expect(flash[:error]).to be_present
      expect(custom_field.usable_values_in(project)).to include(global_option)
    end

    context "for a hierarchy custom field" do
      let(:custom_field) do
        create(:hierarchy_wp_custom_field, :project_specific_allowlist,
               types: [feature], project_level_value_management:, allow_additional_project_values:)
      end
      let!(:enabled_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Enabled") }
      let!(:disabled_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Disabled") }

      before do
        create(:project_specific_value_restriction, project:, hierarchy_item: enabled_item, restriction: "allow")
      end

      it "adds a sub-value below a value enabled in the project" do
        post values_path, params: { label: "Own", parent_id: enabled_item.id }

        expect(response).to redirect_to(values_path)
        expect(enabled_item.children.find_by!(label: "Own").project).to eq(project)
      end

      it "does not add a sub-value below a value disabled in the project" do
        post values_path, params: { label: "Own", parent_id: disabled_item.id }

        expect(response).to have_http_status(:not_found)
        expect(disabled_item.children).to be_empty
      end

      it "adds a top level value" do
        post values_path, params: { label: "Own", parent_id: custom_field.hierarchy_root.id }

        expect(response).to redirect_to(values_path)
        expect(custom_field.hierarchy_root.children.find_by!(label: "Own").project).to eq(project)
      end
    end
  end

  context "when project admins may not manage the values" do
    let(:project_level_value_management) { false }
    let(:allow_additional_project_values) { false }

    it "shows the values of the custom field in the project" do
      get values_path

      expect(response).to have_http_status(:ok)
    end

    it "does not add a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to have_http_status(:not_found)
    end

    it "does not enable all global values in the project" do
      post enable_all_path

      expect(response).to redirect_to(values_path)
      expect(flash[:error]).to be_present
      expect(custom_field.usable_values_in(project)).not_to include(global_option)
    end

    it "deletes a value the project added before" do
      delete value_path.call(own_option)

      expect(response).to redirect_to(values_path)
      expect(CustomOption.exists?(own_option.id)).to be(false)
    end
  end

  context "when the values are neither restricted per project nor may be added" do
    let(:custom_field) { create(:list_wp_custom_field, types: [feature], possible_values: %w[A B]) }

    it "shows the values of the custom field in the project" do
      get values_path

      expect(response).to have_http_status(:ok)
    end
  end

  context "for a custom field without values" do
    let(:custom_field) { create(:integer_wp_custom_field, types: [feature]) }

    it "is not found" do
      get values_path

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the values are not restricted per project" do
    let(:custom_field) do
      create(:list_wp_custom_field, types: [feature], possible_values: %w[A B], allow_additional_project_values: true)
    end

    it "shows the values of the custom field in the project" do
      get values_path

      expect(response).to have_http_status(:ok)
    end

    it "adds a value to the project" do
      post values_path, params: { label: "Own" }

      expect(response).to redirect_to(values_path)
      expect(custom_field.custom_options.find_by!(value: "Own").project).to eq(project)
    end

    it "does not enable or disable a global value" do
      post toggle_path.call(global_option), params: { value: "1" }

      expect(response).to have_http_status(:not_found)
    end

    it "does not enable all global values" do
      post enable_all_path

      expect(response).to have_http_status(:not_found)
    end
  end

  context "without the enterprise plan", with_ee: [] do
    it "does not add a value to the project" do
      post values_path, params: { label: "Own" }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(custom_field.custom_options.where(project:)).to be_empty
    end

    it "does not rename a value the project added before" do
      patch value_path.call(own_option), params: { label: "Renamed" }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(own_option.reload.value).to eq("Own")
    end

    it "deletes a value the project added before" do
      delete value_path.call(own_option)

      expect(response).to redirect_to(values_path)
      expect(CustomOption.exists?(own_option.id)).to be(false)
    end

    it "does not enable a global value in the project" do
      post toggle_path.call(global_option), params: { value: "1" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(custom_field.usable_values_in(project)).not_to include(global_option)
    end
  end

  context "as a global admin" do
    let(:user) { create(:admin) }

    it "makes a value of the project available to all projects" do
      post make_global_path.call(own_option)

      expect(response).to redirect_to(values_path)
      expect(own_option.reload.project_id).to be_nil
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
