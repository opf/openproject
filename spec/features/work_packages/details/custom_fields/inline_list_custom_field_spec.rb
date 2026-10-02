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

RSpec.describe "List custom fields displayed inline", :js do
  let(:user) { create(:admin) }
  let(:severity) do
    create(:list_wp_custom_field, name: "Severity", possible_values: %w[low medium high], display_as: "radio_buttons")
  end
  let(:platforms) do
    create(:list_wp_custom_field,
           name: "Platforms",
           multi_value: true,
           possible_values: %w[Windows Linux macOS],
           display_as: "checkboxes")
  end
  let(:custom_fields) { [severity, platforms] }
  let(:type) { create(:type_task, custom_fields:) }
  let(:project) { create(:project, types: [type], work_package_custom_fields: custom_fields) }
  let!(:work_package) { create(:work_package, type:, project:, subject: "Phishing campaign") }

  current_user { user }

  def option(custom_field, value)
    custom_field.custom_options.find_by!(value:)
  end

  describe "in the work package view" do
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
    let(:severity_field) { wp_page.edit_field(severity.attribute_name(:camel_case)) }
    let(:platforms_field) { wp_page.edit_field(platforms.attribute_name(:camel_case)) }

    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it "edits single-select values with radio buttons and multi-select values with checkboxes" do
      severity_field.activate!
      within(severity_field.field_container) do
        expect(page).to have_field(type: "radio", count: 4, wait: 20)
        choose "high"
      end

      wp_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))
      severity_field.expect_state_text "high"

      platforms_field.activate!
      within(platforms_field.field_container) do
        expect(page).to have_field(type: "checkbox", count: 3, wait: 20)
        check "Windows"
        check "macOS"
      end
      platforms_field.submit_by_dashboard

      wp_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))
      platforms_field.expect_state_text "Windows"
      platforms_field.expect_state_text "macOS"

      work_package.reload
      expect(work_package.send(severity.attribute_getter)).to eq("high")
      expect(work_package.send(platforms.attribute_getter)).to contain_exactly("Windows", "macOS")

      page.driver.refresh
      wp_page.ensure_page_loaded

      platforms_field.activate!
      within(platforms_field.field_container) do
        expect(page).to have_checked_field("Windows")
        expect(page).to have_checked_field("macOS")
        expect(page).to have_unchecked_field("Linux")
        uncheck "Windows"
      end
      platforms_field.submit_by_dashboard

      wp_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))
      expect(work_package.reload.send(platforms.attribute_getter)).to contain_exactly("macOS")
    end
  end

  describe "in the work package table" do
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:query) do
      create(:query, project:, user:, column_names: ["subject", severity.column_name, platforms.column_name])
    end

    before do
      work_package.update!(severity.attribute_name => option(severity, "low"))
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(work_package)
    end

    it "shows the values and keeps the dropdown for editing" do
      wp_table.expect_work_package_with_attributes(work_package, severity.attribute_name(:camel_case) => "low")

      field = wp_table.edit_field(work_package, severity.attribute_name(:camel_case))
      field.field_type = "create-autocompleter"
      field.activate!

      expect(page).to have_css(".#{severity.attribute_name(:camel_case)} ng-select")
      expect(page).to have_no_field(type: "radio")

      field.set_value "medium"

      wp_table.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))
      expect(work_package.reload.send(severity.attribute_getter)).to eq("medium")
    end
  end
end
