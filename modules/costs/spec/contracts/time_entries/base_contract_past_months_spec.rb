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

RSpec.describe TimeEntries::BaseContract, "prohibiting logging for past months" do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:activity) { create(:time_entry_activity) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages log_time edit_time_entries] })
  end

  # Derived from the real current date rather than a frozen one: freezing the clock makes
  # two journals share a timestamp, which Postgres rejects as an empty validity period.
  let(:today) { Date.current }
  let(:first_of_this_month) { Date.current.beginning_of_month }
  let(:last_day_of_last_month) { Date.current.beginning_of_month - 1.day }
  let(:first_day_of_last_month) { last_day_of_last_month.beginning_of_month }

  def log_time(spent_on)
    TimeEntries::CreateService
      .new(user:)
      .call(project:, entity: work_package, user:, activity_id: activity.id, spent_on:, hours: 1)
  end

  def existing_entry(spent_on:)
    create(:time_entry, project:, entity: work_package, user:, activity:, spent_on:, hours: 1)
  end

  def expect_rejected(call)
    expect(call).to be_failure
    expect(call.errors.symbols_for(:spent_on)).to contain_exactly(:in_past_month)
  end

  context "with the restriction enabled",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_prohibit_logging_for_past_months: true } do
    it "allows logging for the current month" do
      expect(log_time(today)).to be_success
      expect(log_time(first_of_this_month)).to be_success
    end

    it "rejects logging for the very last day of the previous month" do
      expect_rejected(log_time(last_day_of_last_month))
    end

    it "rejects logging for an earlier past month" do
      expect_rejected(log_time(first_day_of_last_month))
    end

    it "allows editing an entry within the current month" do
      time_entry = existing_entry(spent_on: first_of_this_month)
      call = TimeEntries::UpdateService.new(model: time_entry, user:).call(hours: 3)

      expect(call).to be_success
    end

    it "rejects editing an entry that lies in a past month" do
      time_entry = existing_entry(spent_on: last_day_of_last_month)
      call = TimeEntries::UpdateService.new(model: time_entry, user:).call(hours: 3)

      expect_rejected(call)
    end

    it "rejects moving an entry out of a past month into the current one" do
      time_entry = existing_entry(spent_on: last_day_of_last_month)
      call = TimeEntries::UpdateService.new(model: time_entry, user:).call(spent_on: today)

      expect_rejected(call)
    end

    it "rejects moving an entry from the current month into a past one" do
      time_entry = existing_entry(spent_on: first_of_this_month)
      call = TimeEntries::UpdateService.new(model: time_entry, user:).call(spent_on: last_day_of_last_month)

      expect_rejected(call)
    end

    it "allows deleting an entry within the current month" do
      time_entry = existing_entry(spent_on: first_of_this_month)
      call = TimeEntries::DeleteService.new(model: time_entry, user:).call

      expect(call).to be_success
      expect { time_entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "rejects deleting an entry that lies in a past month" do
      time_entry = existing_entry(spent_on: last_day_of_last_month)
      call = TimeEntries::DeleteService.new(model: time_entry, user:).call

      expect_rejected(call)
      expect(time_entry.reload).to be_present
    end
  end

  context "with a grace period of 5 days",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_prohibit_logging_for_past_months: true,
                           time_entries_past_month_grace_days: 5 } do
    # Evaluated inside the before hook, so still relative to the real date.
    let(:next_month) { Date.current.next_month.beginning_of_month }

    # Evaluated inside the examples, so relative to the date travelled to.
    let(:month_that_just_ended) { Date.current.prev_month.beginning_of_month }
    let(:an_earlier_month) { Date.current.prev_month.prev_month.beginning_of_month }

    context "when still within the grace period" do
      before { travel_to(next_month + 3) }

      it "allows logging for the month that just ended" do
        expect(log_time(month_that_just_ended)).to be_success
      end

      it "still rejects logging for an earlier month" do
        expect_rejected(log_time(an_earlier_month))
      end
    end

    context "on the last day of the grace period" do
      before { travel_to(next_month + 4) }

      it "allows logging for the month that just ended" do
        expect(log_time(month_that_just_ended)).to be_success
      end
    end

    context "when the grace period has passed" do
      before { travel_to(next_month + 5) }

      it "rejects logging for the month that just ended" do
        expect_rejected(log_time(month_that_just_ended))
      end
    end
  end

  context "with the restriction disabled",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_prohibit_logging_for_past_months: false } do
    it "allows logging for a past month" do
      expect(log_time(last_day_of_last_month)).to be_success
    end
  end

  context "without an Enterprise token",
          with_settings: { time_entries_prohibit_logging_for_past_months: true } do
    it "allows logging for a past month" do
      expect(log_time(last_day_of_last_month)).to be_success
    end
  end
end
