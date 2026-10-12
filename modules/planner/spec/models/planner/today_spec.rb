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

RSpec.describe Planner::Today do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:meeting_project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  let(:user) do
    create(:user,
           preferences: { time_zone: "Europe/Berlin" },
           member_with_permissions: { meeting_project => %i[view_meetings view_work_packages] })
  end
  let(:project) { Planner::ProjectService.new(user).call.result }
  let(:day_part) { WorkPackageCustomField.for_semantic_key(:day_part) }
  let(:options) { day_part.custom_options.order(:position).to_a }
  let(:berlin) { ActiveSupport::TimeZone["Europe/Berlin"] }

  subject(:today) { described_class.new(user:, project:) }

  around { |example| travel_to(Time.zone.parse("2026-10-06 08:00 UTC")) { example.run } }

  def section(day_part) = today.sections.find { it.day_part == day_part }

  describe "tasks" do
    let!(:afternoon_task) do
      create(:work_package, project:, type: task, subject: "Afternoon", due_date: Date.new(2026, 10, 6),
                            custom_field_values: { day_part.id => options[1].id })
    end
    let!(:task_without_part) do
      create(:work_package, project:, type: task, subject: "No part", due_date: Date.new(2026, 10, 6))
    end
    let!(:closed_task) do
      create(:work_package, project:, type: task, subject: "Done", due_date: Date.new(2026, 10, 6),
                            status: create(:closed_status), custom_field_values: { day_part.id => options[2].id })
    end
    let!(:tomorrow_task) do
      create(:work_package, project:, type: task, subject: "Tomorrow", due_date: Date.new(2026, 10, 7))
    end
    let!(:other_project_task) do
      create(:work_package, subject: "Elsewhere", due_date: Date.new(2026, 10, 6))
    end

    it "puts today's tasks into their day part, and those without one into the morning" do
      expect(section(:morning).work_packages).to contain_exactly(task_without_part)
      expect(section(:afternoon).work_packages).to contain_exactly(afternoon_task)
      expect(section(:evening).work_packages).to contain_exactly(closed_task)
    end

    it "counts all tasks of a day part, closed ones included" do
      expect(section(:evening).todo_count).to eq(1)
    end
  end

  describe "references" do
    let(:visible_work_package) { create(:work_package, project: meeting_project) }
    let(:hidden_work_package) { create(:work_package) }

    before do
      create(:work_package, project:, type: task, due_date: Date.new(2026, 10, 6),
                            subject: "Work on ##{visible_work_package.id} and ##{hidden_work_package.id}")
    end

    it "finds the referenced work packages the user can see" do
      expect(today.references.values.uniq).to contain_exactly(visible_work_package)
      expect(today.references[visible_work_package.id.to_s]).to eq(visible_work_package)
    end
  end

  describe "meetings" do
    let!(:morning_meeting) { create(:meeting, project: meeting_project, start_time: berlin.parse("2026-10-06 11:30")) }
    let!(:afternoon_meeting) { create(:meeting, project: meeting_project, start_time: berlin.parse("2026-10-06 12:00")) }
    let!(:late_meeting) { create(:meeting, project: meeting_project, start_time: berlin.parse("2026-10-06 23:30")) }
    let!(:after_midnight_meeting) do
      create(:meeting, project: meeting_project, start_time: berlin.parse("2026-10-07 00:30"))
    end
    let!(:not_invited_meeting) { create(:meeting, project: meeting_project, start_time: berlin.parse("2026-10-06 10:00")) }

    before do
      [morning_meeting, afternoon_meeting, late_meeting, after_midnight_meeting].each do |meeting|
        create(:meeting_participant, meeting:, user:)
      end
    end

    it "shows the meetings the user takes part in on their local day, by local start time" do
      expect(section(:morning).meetings.map(&:meeting)).to contain_exactly(morning_meeting)
      expect(section(:afternoon).meetings.map(&:meeting)).to contain_exactly(afternoon_meeting)
      expect(section(:evening).meetings.map(&:meeting)).to contain_exactly(late_meeting)
    end

    it "knows which day part it is now" do
      expect(today.current_day_part).to eq(:morning)
    end

    context "with a recurring series" do
      let!(:series) do
        create(:recurring_meeting, project: meeting_project, author: user, title: "Daily",
                                   start_time: berlin.parse("2026-10-05 09:30"), frequency: "working_days",
                                   end_after: "never")
      end

      it "lists today's occurrence before it is created" do
        daily = section(:morning).meetings.find { it.series == series }

        expect(daily).to have_attributes(title: "Daily", meeting: nil, start_time: berlin.parse("2026-10-06 09:30"))
        expect(daily).to be_recurring
      end
    end

    context "when the user can no longer see the meeting project" do
      before { Member.where(project: meeting_project, principal: user).destroy_all }

      it "shows no meetings" do
        expect(today.meetings).to be_empty
      end
    end
  end
end
