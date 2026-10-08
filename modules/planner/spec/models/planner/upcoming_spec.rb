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

RSpec.describe Planner::Upcoming, with_settings: { working_days: [1, 2, 3, 4, 5] } do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:meeting_project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:user) { create(:user, member_with_permissions: { meeting_project => %i[view_meetings] }) }
  let(:project) { Planner::ProjectService.new(user).call.result }

  subject(:upcoming) { described_class.new(user:, project:) }

  # Wednesday
  around { |example| travel_to(Time.zone.parse("2026-10-07 08:00")) { example.run } }

  def day(date) = upcoming.days.find { it.date == date }

  it "covers the next week's working days, starting tomorrow" do
    expect(upcoming.days.map(&:date))
      .to eq([Date.new(2026, 10, 8), Date.new(2026, 10, 9), Date.new(2026, 10, 12), Date.new(2026, 10, 13),
              Date.new(2026, 10, 14)])
  end

  it "puts tasks on their day" do
    thursday = create(:work_package, project:, type: task, subject: "Thursday", due_date: Date.new(2026, 10, 8))
    create(:work_package, project:, type: task, subject: "Today", due_date: Date.new(2026, 10, 7))

    expect(day(Date.new(2026, 10, 8)).work_packages).to contain_exactly(thursday)
    expect(upcoming.days.flat_map(&:work_packages)).to contain_exactly(thursday)
  end

  describe "meetings" do
    let!(:series) do
      create(:recurring_meeting, project: meeting_project, author: user, title: "Daily",
                                 start_time: Time.zone.parse("2026-10-07 09:30"), frequency: "working_days",
                                 end_after: "never")
    end
    let!(:thursday_occurrence) do
      create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: Time.zone.parse("2026-10-08 09:30"),
                                            participants: [build(:meeting_participant, user:)])
    end
    let!(:cancelled_friday) do
      create(:recurring_meeting_occurrence, :cancelled, recurring_meeting: series,
                                                        start_time: Time.zone.parse("2026-10-09 09:30"))
    end

    it "lists created occurrences once and scheduled ones from the series" do
      thursday = day(Date.new(2026, 10, 8)).meetings
      expect(thursday.map(&:meeting)).to eq([thursday_occurrence])

      monday = day(Date.new(2026, 10, 12)).meetings
      expect(monday.map { [it.title, it.series, it.start_time] }).to eq([["Daily", series, Time.zone.parse("2026-10-12 09:30")]])
    end

    it "leaves out cancelled occurrences" do
      expect(day(Date.new(2026, 10, 9)).meetings).to be_empty
    end
  end
end
