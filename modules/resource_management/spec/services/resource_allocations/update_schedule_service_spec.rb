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
require_relative "../../support/resource_allocations/schedule_helpers"

RSpec.describe ResourceAllocations::UpdateScheduleService do
  include ResourceAllocations::ScheduleHelpers

  let(:user) { create(:user) }
  let(:monday) { Date.new(2026, 1, 5) }
  let(:wednesday) { Date.new(2026, 1, 7) }
  let(:thursday) { Date.new(2026, 1, 8) }
  let(:friday) { Date.new(2026, 1, 9) }
  let(:next_monday) { Date.new(2026, 1, 12) }
  let(:next_thursday) { Date.new(2026, 1, 15) }
  let(:next_friday) { Date.new(2026, 1, 16) }

  before do
    create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1))
  end

  def update_schedule(users: [user], from: nil)
    described_class.new.call(users:, from:)
  end

  def add_without_rebuild(**)
    build(:resource_allocation, principal: user, **).tap(&:save!)
  end

  def entry_ids(user)
    ResourceAllocations::ScheduledEntry
      .where(user:)
      .pluck(:resource_allocation_id, :allocated_on, :id)
      .to_h { |allocation_id, allocated_on, id| [[allocation_id, allocated_on], id] }
  end

  describe "a full rebuild" do
    it "stores the schedule computed over all of the user's allocations" do
      create(:resource_allocation, principal: user, start_date: monday, end_date: friday, allocated_time: 1500)
      create(:resource_allocation, principal: user, start_date: wednesday, end_date: next_friday, allocated_time: 3000)
      create(:resource_allocation, principal: user, start_date: thursday, end_date: friday, allocated_time: 1200)

      update_schedule

      expect(stored_schedule(user)).not_to be_empty
      expect(stored_schedule(user)).to match_array(computed_schedule(user))
    end

    it "removes the entries of a user left without allocated allocations" do
      allocation = create(:resource_allocation, principal: user)
      update_schedule
      allocation.update_column(:state, "canceled")

      update_schedule

      expect(stored_schedule(user)).to be_empty
    end
  end

  describe "resuming from a date" do
    let!(:early) do
      create(:resource_allocation, principal: user, start_date: monday, end_date: friday, allocated_time: 2000)
    end
    let!(:running) do
      create(:resource_allocation, principal: user, start_date: wednesday, end_date: next_friday, allocated_time: 2400)
    end

    before { update_schedule }

    it "matches a full rebuild after adding an allocation" do
      add_without_rebuild(start_date: thursday, end_date: friday, allocated_time: 960)

      update_schedule(from: thursday)

      expect(stored_schedule(user)).to match_array(computed_schedule(user))
    end

    it "matches a full rebuild after changing an allocation" do
      running.update!(start_date: thursday, allocated_time: 3000)

      update_schedule(from: wednesday)

      expect(stored_schedule(user)).to match_array(computed_schedule(user))
    end

    it "matches a full rebuild after removing an allocation" do
      running.update_column(:state, "canceled")

      update_schedule(from: running.start_date)

      expect(stored_schedule(user)).to match_array(computed_schedule(user))
      expect(stored_schedule(user).pluck(:allocation_id)).to all(eq(early.id))
    end

    it "writes only the entries that change, in place" do
      added = add_without_rebuild(start_date: next_thursday, end_date: next_thursday, allocated_time: 240)
      ids_before = entry_ids(user)
      allow(ResourceAllocations::ScheduledEntry).to receive(:upsert_all).and_call_original

      update_schedule(from: next_thursday)

      expect(ResourceAllocations::ScheduledEntry).to have_received(:upsert_all).once do |rows, **|
        expect(rows.map { |row| [row[:resource_allocation_id], row[:allocated_on]] })
          .to contain_exactly([added.id, next_thursday], [running.id, next_thursday], [running.id, next_friday])
      end
      expect(entry_ids(user).slice(*ids_before.keys)).to eq(ids_before)
      expect(stored_schedule(user)).to match_array(computed_schedule(user))
    end

    it "writes nothing when the schedule did not change" do
      ids_before = entry_ids(user)
      allow(ResourceAllocations::ScheduledEntry).to receive(:upsert_all)

      update_schedule

      expect(ResourceAllocations::ScheduledEntry).not_to have_received(:upsert_all)
      expect(entry_ids(user)).to eq(ids_before)
    end
  end

  it "updates the overtime before the date of an allocation still running on it" do
    long = create(:resource_allocation, principal: user, start_date: monday, end_date: friday, allocated_time: 2400)
    update_schedule
    add_without_rebuild(start_date: thursday, end_date: thursday, allocated_time: 480)

    update_schedule(from: thursday)

    expect(stored_schedule(user)).to match_array(computed_schedule(user))
    expect(stored_schedule(user)).to include(
      { allocation_id: long.id, allocated_on: monday, minutes: 480 + 96, overtime_minutes: 96 }
    )
  end

  context "when an allocation moves to another principal" do
    let(:other_user) { create(:user) }

    before do
      create(:user_working_hours, user: other_user, valid_from: Date.new(2025, 1, 1))
    end

    it "moves its entries to the new principal" do
      create(:resource_allocation, principal: user, start_date: monday, end_date: friday, allocated_time: 960)
      moving = create(:resource_allocation, principal: user, start_date: monday, end_date: friday, allocated_time: 1920)
      update_schedule
      moving.update!(principal: other_user)

      update_schedule(users: [user, other_user], from: monday)

      expect(stored_schedule(user)).to match_array(computed_schedule(user))
      expect(stored_schedule(other_user)).to match_array(computed_schedule(other_user))
      expect(stored_schedule(other_user).pluck(:allocation_id)).to all(eq(moving.id))
    end
  end
end
