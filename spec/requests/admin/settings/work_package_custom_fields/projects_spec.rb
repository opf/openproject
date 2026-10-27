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

RSpec.describe "Admin work package custom field projects", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:using_project) { create(:project, name: "Using project", types: [feature, epic]) }
  shared_let(:other_project) { create(:project, name: "Other project", types: [create(:type)]) }

  let(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist, types: [feature, epic], possible_values: %w[A B])
  end
  let(:projects_path) { projects_admin_settings_work_package_custom_field_path(custom_field) }
  let(:page) { Capybara.string(response.body) }
  let(:project_specific_values_filter) do
    { project_specific_values: { operator: "=", values: [custom_field.id.to_s] } }
  end

  it "denies non-admins" do
    login_as create(:user)
    get projects_path

    expect(response).to have_http_status(:forbidden)
  end

  context "as an admin" do
    before do
      login_as(admin)
    end

    context "with project-specific values enabled" do
      before do
        create(:project_specific_value_restriction, project: using_project,
                                                    custom_option: custom_field.custom_options.first)
        get projects_path
      end

      it "lists the projects using the custom field with their types and enabled values" do
        expect(response).to have_http_status(:ok)

        row = page.find("[data-test-selector='custom-field-projects-row-#{using_project.id}']")
        expect(row).to have_link("Feature")
        expect(row).to have_link("Epic")
        expect(row).to have_text("1 of 2")
      end

      it "shows None and All instead of counts when no or all values are enabled" do
        unconfigured_project = create(:project, types: [feature])
        fully_configured_project = create(:project, types: [feature])
        custom_field.custom_options.each do |option|
          create(:project_specific_value_restriction, project: fully_configured_project, custom_option: option)
        end

        get projects_path

        expect(page.find("[data-test-selector='custom-field-projects-row-#{unconfigured_project.id}']"))
          .to have_text(I18n.t("custom_fields.admin.projects.enabled_values.none"))
        expect(page.find("[data-test-selector='custom-field-projects-row-#{fully_configured_project.id}']"))
          .to have_text(I18n.t("custom_fields.admin.projects.enabled_values.all"))
      end

      it "does not list projects not using the custom field" do
        expect(page).to have_no_text("Other project")
      end

      it "filters the projects by name" do
        create(:project, name: "Another using project", types: [feature])

        get projects_path, params: { filters: [{ name_and_identifier: { operator: "~", values: ["another"] } }].to_json }

        expect(page).to have_link("Another using project")
        expect(page).to have_no_link(using_project.name)
      end

      it "offers to only show the projects with project-specific values" do
        expect(page).to have_link(I18n.t("custom_fields.admin.projects.quick_filter.with_project_specific_values"))
      end

      it "filters the projects with project-specific values" do
        create(:project, name: "Unconfigured project", types: [feature])

        get projects_path, params: { filters: [project_specific_values_filter].to_json }

        expect(page).to have_link(using_project.name)
        expect(page).to have_no_link("Unconfigured project")
      end

      context "with more projects than fit a page", with_settings: { per_page_options: "1, 100" } do
        it "keeps the filters when paginating" do
          another_project = create(:project, name: "Another using project", types: [feature])
          create(:project_specific_value_restriction, project: another_project,
                                                      custom_option: custom_field.custom_options.first)
          filters = [{ name_and_identifier: { operator: "~", values: ["using"] } }, project_specific_values_filter]

          get projects_path, params: { filters: filters.to_json }

          next_page = page.first("a[href*='page=2']")[:href]
          next_page_filters = JSON.parse(Rack::Utils.parse_query(URI(next_page).query)["filters"])

          expect(next_page_filters).to include(*filters.map(&:deep_stringify_keys))
        end
      end

      it "shows a dedicated empty state when no project matches the filters" do
        get projects_path,
            params: { filters: [{ name_and_identifier: { operator: "~", values: ["no such project"] } }].to_json }

        expect(page).to have_text(I18n.t("custom_fields.admin.projects.filter_no_results.title"))
        expect(page).to have_no_text(I18n.t("custom_fields.admin.projects.empty_state.title"))
      end

      it "shows the projects tab" do
        expect(page).to have_link(I18n.t(:label_project_plural), href: projects_path)
      end

      it "links each project name to the project" do
        expect(page).to have_link(using_project.name, href: project_path(using_project))
      end

      it "links each project to the configuration of its values" do
        values_path = project_values_admin_settings_work_package_custom_field_path(custom_field, using_project)

        expect(page).to have_link(href: values_path)
      end
    end

    describe "the values of a project" do
      it "lists the values of the custom field for the project" do
        get project_values_admin_settings_work_package_custom_field_path(custom_field, using_project)

        expect(response).to have_http_status(:ok)
        expect(page).to have_text("#{Project.model_name.human}: #{using_project.name}")
        expect(page).to have_css("[data-test-selector='custom-field-project-value-#{custom_field.custom_options.first.id}']")
      end

      it "is not found for a project not using the custom field" do
        get project_values_admin_settings_work_package_custom_field_path(custom_field, other_project)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "changing the values of a project", with_ee: %i[project_specific_list_values] do
      let(:option) { custom_field.custom_options.first }
      let(:enabled_values) { custom_field.usable_values_in(using_project) }
      let(:values_path) { project_values_admin_settings_work_package_custom_field_path(custom_field, using_project) }

      context "when the enterprise plan does not include project-specific values", with_ee: false do
        it "does not change a value" do
          post toggle_project_value_admin_settings_work_package_custom_field_path(custom_field, using_project, option.id),
               params: { value: "1" }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(enabled_values).to be_empty
        end
      end

      it "enables a single value" do
        post toggle_project_value_admin_settings_work_package_custom_field_path(custom_field, using_project, option.id),
             params: { value: "1" }

        expect(response).to have_http_status(:ok)
        expect(enabled_values).to contain_exactly(option)
      end

      it "does not find a value of another custom field" do
        other_option = create(:list_wp_custom_field).custom_options.first
        post toggle_project_value_admin_settings_work_package_custom_field_path(custom_field, using_project, other_option.id),
             params: { value: "1" }

        expect(response).to have_http_status(:not_found)
      end

      it "enables all values" do
        post enable_all_project_values_admin_settings_work_package_custom_field_path(custom_field, using_project)

        expect(response).to redirect_to(values_path)
        expect(enabled_values).to match_array(custom_field.custom_options)
      end

      it "disables all values" do
        create(:project_specific_value_restriction, project: using_project, custom_option: option)
        post disable_all_project_values_admin_settings_work_package_custom_field_path(custom_field, using_project)

        expect(response).to redirect_to(values_path)
        expect(enabled_values).to be_empty
      end
    end

    context "without project-specific values enabled" do
      let(:custom_field) { create(:list_wp_custom_field, types: [feature]) }

      it "lists the projects without their project-specific values" do
        get projects_path

        expect(response).to have_http_status(:ok)
        expect(page).to have_link(using_project.name, href: project_path(using_project))
        expect(page).to have_no_text(CustomField.human_attribute_name(:project_specific_value_restriction))
        expect(page).to have_no_link(
          href: project_values_admin_settings_work_package_custom_field_path(custom_field, using_project)
        )
        expect(page).to have_no_link(I18n.t("custom_fields.admin.projects.quick_filter.with_project_specific_values"))
      end

      it "does not find the values of a project" do
        get project_values_admin_settings_work_package_custom_field_path(custom_field, using_project)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
