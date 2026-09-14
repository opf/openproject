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

RSpec.describe Sprints::Scopes::OrderByActivity do
  shared_let(:project) { create(:project) }

  shared_let(:active_sprint) do
    create(:sprint, project:, status: :active,
                    name: "Active sprint",
                    start_date: Date.new(2025, 9, 1),
                    finish_date: Date.new(2025, 9, 10))
  end
  shared_let(:in_planning_sprint_later) do
    create(:sprint, project:, status: :in_planning,
                    name: "Later planning sprint",
                    start_date: Date.new(2025, 9, 11),
                    finish_date: Date.new(2025, 9, 20))
  end
  shared_let(:in_planning_sprint_earlier) do
    create(:sprint, project:, status: :in_planning,
                    name: "Earlier planning sprint",
                    start_date: Date.new(2025, 9, 1),
                    finish_date: Date.new(2025, 9, 10))
  end
  shared_let(:in_planning_sprint_no_dates) do
    create(:sprint, project:, status: :in_planning,
                    name: "No dates planning sprint",
                    start_date: nil,
                    finish_date: nil)
  end
  shared_let(:completed_sprint_b) do
    create(:sprint, project:, status: :completed,
                    name: "Completed sprint B",
                    start_date: Date.new(2025, 8, 1),
                    finish_date: Date.new(2025, 8, 31))
  end
  shared_let(:completed_sprint_a) do
    create(:sprint, project:, status: :completed,
                    name: "Completed sprint A",
                    start_date: Date.new(2025, 8, 1),
                    finish_date: Date.new(2025, 8, 31))
  end

  it "orders active first, then in_planning, then completed" do
    expected_order = [
      active_sprint,
      in_planning_sprint_later,
      in_planning_sprint_earlier,
      in_planning_sprint_no_dates,
      completed_sprint_a,
      completed_sprint_b
    ]

    expect(Sprint.order_by_activity).to eq(expected_order)
  end

  it "orders sprints with the same status by start_date descending" do
    expected_order = [
      in_planning_sprint_later,
      in_planning_sprint_earlier,
      in_planning_sprint_no_dates
    ]

    expect(Sprint.order_by_activity.in_planning).to eq(expected_order)
  end

  it "places sprints without dates last within their status group" do
    expect(Sprint.order_by_activity.in_planning.last).to eq(in_planning_sprint_no_dates)
  end

  it "breaks ties within the same status and dates by name ascending" do
    expect(Sprint.order_by_activity.completed).to eq([completed_sprint_a, completed_sprint_b])
  end

  it "breaks ties within the same status, dates, and name by id ascending" do
    duplicate_a = create(:sprint, project:, status: :completed,
                                  name: "Duplicate",
                                  start_date: Date.new(2025, 8, 1),
                                  finish_date: Date.new(2025, 8, 31))
    duplicate_b = create(:sprint, project:, status: :completed,
                                  name: "Duplicate",
                                  start_date: Date.new(2025, 8, 1),
                                  finish_date: Date.new(2025, 8, 31))

    expect(Sprint.order_by_activity).to include(duplicate_a, duplicate_b)
    idx_a = Sprint.order_by_activity.to_a.index(duplicate_a)
    idx_b = Sprint.order_by_activity.to_a.index(duplicate_b)
    expect(idx_a).to be < idx_b
  end
end
