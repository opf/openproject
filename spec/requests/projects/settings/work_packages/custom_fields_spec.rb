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

RSpec.describe "Project settings for work package custom fields", type: :rails_request do
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:project) { create(:project, types: [feature]) }
  shared_let(:department) { create(:list_wp_custom_field, name: "Department", types: [feature]) }
  shared_let(:sku) { create(:integer_wp_custom_field, name: "SKU", types: [feature]) }

  let(:page) { Capybara.string(response.body) }

  before { login_as user }

  context "with the permission to manage custom field values" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[manage_work_package_custom_field_values] })
    end

    it "shows the custom fields" do
      get project_settings_work_packages_custom_fields_path(project)

      expect(response).to have_http_status(:ok)
      expect(page).to have_link(I18n.t(:label_custom_field_plural),
                                href: project_settings_work_packages_custom_fields_path(project))
      expect(page).to have_no_link(I18n.t(:label_type_plural), href: project_settings_work_packages_types_path(project))
      expect(page).to have_no_link(href: project_settings_work_packages_internal_comments_path(project))
    end

    it "offers to search and filter the custom fields" do
      get project_settings_work_packages_custom_fields_path(project)

      sub_header = find_test_selector("project-custom-fields-sub-header")
      expect(sub_header).to have_field(I18n.t("projects.settings.custom_fields.search_label"))
      expect(sub_header).to have_button(WorkPackageCustomField.human_attribute_name(:field_format))
      expect(sub_header).to have_button(I18n.t("projects.settings.custom_fields.values_filter"))
      expect(sub_header).to have_test_selector("filter-component-toggle")
    end

    it "lists only the custom fields matching the filters" do
      filters = [{ field_format: { operator: "=", values: ["list"] } }].to_json

      get project_settings_work_packages_custom_fields_path(project, filters:)

      expect(page).to have_test_selector("project-custom-field-#{department.id}")
      expect(page).to have_no_test_selector("project-custom-field-#{sku.id}")
    end

    it "updates the custom fields via turbo stream" do
      filters = [{ name: { operator: "~", values: ["sku"] } }].to_json

      get project_settings_work_packages_custom_fields_path(project, filters:, format: :turbo_stream)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("project-custom-field-#{sku.id}")
      expect(response.body).not_to include("project-custom-field-#{department.id}")
    end

    it "leads from the work package settings to the custom fields" do
      get project_settings_work_packages_path(project)

      expect(response).to redirect_to(project_settings_work_packages_custom_fields_path(project))
    end

    it "lists the work package settings in the project settings menu" do
      get project_settings_work_packages_custom_fields_path(project)

      expect(page).to have_link(I18n.t(:label_work_package_plural), href: project_settings_work_packages_url(project))
    end
  end

  context "without the permission to manage custom field values" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "is forbidden" do
      get project_settings_work_packages_custom_fields_path(project)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
