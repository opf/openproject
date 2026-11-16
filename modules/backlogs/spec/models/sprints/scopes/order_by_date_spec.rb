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

RSpec.describe Sprints::Scopes::OrderByDate do
  shared_let(:project) { create(:project) }

  shared_let(:august_sprint) do
    create(:sprint, project:, name: "August sprint",
                    start_date: Date.new(2025, 8, 1), finish_date: Date.new(2025, 8, 31))
  end
  shared_let(:early_september_sprint) do
    create(:sprint, project:, name: "Early September sprint",
                    start_date: Date.new(2025, 9, 1), finish_date: Date.new(2025, 9, 10))
  end
  shared_let(:late_september_sprint) do
    create(:sprint, project:, name: "Late September sprint",
                    start_date: Date.new(2025, 9, 11), finish_date: Date.new(2025, 9, 20))
  end
  shared_let(:no_dates_sprint) do
    create(:sprint, project:, name: "No dates sprint", start_date: nil, finish_date: nil)
  end

  it "orders sprints by start_date, placing those without dates last" do
    expect(Sprint.order_by_date)
      .to eq([august_sprint, early_september_sprint, late_september_sprint, no_dates_sprint])
  end

  it "can be reversed" do
    expect(Sprint.order_by_date.last).to eq(no_dates_sprint)
  end

  describe "sprints compared with each other" do
    let(:day) { Date.new(2025, 10, 1) }

    def at(date, hour) = date.in_time_zone + hour.hours

    it "prefers the actual start over the planned start date" do
      started_late = create(:sprint, project:, name: "Started late",
                                     start_date: day, finish_date: day + 30.days,
                                     started_at: at(day + 19.days, 9))
      started_between = create(:sprint, project:, name: "Started between",
                                        start_date: day + 9.days, finish_date: day + 30.days,
                                        started_at: at(day + 9.days, 9))

      expect(Sprint.order_by_date.where(id: [started_late, started_between])).to eq([started_between, started_late])
    end

    it "orders overlapping sprints by their actual start, even if the earlier one completed later" do
      long_running = create(:sprint, project:, name: "Long running",
                                     start_date: day, finish_date: day + 30.days,
                                     started_at: at(day, 9), completed_at: at(day + 30.days, 17))
      short_in_between = create(:sprint, project:, name: "Short in between",
                                         start_date: day + 9.days, finish_date: day + 14.days,
                                         started_at: at(day + 9.days, 9), completed_at: at(day + 14.days, 17))

      expect(Sprint.order_by_date.where(id: [short_in_between, long_running])).to eq([long_running, short_in_between])
    end

    it "places sprints with an actual start before those without, even if the latter are planned to start earlier" do
      started_late = create(:sprint, project:, name: "Started late",
                                     start_date: day, finish_date: day + 5.days,
                                     started_at: at(day + 11.days, 12))
      planned_next = create(:sprint, project:, name: "Planned next",
                                     start_date: day + 11.days, finish_date: day + 18.days)

      expect(Sprint.order_by_date.where(id: [planned_next, started_late])).to eq([started_late, planned_next])
    end

    it "prefers the actual completion over the planned finish date when the starts are equal" do
      completed_early = create(:sprint, project:, name: "Completed early",
                                        start_date: day, finish_date: day + 30.days,
                                        completed_at: at(day + 4.days, 17))
      planned_shorter = create(:sprint, project:, name: "Planned shorter",
                                        start_date: day, finish_date: day + 9.days)

      expect(Sprint.order_by_date.where(id: [planned_shorter, completed_early])).to eq([completed_early, planned_shorter])
    end

    it "breaks ties in start_date by finish_date ascending" do
      longer = create(:sprint, project:, name: "Longer", start_date: day, finish_date: day + 19.days)
      shorter = create(:sprint, project:, name: "Shorter", start_date: day, finish_date: day + 9.days)

      expect(Sprint.order_by_date.where(id: [longer, shorter])).to eq([shorter, longer])
    end

    it "breaks ties within the same dates by name ascending" do
      sprint_b = create(:sprint, project:, name: "Sprint B", start_date: day, finish_date: day + 9.days)
      sprint_a = create(:sprint, project:, name: "Sprint A", start_date: day, finish_date: day + 9.days)

      expect(Sprint.order_by_date.where(id: [sprint_a, sprint_b])).to eq([sprint_a, sprint_b])
    end

    it "breaks ties within the same dates and name by id ascending" do
      duplicate_a = create(:sprint, project:, name: "Duplicate", start_date: day, finish_date: day + 9.days)
      duplicate_b = create(:sprint, project:, name: "Duplicate", start_date: day, finish_date: day + 9.days)

      expect(Sprint.order_by_date.where(id: [duplicate_b, duplicate_a])).to eq([duplicate_a, duplicate_b])
    end
  end
end
