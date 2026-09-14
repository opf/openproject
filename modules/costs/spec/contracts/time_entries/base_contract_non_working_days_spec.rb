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

RSpec.describe TimeEntries::BaseContract, "logging on non-working days" do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:activity) { create(:time_entry_activity) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages log_time edit_time_entries] })
  end

  let(:monday) { Date.new(2026, 8, 3) }
  let(:tuesday) { Date.new(2026, 8, 4) }
  let(:saturday) { Date.new(2026, 8, 1) }

  def log_time(spent_on)
    TimeEntries::CreateService
      .new(user:)
      .call(project:, entity: work_package, user:, activity_id: activity.id, spent_on:, hours: 1)
  end

  def expect_rejected(call)
    expect(call).to be_failure
    expect(call.errors.symbols_for(:spent_on)).to contain_exactly(:not_a_working_day)
  end

  context "with the restriction enabled",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_prohibit_logging_on_non_working_days: true,
                           working_days: [1, 2, 3, 4, 5] } do
    it "allows logging on a working day" do
      expect(log_time(monday)).to be_success
    end

    it "rejects logging on a globally non-working week day" do
      expect_rejected(log_time(saturday))
    end

    it "rejects logging on a global non-working day" do
      create(:non_working_day, date: tuesday)

      expect_rejected(log_time(tuesday))
    end

    it "rejects logging within the user's own non-working times" do
      create(:user_non_working_time, user:, start_date: monday, end_date: tuesday)

      expect_rejected(log_time(tuesday))
    end

    it "ignores non-working times of other users" do
      create(:user_non_working_time, user: create(:user), start_date: monday, end_date: tuesday)

      expect(log_time(tuesday)).to be_success
    end

    it "rejects updating an entry onto a non-working day" do
      time_entry = create(:time_entry, project:, entity: work_package, user:, activity:, spent_on: monday, hours: 1)
      call = TimeEntries::UpdateService.new(model: time_entry, user:).call(spent_on: saturday)

      expect_rejected(call)
    end
  end

  context "with the restriction disabled",
          with_ee: %i[time_entry_time_restrictions],
          with_settings: { time_entries_prohibit_logging_on_non_working_days: false,
                           working_days: [1, 2, 3, 4, 5] } do
    it "allows logging on a globally non-working week day" do
      expect(log_time(saturday)).to be_success
    end
  end

  context "without an Enterprise token",
          with_settings: { time_entries_prohibit_logging_on_non_working_days: true,
                           working_days: [1, 2, 3, 4, 5] } do
    it "allows logging on a globally non-working week day" do
      expect(log_time(saturday)).to be_success
    end
  end
end
