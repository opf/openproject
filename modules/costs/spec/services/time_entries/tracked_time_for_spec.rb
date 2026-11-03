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

RSpec.describe TimeEntries::TrackedTimeFor do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) { create(:user) }
  shared_let(:monday) { Date.new(2026, 1, 5) }
  shared_let(:tuesday) { Date.new(2026, 1, 6) }
  shared_let(:friday) { Date.new(2026, 1, 9) }

  let(:dates) { monday..friday }

  subject(:tracked_time) { described_class.new(user:, dates:) }

  def track(spent_on:, user: self.user, entity: work_package, **)
    create(:time_entry, user:, entity:, spent_on:, **)
  end

  describe "#items" do
    it "returns the user's time entries within the dates, in the order they were tracked" do
      later_on_monday = track(spent_on: monday, start_time: 600)
      tuesday_entry = track(spent_on: tuesday)
      earlier_on_monday = track(spent_on: monday, start_time: 480)

      expect(tracked_time.items).to eq([earlier_on_monday, later_on_monday, tuesday_entry])
    end

    it "leaves out entries outside the dates" do
      track(spent_on: friday + 1)

      expect(tracked_time.items).to be_empty
    end

    it "leaves out entries of other users" do
      track(spent_on: monday, user: create(:user))

      expect(tracked_time.items).to be_empty
    end

    it "leaves out entries in projects the user can no longer see" do
      track(spent_on: monday, entity: create(:work_package, project: create(:project, active: false)))

      expect(tracked_time.items).to be_empty
    end
  end

  describe "#events" do
    it "returns a calendar event for each time entry" do
      time_entry = track(spent_on: monday)

      expect(tracked_time.events).to contain_exactly(
        an_instance_of(FullCalendar::TimeEntryEvent).and(have_attributes(time_entry:))
      )
    end
  end
end
