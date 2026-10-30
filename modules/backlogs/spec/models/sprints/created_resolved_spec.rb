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

RSpec.describe Sprints::CreatedResolved do
  subject(:created_resolved) { described_class.new(sprint:, project:) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:open_status) { create(:status, name: "Open", is_default: true) }
  shared_let(:closed_status) { create(:status, name: "Closed", is_closed: true) }
  shared_let(:done_status) { create(:status, name: "Delivered") }

  let(:first_monday) { Date.new(2026, 10, 12) }
  let(:first_tuesday) { Date.new(2026, 10, 13) }
  let(:first_wednesday) { Date.new(2026, 10, 14) }
  let(:second_friday) { Date.new(2026, 10, 23) }

  let(:sprint_start) { at_hour(first_monday, 9) }
  let(:now) { at_hour(first_wednesday, 12) }

  let(:started_at) { sprint_start }
  let(:finish_date) { second_friday }

  let(:sprint) do
    create(:sprint, project:, start_date: first_monday, finish_date:, started_at:)
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  def at_hour(date, hour)
    date.in_time_zone + hour.hours
  end

  # In the sprint from +from+ onwards. Anything journalled, such as a status_id, rides along.
  def counted(from, **journal)
    create(:work_package, project:, sprint:, status: open_status,
                          journals: { from => { subject: "Counted", **journal } })
  end

  def values_at(series, instant)
    series.find { it.at == instant }&.value
  end

  before { week_with_saturday_and_sunday_as_weekend }

  around do |example|
    travel_to(now) { example.run }
  end

  describe "#created" do
    it "counts every work package the sprint held, whatever its status" do
      counted(sprint_start)
      counted(sprint_start, status_id: closed_status.id)

      expect(created_resolved.created.first.value).to eq 2.0
    end

    it "stops at the current time rather than the sprint's finish date" do
      counted(sprint_start)

      expect(created_resolved.created.last.at).to eq now
    end

    # Membership is historic: the journals carry the sprint the work package was in at the time.
    it "picks a work package up from the moment it joined the sprint" do
      counted(sprint_start)
      counted(at_hour(first_tuesday, 15))

      expect(values_at(created_resolved.created, sprint_start)).to eq 1.0
      expect(created_resolved.created.last.value).to eq 2.0
    end

    context "when the sprint has not started yet" do
      let(:started_at) { nil }
      let(:now) { at_hour(first_monday - 7.days, 12) }

      it { expect(created_resolved.created).to be_empty }
    end
  end

  describe "#resolved" do
    it "counts only what the project considers done" do
      counted(sprint_start)
      counted(sprint_start, status_id: closed_status.id)

      expect(created_resolved.resolved.first.value).to eq 1.0
    end

    # A status the project nominated counts even though it is not closed globally.
    it "counts a status the project configured as done" do
      project.done_statuses << done_status
      counted(sprint_start, status_id: done_status.id)

      expect(created_resolved.resolved.first.value).to eq 1.0
    end

    it "never exceeds created" do
      counted(sprint_start)
      counted(sprint_start, status_id: closed_status.id)

      pairs = created_resolved.created.zip(created_resolved.resolved)

      expect(pairs).to all(satisfy { |created, resolved| resolved.value <= created.value })
    end

    context "when the sprint has not started yet" do
      let(:started_at) { nil }
      let(:now) { at_hour(first_monday - 7.days, 12) }

      it { expect(created_resolved.resolved).to be_empty }
    end
  end

  # The chart matches the two series by index, which only holds while they share their instants.
  it "samples both series at the very same instants" do
    counted(sprint_start)

    expect(created_resolved.created.map(&:at)).to eq created_resolved.resolved.map(&:at)
  end

  describe "#step" do
    it "samples hourly over a sprint short enough to render that way" do
      expect(created_resolved.step).to eq :hour
    end

    context "with a sprint running longer than a month" do
      let(:finish_date) { first_monday + 60.days }

      it { expect(created_resolved.step).to eq :day }
    end
  end

  describe "#too_long_to_chart?" do
    context "with a sprint running longer than a year" do
      let(:finish_date) { first_monday + 1.year + 1.day }

      it "draws nothing rather than a series nobody could read" do
        counted(sprint_start)

        expect(created_resolved).to be_too_long_to_chart
        expect(created_resolved.created).to be_empty
        expect(created_resolved.resolved).to be_empty
        expect(created_resolved.non_working_intervals).to be_empty
      end
    end
  end

  describe "visibility" do
    let(:other_user) { create(:user) }

    subject(:created_resolved) { described_class.new(sprint:, project:, user: other_user) }

    # The count follows the user it was given rather than whoever happens to be current.
    it "leaves out work the given user may not see" do
      counted(sprint_start)

      expect(created_resolved.created.map(&:value).uniq).to eq [0.0]
    end
  end
end
