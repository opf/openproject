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
require "support/edit_fields/edit_field"

RSpec.describe "Datepicker: Finish date field in auto-scheduled mode logic test cases (WP #62599)", :js,
               with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:project) { create(:project, types: [type_bug]) }

  shared_let(:work_package) do
    create(:work_package,
           project:,
           type: type_bug,
           start_date: "2025-04-08",
           due_date: "2025-04-17",
           duration: 8,
           schedule_manually: false)
  end
  shared_let(:predecessor) { create(:work_package, project:, type: type_bug, start_date: "2025-04-07", due_date: "2025-04-07") }

  let!(:relationship) do
    create(:relation,
           from: predecessor,
           to: work_package,
           relation_type: Relation::TYPE_PRECEDES)
  end
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

  # assume sat+sun are non working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  before do
    login_as(current_user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
    datepicker.expect_automatic_scheduling_mode
    datepicker.expect_start_date "2025-04-08", disabled: true
    datepicker.expect_due_date "2025-04-17", disabled: false
    datepicker.expect_duration "8"

    datepicker.expect_due_highlighted
  end

  describe "when changing finish date (manual input) (scenario 1)" do
    it "sets the finish date and calculates the duration" do
      datepicker.set_due_date "2025-04-23"

      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-23", disabled: false
      datepicker.expect_duration "12"

      datepicker.expect_due_highlighted
    end
  end

  describe "when changing finish date (click on calendar) (scenario 2)" do
    it "sets the finish date and calculates the duration" do
      datepicker.set_date "2025-04-23"

      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-23", disabled: false
      datepicker.expect_duration "12"

      datepicker.expect_due_highlighted
    end
  end

  describe "when changing duration (scenario 3)" do
    it "sets the duration and calculates the finish date" do
      datepicker.set_duration "12"

      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-23", disabled: false
      datepicker.expect_duration "12"

      datepicker.expect_due_highlighted
    end
  end

  describe "when changing finish date and non-working days (scenario 4)" do
    it "keeps the finish date and calculates the duration" do
      datepicker.set_date "2025-04-23"

      datepicker.expect_working_days_only(true)
      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-23", disabled: false
      datepicker.expect_duration "12"

      datepicker.toggle_working_days_only

      datepicker.expect_working_days_only(false)
      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-23", disabled: false
      datepicker.expect_duration "16"
    end
  end

  describe "when changing duration date and non-working days (scenario 5)" do
    it "keeps the duration and calculates the finish date" do
      datepicker.set_duration "14"

      datepicker.expect_working_days_only(true)
      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-25", disabled: false
      datepicker.expect_duration "14"

      datepicker.toggle_working_days_only

      datepicker.expect_working_days_only(false)
      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-21", disabled: false
      datepicker.expect_duration "14"
    end
  end

  describe "when launching date-picker with duration but change finish date (scenario 6)" do
    let(:duration) { wp_table.edit_field(work_package, :duration) }

    before do
      wp_table.visit_query query
    end

    it "sets the finish date" do
      duration.activate!
      duration.expect_active!

      datepicker.expect_visible
      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-17", disabled: false
      datepicker.expect_duration "8"
      datepicker.expect_duration_highlighted

      datepicker.set_date "2025-04-24"

      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "2025-04-24", disabled: false
      datepicker.expect_duration "13"
    end
  end

  describe "when removing the finish date (scenario 7)" do
    it "clears duration and finish date" do
      datepicker.set_due_date ""

      datepicker.expect_start_date "2025-04-08", disabled: true
      datepicker.expect_due_date "", disabled: false
      datepicker.expect_duration ""
    end
  end

  describe "when switching to manual" do
    before do
      datepicker.click_manual_scheduling_mode

      datepicker.expect_manual_scheduling_mode
      datepicker.expect_start_date "2025-04-08", disabled: false
      datepicker.expect_due_date "2025-04-17", disabled: false
      datepicker.expect_duration "8"

      datepicker.focus_due_date
    end

    describe "and changing the finish date (scenario 8)" do
      it "keeps the finish date and calculates the duration" do
        datepicker.set_due_date "2025-04-23"

        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-23", disabled: false
        datepicker.expect_duration "12"
      end
    end

    describe "and changing the start date to the past and switching back to automatic (scenario 9)" do
      it "resets the start date" do
        datepicker.focus_start_date
        datepicker.set_date "2025-04-02"

        datepicker.expect_start_date "2025-04-02", disabled: false
        datepicker.expect_due_date "2025-04-17", disabled: false
        datepicker.expect_duration "12"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-17", disabled: false
        datepicker.expect_duration "8"
      end
    end

    describe "and changing the start date to the future and switching back to automatic (scenario 10)" do
      it "resets the start date" do
        datepicker.focus_start_date
        datepicker.set_date "2025-04-14"

        datepicker.expect_start_date "2025-04-14", disabled: false
        datepicker.expect_due_date "2025-04-17", disabled: false
        datepicker.expect_duration "4"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-17", disabled: false
        datepicker.expect_duration "8"
      end
    end

    describe "and changing new start and finish date (both before constraint) and switching back to automatic (scenario 11)" do
      it "resets the start date and throws an error for the finish date" do
        datepicker.focus_start_date
        datepicker.set_date "2025-04-01"

        datepicker.expect_start_date "2025-04-01", disabled: false
        datepicker.expect_due_date "2025-04-17", disabled: false
        datepicker.expect_duration "13"

        datepicker.focus_due_date
        datepicker.set_date "2025-04-07"

        datepicker.expect_start_date "2025-04-01", disabled: false
        datepicker.expect_due_date "2025-04-07", disabled: false
        datepicker.expect_duration "5"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-07", disabled: false
        datepicker.expect_duration "0"

        datepicker.expect_due_date_error(
          I18n.t("activerecord.errors.models.work_package.attributes.start_date.violates_relationships",
                 soonest_start: "2025-04-08").capitalize
        )
        datepicker.expect_duration_error "Must be greater than 0."
      end
    end

    describe "and changing new start (before constraint) and finish date (after constraint),
              switching back to automatic (scenario 12)" do
      it "resets the start date and preserves the finish date" do
        datepicker.focus_start_date
        datepicker.set_date "2025-04-01"

        datepicker.expect_start_date "2025-04-01", disabled: false
        datepicker.expect_due_date "2025-04-17", disabled: false
        datepicker.expect_duration "13"

        datepicker.focus_due_date
        datepicker.set_date "2025-04-24"

        datepicker.expect_start_date "2025-04-01", disabled: false
        datepicker.expect_due_date "2025-04-24", disabled: false
        datepicker.expect_duration "18"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-24", disabled: false
        datepicker.expect_duration "13"
      end
    end

    describe "and changing duration (start date unmodified) switching back to automatic (scenario 13a)" do
      it "preserves the duration" do
        datepicker.set_duration "14"

        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "14"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "14"
      end
    end

    describe "and changing duration and start date, switching back to automatic (scenario 13b)" do
      it "preserves the duration and resets the start date" do
        datepicker.set_duration "14"

        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "14"

        datepicker.focus_start_date
        datepicker.set_date "2025-04-04"

        datepicker.expect_start_date "2025-04-04", disabled: false
        datepicker.expect_due_date "2025-04-23", disabled: false
        datepicker.expect_duration "14"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "14"
      end
    end

    describe "and change duration and non-working days, switching back to automatic (scenario 14a)" do
      it "preserves the duration date" do
        datepicker.set_duration "14"

        datepicker.expect_working_days_only(true)
        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "14"

        datepicker.toggle_working_days_only

        datepicker.expect_working_days_only(false)
        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-21", disabled: false
        datepicker.expect_duration "14"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_working_days_only(false)
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-21", disabled: false
        datepicker.expect_duration "14"
      end
    end

    describe "and change finish and non-working days, switching back to automatic (scenario 14b)" do
      it "preserves the finish date" do
        datepicker.set_date "2025-04-25"

        datepicker.expect_working_days_only(true)
        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "14"

        datepicker.toggle_working_days_only

        datepicker.expect_working_days_only(false)
        datepicker.expect_start_date "2025-04-08", disabled: false
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "18"

        datepicker.click_automatic_scheduling_mode

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_working_days_only(false)
        datepicker.expect_start_date "2025-04-08", disabled: true
        datepicker.expect_due_date "2025-04-25", disabled: false
        datepicker.expect_duration "18"
      end
    end
  end
end
