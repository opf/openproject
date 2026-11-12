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

RSpec.describe "Datepicker logic on parents", :js, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  # assume sat+sun are non working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  shared_let(:type) { create(:type_bug) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:parent) { create(:work_package, type:, project:) }
  shared_let(:child) { create(:work_package, type:, project:, parent:) }

  let(:work_packages_page) { Pages::FullWorkPackage.new(parent) }
  let(:date_field) { work_packages_page.edit_field(:combinedDate) }
  let(:datepicker) { date_field.datepicker }

  let(:parent_attributes) { {} }
  let(:child_attributes) { {} }

  before do
    parent.update!(parent_attributes)
    child.update!(child_attributes)

    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded

    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  context "with the child having set dates and the parent being scheduled automatically" do
    let(:child_attributes) do
      {
        start_date: "2021-02-01",
        due_date: "2021-02-02",
        duration: 2,
        ignore_non_working_days: true
      }
    end

    context "when the parent is scheduled automatically" do
      let(:parent_attributes) do
        {
          schedule_manually: false
        }
      end

      it "disables the non-working days options" do
        datepicker.expect_working_days_only_disabled
        datepicker.expect_automatic_scheduling_mode

        first_monday = Time.zone.today.beginning_of_month.next_occurring(:monday)
        datepicker.expect_disabled(first_monday)

        datepicker.toggle_scheduling_mode
        datepicker.expect_manual_scheduling_mode

        datepicker.expect_not_disabled(first_monday)
      end
    end

    context "when the parent is scheduled manually" do
      let(:parent_attributes) do
        {
          schedule_manually: true
        }
      end

      it "enables the non-working days options" do
        datepicker.expect_working_days_only_enabled
        datepicker.expect_manual_scheduling_mode

        first_monday = Time.zone.today.beginning_of_month.next_occurring(:monday)
        datepicker.expect_not_disabled(first_monday)

        datepicker.toggle_scheduling_mode
        datepicker.expect_automatic_scheduling_mode

        # In automatic mode, the dates are set by the children.
        # Therefore, the calendar sheets also show the start_date of the child first
        first_monday = Time.zone.parse(child_attributes[:start_date]).beginning_of_month.next_occurring(:monday)
        datepicker.expect_disabled(first_monday)
      end
    end

    context "when the parent is switched to manual, and dates are cleared, " \
            "and scheduling mode is switched back to automatic" do
      let(:parent_attributes) do
        # parent inherits from child attributes
        child_attributes.merge(schedule_manually: false)
      end

      it "shows the inherited dates and duration of the child in the date picker" do
        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date child_attributes[:start_date], disabled: true
        datepicker.expect_due_date child_attributes[:due_date], disabled: true
        datepicker.expect_duration child_attributes[:duration], disabled: true

        datepicker.toggle_scheduling_mode
        datepicker.wait_for_preview_update
        datepicker.expect_manual_scheduling_mode
        datepicker.set_start_date ""
        datepicker.set_due_date ""
        datepicker.expect_duration ""

        datepicker.toggle_scheduling_mode
        datepicker.wait_for_preview_update
        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date child_attributes[:start_date], disabled: true
        datepicker.expect_due_date child_attributes[:due_date], disabled: true
        datepicker.expect_duration child_attributes[:duration], disabled: true
      end
    end
  end
end
