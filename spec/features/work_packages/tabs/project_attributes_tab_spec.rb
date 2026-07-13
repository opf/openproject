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

RSpec.describe "Work package project attributes tab", :js do
  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type) }
  shared_let(:section) { create(:project_custom_field_section, name: "Details") }
  shared_let(:string_field) do
    create(:string_project_custom_field,
           name: "Project info",
           project_custom_field_section: section,
           projects: [project]) do |field|
      type.project_custom_fields << field
      create(:custom_value, customized: project, custom_field: field, value: "Initial value")
    end
  end

  shared_let(:edit_role) do
    create(:project_role, permissions: %i[view_work_packages view_project_attributes edit_project_attributes edit_project])
  end
  shared_let(:edit_project_attributes_only_role) do
    create(:project_role, permissions: %i[view_work_packages view_project_attributes edit_project_attributes])
  end
  shared_let(:view_role) do
    create(:project_role, permissions: %i[view_work_packages view_project_attributes])
  end

  let(:work_package) { create(:work_package, project:, type:) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:inplace_field) { Components::Common::InplaceEditField.new(project, string_field.attribute_name.to_sym) }
  let(:input_field) { FormFields::Primerized::InputField.new(string_field) }

  context "as a user with view and edit permissions" do
    let(:user) { create(:user, member_with_roles: { project => edit_role }) }

    before do
      login_as user
      wp_page.visit_tab! "activity"
      expect_angular_frontend_initialized
      wait_for_turbo_frame { click_on I18n.t("js.work_packages.tabs.project_attributes") }
    end

    it "displays the section and field" do
      expect(page).to have_test_selector("wp-project-attribute-section-#{section.id}")
      expect(page).to have_test_selector("wp-project-attribute-#{string_field.id}")
    end

    it "allows editing a string field" do
      wait_for_turbo_stream { inplace_field.open_field }

      input_field.fill_in(with: "Updated value")
      inplace_field.submit
      inplace_field.expect_close

      within_test_selector("wp-project-attribute-#{string_field.id}") do
        expect(page).to have_text "Updated value"
      end
    end
  end

  context "as a user with edit_project_attributes but without edit_project" do
    let(:user) { create(:user, member_with_roles: { project => edit_project_attributes_only_role }) }

    before do
      login_as user
      wp_page.visit_tab! "activity"
      expect_angular_frontend_initialized
      wait_for_turbo_frame { click_on I18n.t("js.work_packages.tabs.project_attributes") }
    end

    it "allows editing a string field" do
      wait_for_turbo_stream { inplace_field.open_field }

      input_field.fill_in(with: "Updated value")
      inplace_field.submit
      inplace_field.expect_close

      within_test_selector("wp-project-attribute-#{string_field.id}") do
        expect(page).to have_text "Updated value"
      end
    end
  end

  context "as a user with view permission only" do
    let(:user) { create(:user, member_with_roles: { project => view_role }) }

    before do
      login_as user
      wp_page.visit_tab! "activity"
      expect_angular_frontend_initialized
      wait_for_turbo_frame { click_on I18n.t("js.work_packages.tabs.project_attributes") }
    end

    it "displays the field but does not allow editing" do
      expect(page).to have_test_selector("wp-project-attribute-#{string_field.id}")

      within_test_selector("wp-project-attribute-#{string_field.id}") do
        expect(page).to have_no_css(".op-inplace-edit--display-field_clickable")
      end
    end
  end
end
