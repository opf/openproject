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

  shared_let(:completed_sprint) do
    create(:sprint, project:, status: :completed,
                    name: "Completed sprint",
                    start_date: Date.new(2025, 8, 1),
                    finish_date: Date.new(2025, 8, 31))
  end
  shared_let(:planned_sprint) do
    create(:sprint, project:, status: :in_planning,
                    name: "Planned sprint",
                    start_date: Date.new(2025, 9, 11),
                    finish_date: Date.new(2025, 9, 20))
  end
  shared_let(:active_sprint) do
    create(:sprint, project:, status: :active,
                    name: "Active sprint",
                    start_date: Date.new(2025, 9, 1),
                    finish_date: Date.new(2025, 9, 10))
  end
  shared_let(:no_dates_sprint) do
    create(:sprint, project:, status: :in_planning,
                    name: "No dates sprint",
                    start_date: nil,
                    finish_date: nil)
  end

  it "orders sprints chronologically by start_date, regardless of status" do
    expect(Sprint.order_by_date).to eq([completed_sprint, active_sprint, planned_sprint, no_dates_sprint])
  end

  it "prefers the actual start over the planned start date" do
    started_late = create(:sprint, project:, name: "Started late", status: :completed,
                                   start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 31),
                                   started_at: Time.zone.local(2025, 10, 20, 9))
    planned_between = create(:sprint, project:, name: "Planned between",
                                      start_date: Date.new(2025, 10, 10), finish_date: Date.new(2025, 10, 31))

    expect(Sprint.order_by_date.where(id: [started_late, planned_between])).to eq([planned_between, started_late])
  end

  it "prefers the actual completion over the planned finish date when the starts are equal" do
    completed_early = create(:sprint, project:, name: "Completed early", status: :completed,
                                      start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 31),
                                      completed_at: Time.zone.local(2025, 10, 5, 17))
    planned_shorter = create(:sprint, project:, name: "Planned shorter",
                                      start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 10))

    expect(Sprint.order_by_date.where(id: [planned_shorter, completed_early])).to eq([completed_early, planned_shorter])
  end

  it "breaks ties in start_date by finish_date ascending" do
    longer = create(:sprint, project:, name: "Longer",
                             start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 20))
    shorter = create(:sprint, project:, name: "Shorter",
                              start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 10))

    expect(Sprint.order_by_date.where(id: [longer, shorter])).to eq([shorter, longer])
  end

  it "breaks ties within the same dates by name ascending" do
    sprint_b = create(:sprint, project:, name: "Sprint B",
                               start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 10))
    sprint_a = create(:sprint, project:, name: "Sprint A",
                               start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 10))

    expect(Sprint.order_by_date.where(id: [sprint_a, sprint_b])).to eq([sprint_a, sprint_b])
  end

  it "breaks ties within the same dates and name by id ascending" do
    duplicate_a = create(:sprint, project:, name: "Duplicate",
                                  start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 10))
    duplicate_b = create(:sprint, project:, name: "Duplicate",
                                  start_date: Date.new(2025, 10, 1), finish_date: Date.new(2025, 10, 10))

    expect(Sprint.order_by_date.where(id: [duplicate_b, duplicate_a])).to eq([duplicate_a, duplicate_b])
  end
end
