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

RSpec.describe "Values of a work package custom field in the project settings",
               :js,
               with_ee: %i[project_specific_list_values] do
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:project) { create(:project, types: [feature]) }

  let(:project_level_value_management) { true }
  let(:allow_additional_project_values) { true }
  let!(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist,
           name: "Supplier", types: [feature], possible_values: %w[Acme Initech],
           project_level_value_management:, allow_additional_project_values:)
  end
  let(:acme) { custom_field.custom_options.find_by!(value: "Acme") }
  let(:initech) { custom_field.custom_options.find_by!(value: "Initech") }

  let(:own_value_row) do
    own_value = custom_field.custom_options.find_by!(project:)
    find_test_selector("custom-field-project-value-#{own_value.id}")
  end

  current_user do
    create(:user, member_with_permissions: { project => %i[manage_work_package_custom_field_values] })
  end

  context "when project admins may manage and add values" do
    it "enables a global value and adds, renames and deletes a project-specific value" do
      visit project_settings_work_packages_custom_fields_path(project)
      click_on "Supplier"

      within_test_selector("custom-field-project-value-#{acme.id}") do
        find("button[aria-pressed='false']").click
        expect(page).to have_css("button[aria-pressed='true']")
      end

      page.refresh
      within_test_selector("custom-field-project-value-#{acme.id}") do
        expect(page).to have_css("button[aria-pressed='true']")
      end

      click_on I18n.t("custom_fields.admin.projects.new_value")
      within_test_selector("custom-field-project-value-dialog") do
        fill_in I18n.t("custom_fields.admin.projects.value_dialog.name"), with: "Own"
        click_on I18n.t(:button_add)
      end

      expect(page).to have_no_test_selector("custom-field-project-value-dialog")
      expect(own_value_row).to have_text("Own")
      expect(own_value_row).to have_text(I18n.t("custom_fields.project_specific_values.label"))

      own_value_row.find(:test_id, "custom-field-project-value-menu").click
      click_on I18n.t("custom_fields.admin.projects.edit_value")
      within_test_selector("custom-field-project-value-dialog") do
        fill_in I18n.t("custom_fields.admin.projects.value_dialog.name"), with: "Own renamed"
        click_on I18n.t(:button_save)
      end

      expect(page).to have_no_test_selector("custom-field-project-value-dialog")
      expect(own_value_row).to have_text("Own renamed")

      own_value_row.find(:test_id, "custom-field-project-value-menu").click
      click_on I18n.t(:button_delete)
      within_test_selector("custom-field-project-value-delete-dialog") do
        check I18n.t(:text_permanent_delete_confirmation_checkbox_label), allow_label_click: true
        click_on I18n.t(:button_delete_permanently)
      end

      expect_flash(message: I18n.t(:notice_successful_delete))
      expect(page).to have_no_text("Own renamed")
      expect(custom_field.custom_options.where(project:)).to be_empty
    end
  end

  context "when project admins may only add values" do
    let(:project_level_value_management) { false }

    before do
      create(:project_specific_value_restriction, project:, custom_option: acme)
    end

    it "lists only the enabled values without toggles and adds a project-specific value" do
      visit project_settings_work_packages_custom_field_values_path(project, custom_field)

      expect(page).to have_test_selector("custom-field-project-value-#{acme.id}")
      expect(page).to have_no_test_selector("custom-field-project-value-#{initech.id}")
      expect(page).to have_no_css("button[aria-pressed]")
      expect(page).to have_no_link(I18n.t("custom_fields.admin.projects.enable_all"))
      expect(page).to have_no_link(I18n.t("custom_fields.admin.projects.disable_all"))

      click_on I18n.t("custom_fields.admin.projects.new_value")
      within_test_selector("custom-field-project-value-dialog") do
        fill_in I18n.t("custom_fields.admin.projects.value_dialog.name"), with: "Own"
        click_on I18n.t(:button_add)
      end

      expect(page).to have_no_test_selector("custom-field-project-value-dialog")
      expect(own_value_row).to have_text("Own")
    end
  end

  context "when project admins may only manage values" do
    let(:allow_additional_project_values) { false }

    before do
      create(:custom_option, custom_field:, value: "Own", project:)
    end

    it "toggles global values and only allows deleting project-specific values" do
      visit project_settings_work_packages_custom_field_values_path(project, custom_field)

      within_test_selector("custom-field-project-value-#{initech.id}") do
        find("button[aria-pressed='false']").click
        expect(page).to have_css("button[aria-pressed='true']")
      end

      expect(page).to have_no_button(I18n.t("custom_fields.admin.projects.new_value"))

      own_value_row.find(:test_id, "custom-field-project-value-menu").click
      expect(page).to have_no_text(I18n.t("custom_fields.admin.projects.edit_value"))
      click_on I18n.t(:button_delete)
      within_test_selector("custom-field-project-value-delete-dialog") do
        check I18n.t(:text_permanent_delete_confirmation_checkbox_label), allow_label_click: true
        click_on I18n.t(:button_delete_permanently)
      end

      expect_flash(message: I18n.t(:notice_successful_delete))
      expect(custom_field.custom_options.where(project:)).to be_empty
    end
  end

  context "when project admins may neither manage nor add values" do
    let(:project_level_value_management) { false }
    let(:allow_additional_project_values) { false }

    before do
      create(:project_specific_value_restriction, project:, custom_option: acme)
      create(:custom_option, custom_field:, value: "Own", project:)
    end

    it "shows the available values read-only and still allows deleting project-specific values" do
      visit project_settings_work_packages_custom_field_values_path(project, custom_field)

      expect(page).to have_test_selector("custom-field-project-value-#{acme.id}")
      expect(page).to have_no_test_selector("custom-field-project-value-#{initech.id}")
      expect(page).to have_no_text("Choose which values of Supplier")
      expect(page).to have_no_css("button[aria-pressed]")
      expect(page).to have_no_button(I18n.t("custom_fields.admin.projects.new_value"))

      own_value_row.find(:test_id, "custom-field-project-value-menu").click
      expect(page).to have_no_text(I18n.t("custom_fields.admin.projects.edit_value"))
      click_on I18n.t(:button_delete)
      within_test_selector("custom-field-project-value-delete-dialog") do
        check I18n.t(:text_permanent_delete_confirmation_checkbox_label), allow_label_click: true
        click_on I18n.t(:button_delete_permanently)
      end

      expect_flash(message: I18n.t(:notice_successful_delete))
      expect(custom_field.custom_options.where(project:)).to be_empty
    end
  end
end
