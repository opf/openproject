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

RSpec.describe "Logging time within the work package view", :js do
  shared_let(:project) { create(:project) }
  shared_let(:admin) { create(:admin) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:activity) { create(:time_entry_activity, project:) }

  let(:user) { admin }

  let(:spent_time_field) { SpentTimeEditField.new(page, "spentTime") }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  let(:time_logging_modal) { Components::TimeLoggingModal.new }

  def log_time_via_modal(user_field_visible: true, log_for_user: nil, date: Time.zone.today)
    time_logging_modal.is_visible true

    # the fields are visible
    time_logging_modal.has_field_with_value "spent_on", Time.zone.today.strftime("%Y-%m-%d")
    time_logging_modal.shows_field "work_package", false
    time_logging_modal.shows_field "user", user_field_visible

    # Update the fields
    time_logging_modal.update_field "activity", activity.name

    Components::BasicDatepicker.update_field(
      "##{time_logging_modal.field_identifier('spent_on')}",
      date.strftime("%Y-%m-%d")
    )

    if log_for_user
      time_logging_modal.update_field "user", log_for_user.name
    elsif user_field_visible
      expect(page).to have_css(".ng-value-label", text: user.name)
    end

    # a click on save creates a time entry
    time_logging_modal.perform_action I18n.t(:button_save)
    wp_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_create")
  end

  context "as an admin" do
    before do
      login_as(user)
      wp_page.visit!
      loading_indicator_saveguard
      spent_time_field.time_log_icon_visible true
    end

    it "shows a logging button within the display field and can log time via a modal" do
      # click on button opens modal
      spent_time_field.open_time_log_modal
      expect do
        log_time_via_modal(date: Date.yesterday)
      end.to change(TimeEntry, :count).by(1)

      # the value is updated automatically
      spent_time_field.expect_display_value "1h"

      TimeEntry.last.tap do |te|
        expect(te.work_package).to eq(work_package)
        expect(te.project).to eq(project)
        expect(te.activity).to eq(activity)
        expect(te.user).to eq(user)
        expect(te.spent_on).to eq(Date.yesterday)
        expect(te.hours).to eq(1)
      end
    end

    context "with another user in the project" do
      let!(:other_user) do
        create(:user,
               firstname: "Loggable",
               lastname: "User",
               member_with_permissions: { project => %i[view_work_packages edit_work_packages work_package_assigned] })
      end

      it "can log time for that user" do
        # click on button opens modal
        spent_time_field.open_time_log_modal

        log_time_via_modal log_for_user: other_user

        # the value is updated automatically
        spent_time_field.expect_display_value "1h"

        time_entry = TimeEntry.last
        expect(time_entry.user).to eq other_user
        expect(time_entry.logged_by).to eq user
      end
    end

    it "the context menu entry to log time leads to the modal" do
      # click on context menu opens the modal
      find("#action-show-more-dropdown-menu .button").click
      find(".menu-item", text: "Log time").click

      log_time_via_modal

      # the value is updated automatically
      spent_time_field.expect_display_value "1h"
    end

    context "with a user with non-one unit numbers", with_settings: { available_languages: %w[en ja] } do
      let(:user) { create(:admin, language: "ja") }

      before do
        I18n.locale = "ja"
      end

      it "shows the correct number (Regression #36269)" do
        # click on button opens modal
        spent_time_field.open_time_log_modal

        log_time_via_modal

        # the value is updated automatically
        spent_time_field.expect_display_value "1h"
      end
    end
  end

  context "as a user who cannot log time" do
    let(:user) do
      create(:user,
             member_with_permissions: { project => %i[view_time_entries view_work_packages edit_work_packages] })
    end

    before do
      login_as(user)
      wp_page.visit!
      loading_indicator_saveguard
    end

    it "shows no logging button within the display field" do
      spent_time_field.time_log_icon_visible false
      spent_time_field.expect_display_value "0h"
    end
  end

  context "as a user who can only log own time" do
    let(:user) do
      create(:user,
             member_with_permissions: { project => %i[view_time_entries view_work_packages log_own_time] })
    end

    before do
      login_as(user)
      wp_page.visit!
      loading_indicator_saveguard
    end

    it "can log its own time" do
      spent_time_field.time_log_icon_visible true
      # click on button opens modal
      spent_time_field.open_time_log_modal

      log_time_via_modal user_field_visible: false

      # the value is updated automatically
      spent_time_field.expect_display_value "1h"
    end
  end

  context "when in the table" do
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:second_work_package) { create(:work_package, project:) }
    let(:query) { create(:public_query, project:, column_names: ["subject", "spent_hours"]) }

    before do
      work_package
      second_work_package
      login_as(admin)

      wp_table.visit_query query
      loading_indicator_saveguard
    end

    it "shows no logging button within the display field" do
      wp_table.expect_work_package_listed work_package, second_work_package

      find("tr:nth-of-type(1) .wp-table--cell-td.spentTime .icon-time").click

      log_time_via_modal

      expect(page).to have_css("tr:nth-of-type(1) .wp-table--cell-td.spentTime", text: "1h")
      expect(page).to have_css("tr:nth-of-type(2) .wp-table--cell-td.spentTime", text: "0h")
    end
  end
end
