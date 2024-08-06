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

require_relative "../spec_helper"

RSpec.describe "Work Package timer", :js do
  shared_let(:project) { create(:project_with_types) }

  shared_let(:work_package_a) { create(:work_package, subject: "WP A", project:) }
  shared_let(:work_package_b) { create(:work_package, subject: "WP B", project:) }

  let(:wp_view_a) { Pages::FullWorkPackage.new(work_package_a) }
  let(:wp_view_b) { Pages::FullWorkPackage.new(work_package_b) }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }
  let(:timer_button) { Components::WorkPackages::TimerButton.new }

  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before do
    login_as user
  end

  shared_examples "allows time tracking" do
    it "shows the timer and allows tracking time" do
      wp_view_a.visit!
      timer_button.expect_visible
      timer_button.start
      timer_button.expect_active

      active_time_entries = TimeEntry.where(ongoing: true, user:)
      expect(active_time_entries.count).to eq 1
      timer_entry = active_time_entries.first
      expect(timer_entry.work_package).to eq work_package_a
      expect(timer_entry.hours).to be_nil

      page.find(".op-top-menu-user").click
      expect(page).to have_css(".op-timer-account-menu", wait: 10)
      expect(page).to have_css(".op-timer-account-menu--wp-details", text: "##{work_package_a.id}: WP A")
      page.find_test_selector("op-timer-account-menu-stop").click

      time_logging_modal.is_visible true

      time_logging_modal.has_field_with_value "spentOn", Date.current.strftime
      time_logging_modal.has_field_with_value "hours", /(\d\.)?\d+/
      time_logging_modal.work_package_is_missing false
      # wait for available_work_packages query to finish before saving
      time_logging_modal.expect_work_package(work_package_a.subject)

      time_logging_modal.perform_action "Save"
      time_logging_modal.is_visible false

      wp_view_a.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)
      timer_button.expect_inactive

      timer_entry.reload
      expect(timer_entry.ongoing).to be false
      expect(timer_entry.hours).not_to be_nil

      timer_button.start
      timer_button.expect_active

      wp_view_b.visit!

      # Clicking timer opens stop modal
      timer_button.expect_visible
      timer_button.expect_inactive

      timer_button.start

      expect(page).to have_css(".op-timer-stop-modal")
      expect(page).to have_text("Tracking time:")

      active_time_entries = TimeEntry.where(ongoing: true, user:)
      expect(active_time_entries.count).to eq 1
      timer_entry = active_time_entries.first
      expect(timer_entry.work_package).to eq work_package_a
      expect(timer_entry.hours).to be_nil

      page.within(".spot-modal") { click_button "Stop current timer" }
      time_logging_modal.is_visible true
      time_logging_modal.has_field_with_value "spentOn", Date.current.strftime
      time_logging_modal.has_field_with_value "hours", /(\d\.)?\d+/
      time_logging_modal.work_package_is_missing false
      # wait for available_work_packages query to finish before saving
      time_logging_modal.expect_work_package(work_package_a.subject)

      time_logging_modal.perform_action "Save"

      # Closing the modal starts the next timer
      wp_view_b.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)
      time_logging_modal.is_visible false
      timer_button.expect_active

      # Timer entry has been saved
      timer_entry.reload
      expect(timer_entry.ongoing).to be false
      expect(timer_entry.hours).not_to be_nil

      active_time_entries = TimeEntry.where(ongoing: true, user:)
      expect(active_time_entries.count).to eq 1
      timer_entry = active_time_entries.first
      expect(timer_entry.work_package).to eq work_package_b
      expect(timer_entry.hours).to be_nil
    end
  end

  context "when user has permission to log time" do
    let(:permissions) { %i[log_own_time edit_own_time_entries view_own_time_entries view_work_packages] }

    it_behaves_like "allows time tracking"

    context "when an old timer exists" do
      let!(:active_timer) do
        Timecop.travel(2.days.ago) do
          create(:time_entry, project:, work_package: work_package_a, user:, ongoing: true)
        end
      end

      it "correctly shows active timers > 24 hours" do
        wp_view_a.visit!
        timer_button.expect_visible
        timer_button.expect_time /48:0\d:\d+/
      end
    end

    it "correctly handles timers in multiple tabs" do
      wp_view_a.visit!
      timer_button.expect_visible

      second_window = open_new_window
      within_window(second_window) do
        wp_view_a.visit!
        timer_button.expect_visible
        timer_button.start
        timer_button.expect_active
      end

      timer_button.expect_inactive
      timer_button.start

      expect(page).to have_css(".op-timer-stop-modal")
      expect(page).to have_text("Tracking time:")

      page.within(".spot-modal") { click_button "Stop current timer" }
      time_logging_modal.is_visible true
      time_logging_modal.has_field_with_value "spentOn", Date.current.strftime
      time_logging_modal.has_field_with_value "hours", /(\d\.)?\d+/
      time_logging_modal.work_package_is_missing false
      # wait for available_work_packages query to finish before saving
      time_logging_modal.expect_work_package(work_package_a.subject)

      time_logging_modal.perform_action "Save"
      wp_view_b.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)
      time_logging_modal.is_visible false
      timer_button.expect_active

      timer_button.stop
      time_logging_modal.is_visible true
      time_logging_modal.has_field_with_value "spentOn", Date.current.strftime
      time_logging_modal.has_field_with_value "hours", /(\d\.)?\d+/
      time_logging_modal.work_package_is_missing false
      # wait for available_work_packages query to finish before saving
      time_logging_modal.expect_work_package(work_package_a.subject)

      time_logging_modal.perform_action "Save"
      wp_view_b.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)
      time_logging_modal.is_visible false
      timer_button.expect_inactive

      within_window(second_window) do
        timer_button.expect_active
        timer_button.stop
        wp_view_b.expect_and_dismiss_toaster message: I18n.t("js.timer.timer_already_stopped"), type: :warning
      end
    end
  end

  context "when user has no permission to log time" do
    let(:permissions) { %i[view_work_packages] }

    it "does not show the timer" do
      wp_view_a.visit!

      # Wait for another button to be present
      expect(page).to have_css("#watch-button", wait: 10)
      timer_button.expect_visible visible: false
    end
  end

  context "when user has permission to add, but not edit or view" do
    let(:permissions) { %i[view_work_packages log_own_time] }

    it_behaves_like "allows time tracking"
  end

  context "when user has permission to add and view but not edit" do
    let(:permissions) { %i[view_work_packages log_own_time view_own_logged_time] }

    it_behaves_like "allows time tracking"
  end
end
