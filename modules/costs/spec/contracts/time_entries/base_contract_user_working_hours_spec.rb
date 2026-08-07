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

RSpec.describe TimeEntries::BaseContract, "limiting hours to the user's working hours" do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:activity) { create(:time_entry_activity) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages log_time edit_time_entries] })
  end

  let(:monday) { Date.new(2026, 8, 3) }
  let(:friday) { Date.new(2026, 8, 7) }

  def log_time(hours:, spent_on: monday)
    TimeEntries::CreateService
      .new(user:)
      .call(project:, entity: work_package, user:, activity_id: activity.id, spent_on:, hours:)
  end

  def existing_entry(hours:, spent_on: monday)
    create(:time_entry, project:, entity: work_package, user:, activity:, spent_on:, hours:)
  end

  def expect_rejected(call)
    expect(call).to be_failure
    expect(call.errors.symbols_for(:hours)).to contain_exactly(:exceeds_user_working_hours)
  end

  context "with the restriction enabled",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_limit_to_user_working_hours: true } do
    context "when the user has no working hours defined" do
      it "does not restrict logging" do
        expect(log_time(hours: 20)).to be_success
      end
    end

    context "when the user works 8 hours on Monday and 6 on Friday" do
      before do
        create(:user_working_hours,
               user:,
               valid_from: monday - 30,
               monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 360,
               saturday: 0, sunday: 0)
      end

      it "allows logging up to the defined hours" do
        expect(log_time(hours: 8)).to be_success
      end

      it "rejects logging more than the defined hours" do
        expect_rejected(log_time(hours: 9))
      end

      it "counts hours already logged on that day" do
        existing_entry(hours: 6)

        expect_rejected(log_time(hours: 3))
      end

      it "uses the hours defined for that particular week day" do
        expect(log_time(hours: 6, spent_on: friday)).to be_success
        expect_rejected(log_time(hours: 7, spent_on: friday))
      end

      it "rejects any logging on a week day with no defined hours" do
        expect_rejected(log_time(hours: 1, spent_on: monday - 2)) # Saturday
      end

      it "does not count the entry's own persisted hours when updating" do
        time_entry = existing_entry(hours: 6)
        call = TimeEntries::UpdateService.new(model: time_entry, user:).call(hours: 8)

        expect(call).to be_success
      end

      it "reduces the allowance by the availability factor" do
        user.working_hours.sole.update!(availability_factor: 50)

        expect(log_time(hours: 4)).to be_success
        expect_rejected(log_time(hours: 5))
      end
    end

    # 20 minutes is 0.333... hours, so these cases only hold when the comparison is done in
    # whole minutes rather than on the rounded hour values.
    context "when the schedule does not divide evenly into hours" do
      before do
        create(:user_working_hours,
               user:,
               valid_from: monday - 30,
               monday: 20, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
               saturday: 0, sunday: 0)
      end

      it "allows logging exactly the defined minutes" do
        expect(log_time(hours: 20.0 / 60)).to be_success
      end

      it "rejects logging more than the defined minutes" do
        expect_rejected(log_time(hours: 21.0 / 60))
      end
    end

    context "when repeated fractional entries add up to the defined minutes" do
      before do
        create(:user_working_hours,
               user:,
               valid_from: monday - 30,
               monday: 60, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
               saturday: 0, sunday: 0)
        2.times { existing_entry(hours: 20.0 / 60) }
      end

      it "allows the entry that fills the day exactly" do
        expect(log_time(hours: 20.0 / 60)).to be_success
      end

      it "rejects the entry that would exceed the day" do
        expect_rejected(log_time(hours: 21.0 / 60))
      end
    end

    context "when the schedule only becomes valid after the logged date" do
      before do
        create(:user_working_hours, user:, valid_from: monday + 7, monday: 120)
      end

      it "does not restrict logging before the schedule takes effect" do
        expect(log_time(hours: 8)).to be_success
      end
    end

    context "when a newer schedule supersedes an older one" do
      before do
        create(:user_working_hours, user:, valid_from: monday - 30, monday: 480)
        create(:user_working_hours, user:, valid_from: monday - 7, monday: 120)
      end

      it "applies the schedule in effect on the logged date" do
        expect_rejected(log_time(hours: 3))
        expect(log_time(hours: 2)).to be_success
      end
    end
  end

  context "with the restriction disabled",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_limit_to_user_working_hours: false } do
    before { create(:user_working_hours, user:, valid_from: monday - 30, monday: 480) }

    it "does not restrict logging" do
      expect(log_time(hours: 20)).to be_success
    end
  end

  context "without an Enterprise token",
          with_settings: { time_entries_limit_to_user_working_hours: true } do
    before { create(:user_working_hours, user:, valid_from: monday - 30, monday: 480) }

    it "does not restrict logging" do
      expect(log_time(hours: 20)).to be_success
    end
  end
end
