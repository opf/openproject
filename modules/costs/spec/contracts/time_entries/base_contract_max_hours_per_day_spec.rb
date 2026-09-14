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

RSpec.describe TimeEntries::BaseContract, "maximum hours per day",
               with_ee: %i[time_entry_time_restrictions],
               with_settings: { time_entries_max_hours_per_day: 8 } do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:activity) { create(:time_entry_activity) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages log_time edit_time_entries] })
  end

  let(:spent_on) { Date.new(2026, 8, 3) }

  def log_time(hours:)
    TimeEntries::CreateService
      .new(user:)
      .call(project:, entity: work_package, user:, activity_id: activity.id, spent_on:, hours:)
  end

  def existing_entry(hours:, day: spent_on, logged_for: user)
    create(:time_entry, project:, entity: work_package, user: logged_for, activity:, spent_on: day, hours:)
  end

  describe "creating an entry" do
    before { existing_entry(hours: 6) }

    it "counts the hours already logged on that day" do
      call = log_time(hours: 3)

      expect(call).to be_failure
      expect(call.errors.symbols_for(:hours)).to contain_exactly(:max_hours_per_day_exceeded)
    end

    it "allows an entry that brings the day exactly to the limit" do
      expect(log_time(hours: 2)).to be_success
    end

    it "ignores hours logged on other days" do
      existing_entry(hours: 8, day: spent_on - 1)

      expect(log_time(hours: 2)).to be_success
    end

    it "ignores hours logged by other users" do
      existing_entry(hours: 8, logged_for: create(:user))

      expect(log_time(hours: 2)).to be_success
    end
  end

  describe "updating an entry" do
    let(:time_entry) { existing_entry(hours: 6) }

    def update_hours(hours)
      TimeEntries::UpdateService.new(model: time_entry, user:).call(hours:)
    end

    it "does not count the entry's own persisted hours" do
      expect(update_hours(8)).to be_success
    end

    it "is invalid when the new hours push the day over the limit" do
      existing_entry(hours: 1)
      call = update_hours(8)

      expect(call).to be_failure
      expect(call.errors.symbols_for(:hours)).to contain_exactly(:max_hours_per_day_exceeded)
    end
  end
end
