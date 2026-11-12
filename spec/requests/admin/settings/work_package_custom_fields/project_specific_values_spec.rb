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

RSpec.describe "Admin project-specific values of a work package custom field", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:using_project) { create(:project, name: "Using project", types: [feature]) }
  shared_let(:other_project) { create(:project, name: "Other project", types: [create(:type)]) }

  let(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist, types: [feature], possible_values: %w[A B])
  end
  let(:values_path) { admin_settings_work_package_custom_field_project_specific_values_path(custom_field, using_project) }
  let(:toggle_path) do
    lambda do |value|
      toggle_admin_settings_work_package_custom_field_project_specific_value_path(custom_field, using_project, value.id)
    end
  end
  let(:enable_all_path) do
    enable_all_admin_settings_work_package_custom_field_project_specific_values_path(custom_field, using_project)
  end
  let(:disable_all_path) do
    disable_all_admin_settings_work_package_custom_field_project_specific_values_path(custom_field, using_project)
  end
  let(:destroy_path) do
    ->(value) { admin_settings_work_package_custom_field_project_specific_value_path(custom_field, using_project, value.id) }
  end
  let(:deletion_dialog_path) do
    lambda do |value|
      deletion_dialog_admin_settings_work_package_custom_field_project_specific_value_path(custom_field, using_project,
                                                                                           value.id)
    end
  end
  let(:page) { Capybara.string(response.body) }

  it "denies non-admins" do
    login_as create(:user)
    get values_path

    expect(response).to have_http_status(:forbidden)
  end

  context "as an admin" do
    before do
      login_as(admin)
    end

    describe "the values of a project" do
      it "lists the values of the custom field for the project" do
        get values_path

        expect(response).to have_http_status(:ok)
        expect(page).to have_text("#{Project.model_name.human}: #{using_project.name}")
        expect(page).to have_css("[data-test-selector='custom-field-project-value-#{custom_field.custom_options.first.id}']")
      end

      context "when values are deactivated for each project" do
        let(:custom_field) do
          create(:list_wp_custom_field, :project_specific_blocklist, types: [feature], possible_values: %w[A B])
        end

        it "lists all values as enabled while none is deactivated" do
          get values_path

          expect(page).to have_css("[data-test-selector^='custom-field-project-value-'] button[aria-pressed='true']",
                                   count: 2)
        end
      end

      it "is not found for a project not using the custom field" do
        get admin_settings_work_package_custom_field_project_specific_values_path(custom_field, other_project)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "changing the values of a project", with_ee: %i[project_specific_list_values] do
      let(:option) { custom_field.custom_options.first }
      let(:enabled_values) { custom_field.usable_values_in(using_project) }

      context "when the enterprise plan does not include project-specific values", with_ee: false do
        it "does not change a value" do
          post toggle_path.call(option), params: { value: "1" }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(enabled_values).to be_empty
        end
      end

      it "enables a single value" do
        post toggle_path.call(option), params: { value: "1" }

        expect(response).to have_http_status(:ok)
        expect(enabled_values).to contain_exactly(option)
      end

      it "does not find a value of another custom field" do
        post toggle_path.call(create(:list_wp_custom_field).custom_options.first), params: { value: "1" }

        expect(response).to have_http_status(:not_found)
      end

      it "enables all values" do
        post enable_all_path

        expect(response).to redirect_to(values_path)
        expect(enabled_values).to match_array(custom_field.custom_options)
      end

      it "disables all values" do
        create(:project_specific_value_restriction, project: using_project, custom_option: option)
        post disable_all_path

        expect(response).to redirect_to(values_path)
        expect(enabled_values).to be_empty
      end
    end

    describe "adding a value to a project" do
      let(:new_path) { new_admin_settings_work_package_custom_field_project_specific_value_path(custom_field, using_project) }

      context "for a list custom field" do
        let(:custom_field) do
          create(:list_wp_custom_field, types: [feature], possible_values: %w[A], allow_additional_project_values: true)
        end

        it "asks for the value in a dialog" do
          get new_path, as: :turbo_stream

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("custom-field-project-value-new-dialog")
        end

        it "adds the value to the project" do
          post values_path, params: { label: "Own" }

          expect(response).to redirect_to(values_path)
          expect(custom_field.custom_options.find_by!(value: "Own").project).to eq(using_project)
        end

        it "shows the errors in the dialog" do
          post values_path, params: { label: "" }, as: :turbo_stream

          expect(response).to have_http_status(:unprocessable_entity)
          expect(custom_field.custom_options.where(project: using_project)).to be_empty
        end
      end

      context "for a hierarchy custom field", with_ee: %i[custom_field_hierarchies] do
        let(:custom_field) do
          create(:hierarchy_wp_custom_field, types: [feature], allow_additional_project_values: true)
        end
        let!(:global_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Global") }

        it "adds a sub-value to the project" do
          post values_path, params: { label: "Own", short: "OW", parent_id: global_item.id }

          expect(response).to redirect_to(values_path)
          expect(global_item.children.find_by!(label: "Own")).to have_attributes(project: using_project, short: "OW")
        end

        it "adds a top level value to the project" do
          post values_path, params: { label: "Own", parent_id: custom_field.hierarchy_root.id }

          expect(response).to redirect_to(values_path)
          expect(custom_field.hierarchy_root.children.find_by!(label: "Own").project).to eq(using_project)
        end

        it "does not find a value of another project as parent" do
          foreign_item = create(:hierarchy_item, parent: global_item, label: "Foreign", project: other_project)

          get new_path, params: { parent_id: foreign_item.id }, as: :turbo_stream

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when projects may not add values" do
        it "is not found" do
          get new_path, as: :turbo_stream

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "making a value of a project available to all projects" do
      let(:custom_field) do
        create(:list_wp_custom_field, types: [feature], possible_values: %w[A], allow_additional_project_values: true)
      end
      let(:make_global_path) do
        lambda do |value|
          make_global_admin_settings_work_package_custom_field_project_specific_value_path(custom_field, using_project,
                                                                                           value.id)
        end
      end

      it "makes the value global" do
        own_option = custom_field.custom_options.create!(value: "Own", project: using_project)

        post make_global_path.call(own_option)

        expect(response).to redirect_to(values_path)
        expect(own_option.reload.project_id).to be_nil
      end

      it "shows the error when the value cannot be made global" do
        own_option = custom_field.custom_options.create!(value: "Own", project: using_project)
        custom_field.custom_options.create!(value: "Own", project: other_project)

        post make_global_path.call(own_option)

        expect(response).to redirect_to(values_path)
        expect(flash[:error]).to be_present
        expect(own_option.reload.project).to eq(using_project)
      end

      it "does not find a global value" do
        post make_global_path.call(custom_field.custom_options.find_by!(value: "A"))

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "deleting a value of a project" do
      context "for a list custom field" do
        let(:custom_field) do
          create(:list_wp_custom_field, types: [feature], possible_values: %w[A], allow_additional_project_values: true)
        end
        let!(:own_option) { custom_field.custom_options.create!(value: "Own", project: using_project) }
        let!(:custom_value) do
          create(:work_package_custom_value, custom_field:, value: own_option.id,
                                             customized: create(:work_package, project: using_project, type: feature))
        end

        it "asks for confirmation in a dialog" do
          get deletion_dialog_path.call(own_option), as: :turbo_stream

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("custom-field-project-value-delete-dialog")
        end

        it "does not offer to delete a global value" do
          get deletion_dialog_path.call(custom_field.custom_options.find_by!(value: "A")), as: :turbo_stream

          expect(response).to have_http_status(:not_found)
        end

        it "deletes the value with its assignments" do
          delete destroy_path.call(own_option)

          expect(response).to redirect_to(values_path)
          expect(CustomOption.exists?(own_option.id)).to be(false)
          expect(CustomValue.exists?(custom_value.id)).to be(false)
        end

        it "does not find a global value" do
          delete destroy_path.call(custom_field.custom_options.find_by!(value: "A"))

          expect(response).to have_http_status(:not_found)
        end

        it "does not find a value of another project" do
          foreign_option = create(:custom_option, custom_field:, value: "Foreign", project: other_project)

          delete destroy_path.call(foreign_option)

          expect(response).to have_http_status(:not_found)
          expect(CustomOption.exists?(foreign_option.id)).to be(true)
        end
      end

      context "for a hierarchy custom field", with_ee: %i[custom_field_hierarchies] do
        let(:custom_field) do
          create(:hierarchy_wp_custom_field, types: [feature], allow_additional_project_values: true)
        end
        let!(:global_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Global") }
        let!(:own_item) { create(:hierarchy_item, parent: global_item, label: "Own", project: using_project) }
        let!(:own_sub_item) { create(:hierarchy_item, parent: own_item, label: "Own sub", project: using_project) }

        it "deletes the value with its sub-values" do
          delete destroy_path.call(own_item)

          expect(response).to redirect_to(values_path)
          expect(CustomField::Hierarchy::Item.where(id: [own_item.id, own_sub_item.id])).to be_empty
          expect(CustomField::Hierarchy::Item.exists?(global_item.id)).to be(true)
        end
      end
    end

    context "without project-specific values enabled" do
      let(:custom_field) { create(:list_wp_custom_field, types: [feature]) }

      it "does not find the values of a project" do
        get values_path

        expect(response).to have_http_status(:not_found)
      end

      it "does not delete a value of the project" do
        option = create(:custom_option, custom_field:, value: "Own", project: using_project)

        delete destroy_path.call(option)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with only additional project values allowed" do
      let(:custom_field) { create(:list_wp_custom_field, types: [feature], allow_additional_project_values: true) }

      it "shows the values of a project" do
        get values_path

        expect(response).to have_http_status(:ok)
      end

      it "does not change the values of a project", with_ee: %i[project_specific_list_values] do
        post enable_all_path

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
