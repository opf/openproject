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
require "support/edit_fields/edit_field"

RSpec.describe "Datepicker: Single-date mode logic test cases (WP #61146)", :js, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:project) { create(:project, types: [type_bug]) }

  shared_let(:bug_wp) { create(:work_package, project:, type: type_bug) }

  # assume sat+sun are non working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "start_date", "due_date", "duration"]
    query.filters.clear

    query.save!
    query
  end

  let(:date_attribute) { :combinedDate }
  let(:date_field) { work_packages_page.edit_field(date_attribute) }
  let(:datepicker) { date_field.datepicker }

  let(:current_user) { user }
  let(:work_package) { bug_wp }

  def save_and_reopen
    date_field.save!
    work_packages_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  before do
    work_package.update_columns(current_attributes)
    login_as(current_user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  describe "when adding a finish date to a new work package (scenario 1)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil
      }
    end

    it "sets the finish date and stays in single-date mode" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted

      datepicker.set_date "2025-02-14"

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted
    end
  end

  context "when adding a duration and a date to a new work package (scenario 1b)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil
      }
    end

    it "takes the new date as finish date and calculates the start date" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.focus_duration
      datepicker.set_duration "30"

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration "30"
      # calendar is showing the current month
      datepicker.expect_month Date.current.strftime("%B")

      datepicker.expect_duration_highlighted

      datepicker.set_date "2025-02-14"

      datepicker.expect_start_date "2025-01-06"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "30"
      # calendar is showing the month of the start date
      datepicker.expect_month "January"

      datepicker.expect_start_highlighted
    end
  end

  describe "when adding a start date to a new work package (scenario 2)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil
      }
    end

    it "sets the start date and switches to range mode" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.enable_start_date
      datepicker.expect_start_highlighted

      datepicker.set_date "2025-02-12"

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted
    end

    it "keeps the calendar at its position (Bug #62012)" do
      # calendar is showing the current month
      datepicker.expect_month Date.current.strftime("%B")

      in_6_months = Date.current.advance(months: 6)
      datepicker.select_month in_6_months.strftime("%B")
      datepicker.expect_month in_6_months.strftime("%B")

      # After enabling the start date, the month shown by the calendar should not have changed
      datepicker.enable_start_date
      datepicker.expect_start_date ""
      datepicker.expect_month in_6_months.strftime("%B")
    end
  end

  describe "when modifying a single date" do
    context "with the new start date in the past (scenario 3a)" do
      let(:current_attributes) do
        {
          start_date: "2025-02-12",
          due_date: nil,
          duration: nil
        }
      end

      it "sets the start date and stays in single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""

        datepicker.expect_start_highlighted

        datepicker.set_date "2025-02-03"

        datepicker.expect_start_date "2025-02-03"
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""

        datepicker.expect_start_highlighted
      end
    end

    context "with the new finish date in the past (scenario 3b)" do
      let(:current_attributes) do
        {
          start_date: nil,
          due_date: "2025-02-14",
          duration: nil
        }
      end

      it "sets the finish date and stays in single-date mode" do
        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted

        datepicker.set_date "2025-02-03"

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date "2025-02-03"
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted
      end
    end

    context "with the new start date in the future (scenario 4a)" do
      let(:current_attributes) do
        {
          start_date: "2025-02-12",
          due_date: nil,
          duration: nil
        }
      end

      it "sets the start date and stays in single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""

        datepicker.expect_start_highlighted

        datepicker.set_date "2025-02-26"

        datepicker.expect_start_date "2025-02-26"
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""

        datepicker.expect_start_highlighted
      end
    end

    context "with the new finish date in the future (scenario 4b)" do
      let(:current_attributes) do
        {
          start_date: nil,
          due_date: "2025-02-14",
          duration: nil
        }
      end

      it "sets the finish date and stays in single-date mode" do
        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted

        datepicker.set_date "2025-02-26"

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date "2025-02-26"
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted
      end
    end
  end

  context "when clearing the finish date (scenario 5)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: "2025-02-14",
        duration: nil
      }
    end

    it "stays in single-date mode" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted

      datepicker.set_due_date ""

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted
    end
  end

  context "when clearing the start date (scenario 6)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: nil,
        duration: nil
      }
    end

    it "stays in single-date mode" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.expect_start_highlighted

      datepicker.set_start_date ""

      datepicker.expect_start_date ""
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.expect_start_highlighted
    end
  end

  context "when a finish date is given and a start date is added (scenario 7)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: "2025-02-14",
        duration: nil
      }
    end

    it "switches to range mode and calculates a duration" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.enable_start_date
      datepicker.expect_start_highlighted

      datepicker.set_date "2025-02-12"

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.expect_due_highlighted
    end
  end

  context "when a finish date is given and a duration is added (scenario 8)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: "2025-02-14",
        duration: nil
      }
    end

    it "switches to range mode and calculates a start date" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.focus_duration
      datepicker.set_duration 3

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.expect_duration_highlighted
    end
  end

  context "when a finish date is given at first, then deleted and a duration is added (scenario 9)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: "2025-02-14",
        duration: nil
      }
    end

    it "stays in single-date mode" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.set_due_date ""
      datepicker.focus_duration
      datepicker.set_duration 3

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration "3"

      datepicker.expect_duration_highlighted
    end
  end

  context "when a finish date is given, then changed and a duration is added (scenario 9b)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: "2025-02-14",
        duration: nil
      }
    end

    it "switches to range mode and calculates a start date" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.set_due_date "2025-02-13"
      datepicker.focus_duration
      datepicker.set_duration 3

      datepicker.expect_start_date "2025-02-11"
      datepicker.expect_due_date "2025-02-13"
      datepicker.expect_duration "3"

      datepicker.expect_duration_highlighted
    end
  end

  context "when a start date is given and a finish date is added (scenario 10)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: nil,
        duration: nil
      }
    end

    it "switches to range mode and calculates a duration" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.enable_due_date
      datepicker.expect_due_highlighted

      datepicker.set_date "2025-02-14"

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.expect_start_highlighted
    end

    it "keeps the calendar at its position when the finish date is enabled (Bug #62012)" do
      # calendar is showing the month of the start date
      datepicker.expect_month "February"

      datepicker.select_month "May"
      datepicker.expect_month "May"

      datepicker.enable_due_date
      datepicker.expect_due_highlighted
      # After enabling the due date, the month shown by the calendar should not have changed
      datepicker.expect_month "May"

      datepicker.set_due_date "2025-02-14"
      datepicker.expect_due_date "2025-02-14"
      # After setting the due date, the calendar is showing the month of the due date
      datepicker.expect_month "February"
    end
  end

  context "when a start date is given and a duration is added (scenario 11)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: nil,
        duration: nil
      }
    end

    it "switches to range mode and calculates a finish date" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.focus_duration
      datepicker.set_duration 3

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.expect_duration_highlighted
    end
  end

  context "when a start date is given at first, then deleted and a duration is added (scenario 12)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: nil,
        duration: nil
      }
    end

    it "stays in single-date mode" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.set_start_date ""
      datepicker.focus_duration
      datepicker.set_duration 3

      datepicker.expect_start_date ""
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration "3"

      datepicker.expect_duration_highlighted
    end
  end

  context "when a start date is given, then changed and a duration is added (scenario 12b)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: nil,
        duration: nil
      }
    end

    it "switches to range mode and calculates a finish date" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.set_start_date "2025-02-11"
      datepicker.focus_duration
      datepicker.set_duration 3

      datepicker.expect_start_date "2025-02-11"
      datepicker.expect_due_date "2025-02-13"
      datepicker.expect_duration "3"

      datepicker.expect_duration_highlighted
    end
  end

  context "when start and finish date are given and the finish date is removed (scenario 13)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: "2025-02-14",
        duration: "3"
      }
    end

    it "stays in range mode and removes the duration" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.set_due_date ""

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted
    end
  end

  context "when start and finish date are given and the start date is removed (scenario 14)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: "2025-02-14",
        duration: "3"
      }
    end

    it "stays in range mode and removes the duration" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.set_start_date ""

      datepicker.expect_start_date ""
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.expect_start_highlighted
    end
  end

  context "when start and finish date are given and the duration is removed (scenario 15)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: "2025-02-14",
        duration: "3"
      }
    end

    it "stays in range mode and removes the finish date" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration "3"

      datepicker.set_duration ""

      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_duration_highlighted
    end
  end

  context "when only finish date is given, then removed, saved and re-opened (scenario 16)" do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: "2025-02-14",
        duration: nil
      }
    end

    it "stays in single-date mode and remains the field to hide" do
      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date "2025-02-14"
      datepicker.expect_duration ""

      datepicker.set_due_date ""

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      save_and_reopen

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted
    end
  end

  context "when only start date is given, then removed, saved and re-opened (scenario 17)" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: nil,
        duration: nil
      }
    end

    it "stays in single-date mode but changes the field to hide" do
      datepicker.expect_start_date "2025-02-12"
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      datepicker.set_start_date ""

      datepicker.expect_start_date ""
      datepicker.expect_due_date "", visible: false
      datepicker.expect_duration ""

      save_and_reopen

      datepicker.expect_start_date "", visible: false
      datepicker.expect_due_date ""
      datepicker.expect_duration ""

      datepicker.expect_due_highlighted
    end
  end

  context "when start and finish date are given" do
    let(:current_attributes) do
      {
        start_date: "2025-02-12",
        due_date: "2025-02-14",
        duration: "3"
      }
    end

    context "and duration is removed, saved and re-opened (scenario 18)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_duration ""

        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date ""
        datepicker.expect_duration ""

        save_and_reopen

        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""

        datepicker.expect_start_highlighted
      end
    end

    context "and start date is removed, saved and re-opened (scenario 19)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_start_date ""

        datepicker.expect_start_date ""
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration ""

        save_and_reopen

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted
      end
    end

    context "and finish date is removed, saved and re-opened (scenario 20)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_due_date ""

        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date ""
        datepicker.expect_duration ""

        save_and_reopen

        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""

        datepicker.expect_start_highlighted
      end
    end

    context "and all dates are cleared, saved and re-opened (scenario 21a)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_due_date ""
        wait_for_network_idle
        datepicker.set_start_date ""
        wait_for_network_idle

        datepicker.expect_start_date ""
        datepicker.expect_due_date ""
        datepicker.expect_duration ""

        save_and_reopen

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date ""
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted
      end
    end

    context "and all dates are cleared in a different order, saved and re-opened (scenario 21b)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_start_date ""
        wait_for_network_idle
        datepicker.set_due_date ""
        wait_for_network_idle

        datepicker.expect_start_date ""
        datepicker.expect_due_date ""
        datepicker.expect_duration ""

        save_and_reopen

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date ""
        datepicker.expect_duration ""

        datepicker.expect_due_highlighted
      end
    end

    context "and all dates are cleared and a duration is set, saved and re-opened (scenario 22a)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_due_date ""
        datepicker.set_start_date ""
        datepicker.focus_duration
        datepicker.set_duration "5"

        datepicker.expect_start_date ""
        datepicker.expect_due_date ""
        datepicker.expect_duration "5"

        save_and_reopen

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date ""
        datepicker.expect_duration "5"

        datepicker.expect_due_highlighted
      end
    end

    context "and all dates are cleared in a different order and a duration is set, saved and re-opened (scenario 22b)" do
      it "switches to single-date mode" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_start_date ""
        datepicker.set_due_date ""
        datepicker.focus_duration
        datepicker.set_duration "5"

        datepicker.expect_start_date ""
        datepicker.expect_due_date ""
        datepicker.expect_duration "5"

        save_and_reopen

        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date ""
        datepicker.expect_duration "5"

        datepicker.expect_due_highlighted
      end
    end

    context "and start date is cleared and a duration is set (scenario 23a)" do
      it "calculates the start date" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_start_date ""
        datepicker.focus_duration
        datepicker.set_duration "2"

        datepicker.expect_start_date "2025-02-13"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "2"

        datepicker.expect_duration_highlighted
      end
    end

    context "and finish date is cleared and a duration is set (scenario 23b)" do
      it "calculates the finish date" do
        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-14"
        datepicker.expect_duration "3"

        datepicker.set_due_date ""
        datepicker.focus_duration
        datepicker.set_duration "2"

        datepicker.expect_start_date "2025-02-12"
        datepicker.expect_due_date "2025-02-13"
        datepicker.expect_duration "2"

        datepicker.expect_duration_highlighted
      end
    end
  end

  context "when being on the WP table" do
    let(:start_field) { wp_table.edit_field(work_package, :startDate) }
    let(:due_field) { wp_table.edit_field(work_package, :dueDate) }
    let(:duration) { wp_table.edit_field(work_package, :duration) }

    before do
      wp_table.visit_query query
    end

    context "with empty values" do
      let(:current_attributes) do
        {
          start_date: nil,
          due_date: nil,
          duration: nil
        }
      end

      it "can open the datepicker" do
        start_field.activate!
        start_field.expect_active!

        datepicker.expect_visible
        datepicker.expect_start_date ""
        datepicker.expect_due_date "", visible: false
        datepicker.expect_duration ""
        datepicker.expect_start_highlighted
        datepicker.cancel!

        due_field.activate!
        due_field.expect_active!

        datepicker.expect_visible
        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date ""
        datepicker.expect_duration ""
        datepicker.expect_due_highlighted
        datepicker.cancel!

        duration.activate!
        duration.expect_active!

        datepicker.expect_visible
        datepicker.expect_start_date "", visible: false
        datepicker.expect_due_date ""
        datepicker.expect_duration ""
        datepicker.expect_duration_highlighted
        datepicker.cancel!
      end
    end

    context "when clicking in a specific date field (regression #62058)" do
      context "when no dates are set" do
        let(:current_attributes) do
          {
            start_date: nil,
            due_date: nil,
            duration: nil
          }
        end

        it "opens the clicked date in single-date mode" do
          start_field.activate!
          start_field.expect_active!

          # Start date is clicked and expected to be active in single-date mode with the due date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date ""
          datepicker.expect_due_date "", visible: false
          datepicker.expect_duration ""
          datepicker.expect_start_highlighted
          datepicker.cancel!

          due_field.activate!
          due_field.expect_active!

          # Due date is clicked and expected to be active in single-date mode with the start date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "", visible: false
          datepicker.expect_due_date ""
          datepicker.expect_duration ""
          datepicker.expect_due_highlighted
          datepicker.cancel!

          duration.activate!
          duration.expect_active!

          # Duration is clicked and expected to be active in single-date mode with the start date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "", visible: false
          datepicker.expect_due_date ""
          datepicker.expect_duration ""
          datepicker.expect_duration_highlighted
          datepicker.cancel!
        end
      end

      context "when only start date is set" do
        let(:current_attributes) do
          {
            start_date: "2025-02-12",
            due_date: nil,
            duration: nil
          }
        end

        it "opens the clicked date and goes to range mode if necessary" do
          start_field.activate!
          start_field.expect_active!

          # Start date is clicked and expected to be active in single-date mode with the due date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "2025-02-12"
          datepicker.expect_due_date "", visible: false
          datepicker.expect_duration ""
          datepicker.expect_start_highlighted
          datepicker.cancel!

          due_field.activate!
          due_field.expect_active!

          # Due date is clicked and expected to be active in range mode
          datepicker.expect_visible
          datepicker.expect_start_date "2025-02-12"
          datepicker.expect_due_date ""
          datepicker.expect_duration ""
          datepicker.expect_due_highlighted
          datepicker.cancel!

          duration.activate!
          duration.expect_active!

          # Duration is clicked and expected to be active in single-date mode with the due date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "2025-02-12"
          datepicker.expect_due_date "", visible: false
          datepicker.expect_duration ""
          datepicker.expect_duration_highlighted
          datepicker.cancel!
        end
      end

      context "when only finish date is set" do
        let(:current_attributes) do
          {
            start_date: nil,
            due_date: "2025-02-14",
            duration: nil
          }
        end

        it "opens the clicked date and goes to range mode if necessary" do
          start_field.activate!
          start_field.expect_active!

          # Start date is clicked and expected to be active in range mode
          datepicker.expect_visible
          datepicker.expect_start_date ""
          datepicker.expect_due_date "2025-02-14"
          datepicker.expect_duration ""
          datepicker.expect_start_highlighted
          datepicker.cancel!

          due_field.activate!
          due_field.expect_active!

          # Due date is clicked and expected to be active in single-date mode with the start date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "", visible: false
          datepicker.expect_due_date "2025-02-14"
          datepicker.expect_duration ""
          datepicker.expect_due_highlighted
          datepicker.cancel!

          duration.activate!
          duration.expect_active!

          # Duration is clicked and expected to be active in single-date mode with the start date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "", visible: false
          datepicker.expect_due_date "2025-02-14"
          datepicker.expect_duration ""
          datepicker.expect_duration_highlighted
          datepicker.cancel!
        end
      end

      context "when both dates are set" do
        let(:current_attributes) do
          {
            start_date: "2025-02-12",
            due_date: "2025-02-14",
            duration: 3
          }
        end

        it "opens the clicked date and stays in range mode" do
          start_field.activate!
          start_field.expect_active!

          # Start date is clicked and expected to be active in range mode
          datepicker.expect_visible
          datepicker.expect_start_date "2025-02-12"
          datepicker.expect_due_date "2025-02-14"
          datepicker.expect_duration "3"
          datepicker.expect_start_highlighted
          datepicker.cancel!

          due_field.activate!
          due_field.expect_active!

          # Due date is clicked and expected to be active in single-date mode with the start date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "2025-02-12"
          datepicker.expect_due_date "2025-02-14"
          datepicker.expect_duration "3"
          datepicker.expect_due_highlighted
          datepicker.cancel!

          duration.activate!
          duration.expect_active!

          # Duration is clicked and expected to be active in single-date mode with the start date being hidden
          datepicker.expect_visible
          datepicker.expect_start_date "2025-02-12"
          datepicker.expect_due_date "2025-02-14"
          datepicker.expect_duration "3"
          datepicker.expect_duration_highlighted
          datepicker.cancel!
        end
      end
    end
  end
end
