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

RSpec.describe "Datepicker logic on follow relationships", :js, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  shared_let(:type) { create(:type_bug) }
  shared_let(:milestone_type) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [milestone_type]) }
  shared_let(:predecessor) do
    create(:work_package,
           type:,
           project:,
           start_date: Date.parse("2024-02-02"),
           due_date: Date.parse("2024-02-02"))
  end
  # assume sat+sun are non-working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  let(:work_packages_page) { Pages::FullWorkPackage.new(follower) }
  let(:datepicker) { date_field.datepicker }

  before do
    login_as(user)
    relation

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded

    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  for_each_context "with default browser timezone",
                   "with a negative browser timezone (New York)" do
    context "if the follower is a task" do
      let!(:follower) do
        create(:work_package,
               type:,
               project:,
               schedule_manually: false,
               start_date: Date.parse("2024-02-05"),
               due_date: Date.parse("2024-02-08"))
      end
      let!(:relation) { create(:follows_relation, from: follower, to: predecessor) }
      let(:date_field) { work_packages_page.edit_field(:combinedDate) }

      it "keeps the minimum dates disabled" do
        datepicker.expect_working_days_only true
        datepicker.expect_automatic_scheduling_mode

        datepicker.show_date "2024-02-01"
        datepicker.expect_disabled Date.parse("2024-02-01")
        datepicker.expect_disabled Date.parse("2024-02-02") # predecessor's due date
        datepicker.expect_disabled Date.parse("2024-02-03") # Saturday is non-working day
        datepicker.expect_disabled Date.parse("2024-02-04") # Sunday is non-working day
        datepicker.expect_not_disabled Date.parse("2024-02-05")
        datepicker.expect_not_disabled Date.parse("2024-02-06")
        datepicker.expect_not_disabled Date.parse("2024-02-07")

        datepicker.toggle_working_days_only
        datepicker.expect_working_days_only false

        datepicker.expect_start_date "2024-02-03", disabled: true
        datepicker.expect_due_date "2024-02-08" # did not change
        datepicker.expect_disabled Date.parse("2024-02-01")
        datepicker.expect_disabled Date.parse("2024-02-02") # predecessor's due date
        datepicker.expect_not_disabled Date.parse("2024-02-03") # Saturday is non-working day but ignored
        datepicker.expect_not_disabled Date.parse("2024-02-04") # Sunday is non-working day but ignored
        datepicker.expect_not_disabled Date.parse("2024-02-05")
        datepicker.expect_not_disabled Date.parse("2024-02-06")
        datepicker.expect_not_disabled Date.parse("2024-02-07")

        datepicker.toggle_working_days_only
        datepicker.expect_working_days_only true

        datepicker.expect_start_date "2024-02-05", disabled: true
        datepicker.expect_due_date "2024-02-08"
        datepicker.expect_disabled Date.parse("2024-02-02") # predecessor's due date
        datepicker.expect_disabled Date.parse("2024-02-03") # Saturday is non-working day
        datepicker.expect_disabled Date.parse("2024-02-04") # Sunday is non-working day
        datepicker.expect_not_disabled Date.parse("2024-02-05")
      end
    end

    context "if the follower is a milestone" do
      let!(:follower) do
        create(:work_package,
               type: milestone_type,
               project:,
               schedule_manually: false,
               start_date: Date.parse("2024-02-05"),
               due_date: Date.parse("2024-02-05"))
      end
      let!(:relation) { create(:follows_relation, from: follower, to: predecessor) }
      let(:date_field) { work_packages_page.edit_field(:date) }

      it "disables the whole date picker" do
        datepicker.expect_working_days_only true
        datepicker.expect_automatic_scheduling_mode

        datepicker.show_date "2024-02-02"
        1.upto(29) do |day|
          datepicker.expect_disabled Date.parse("2024-02-%02d" % day)
        end

        datepicker.toggle_working_days_only
        datepicker.expect_working_days_only false

        datepicker.expect_start_date "2024-02-03", disabled: true
        1.upto(29) do |day|
          datepicker.expect_disabled Date.parse("2024-02-%02d" % day)
        end
      end
    end

    context "if the predecessor has no dates" do
      before_all do
        predecessor.update_column(:start_date, nil)
        predecessor.update_column(:due_date, nil)
      end

      let!(:follower) do
        create(:work_package,
               type:,
               project:,
               schedule_manually: false,
               start_date: nil,
               due_date: nil)
      end
      let!(:relation) { create(:follows_relation, from: follower, to: predecessor) }
      let(:date_field) { work_packages_page.edit_field(:combinedDate) }

      it "disables the start date and can pick any finish date or duration" do
        datepicker.expect_start_date("", disabled: true)
        datepicker.expect_due_date("", disabled: false)
        datepicker.expect_duration("", disabled: false)
        datepicker.expect_working_days_only true
        datepicker.expect_automatic_scheduling_mode

        datepicker.show_date "2024-02-01"
        datepicker.expect_not_disabled Date.parse("2024-02-01")
        datepicker.expect_not_disabled Date.parse("2024-02-02")
        datepicker.expect_disabled Date.parse("2024-02-03") # Saturday is non-working day
        datepicker.expect_disabled Date.parse("2024-02-04") # Sunday is non-working day
        datepicker.expect_not_disabled Date.parse("2024-02-05")
        datepicker.expect_not_disabled Date.parse("2024-02-06")
        datepicker.expect_not_disabled Date.parse("2024-02-07")

        datepicker.set_date "2024-02-14"
        # dates before and after the selected date are still selectable
        datepicker.expect_not_disabled Date.parse("2024-02-01")
        datepicker.expect_not_disabled Date.parse("2024-02-02")
        datepicker.expect_not_disabled Date.parse("2024-02-13")
        datepicker.expect_not_disabled Date.parse("2024-02-14")
        datepicker.expect_not_disabled Date.parse("2024-02-15")
        datepicker.expect_not_disabled Date.parse("2024-02-28")
        datepicker.expect_not_disabled Date.parse("2024-02-29")

        # duration can be set, but it will remove the finish date as start date can't be set
        datepicker.set_duration 3
        datepicker.expect_due_date ""
        datepicker.expect_duration "3"

        # and setting finish date removes the duration too for the same reason
        datepicker.set_due_date "2024-02-14"
        datepicker.expect_due_date "2024-02-14"
        datepicker.expect_duration ""
      end
    end
  end
end
