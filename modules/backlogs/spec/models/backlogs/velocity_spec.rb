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

RSpec.describe Backlogs::Velocity do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }

  let(:open_status) { create(:status, is_default: true) }
  let(:done_status) { create(:status) }
  let(:closed_status) { create(:status, is_closed: true) }

  let(:start_of_history) { Time.zone.local(2026, 3, 2, 10) }

  current_user { create(:user, member_with_roles: { project => role, other_project => role }) }

  before do
    project.done_statuses << done_status
  end

  subject(:velocity) { described_class.new(sprint, project) }

  def completed_sprint(started_at:, completed_at:, **)
    create(:sprint,
           project:,
           status: "completed",
           start_date: started_at.to_date,
           finish_date: completed_at.to_date,
           started_at:,
           completed_at:,
           **)
  end

  def active_sprint(started_at:, **)
    create(:sprint,
           project:,
           status: "active",
           start_date: started_at.to_date,
           finish_date: started_at.to_date + 14.days,
           started_at:,
           **)
  end

  def create_story(time:, sprint:, story_points:, status: open_status, project: self.project)
    travel_to(time) { create(:work_package, project:, sprint:, story_points:, status:) }
  end

  def change_story(story, time:, **attributes)
    travel_to(time) { story.reload.update!(attributes) }
  end

  describe "#sprints" do
    context "with only the viewed sprint" do
      let(:sprint) { active_sprint(started_at: start_of_history) }

      it "contains just that sprint" do
        expect(velocity.sprints).to eq [sprint]
      end
    end

    context "with more than seven sprints before the viewed one" do
      let!(:previous_sprints) do
        Array.new(8) do |i|
          completed_sprint(started_at: start_of_history + (i * 2).weeks,
                           completed_at: start_of_history + ((i * 2) + 2).weeks)
        end
      end
      let(:sprint) { active_sprint(started_at: start_of_history + 16.weeks) }

      it "contains the six latest preceding sprints followed by the viewed sprint" do
        expect(velocity.sprints).to eq [*previous_sprints.last(6), sprint]
      end
    end

    context "with sprints created in a different order than they ran" do
      let!(:second) do
        completed_sprint(started_at: start_of_history + 2.weeks, completed_at: start_of_history + 4.weeks)
      end
      let!(:first) do
        completed_sprint(started_at: start_of_history, completed_at: start_of_history + 2.weeks)
      end
      let(:sprint) { active_sprint(started_at: start_of_history + 4.weeks) }

      it "orders them by the time they were started" do
        expect(velocity.sprints).to eq [first, second, sprint]
      end
    end

    context "with a completed sprint lacking started_at" do
      let!(:undated_start) do
        create(:sprint,
               project:,
               status: "completed",
               start_date: (start_of_history + 2.weeks).to_date,
               finish_date: (start_of_history + 4.weeks).to_date,
               started_at: nil,
               completed_at: start_of_history + 4.weeks)
      end
      let!(:first) do
        completed_sprint(started_at: start_of_history, completed_at: start_of_history + 2.weeks)
      end
      let(:sprint) { active_sprint(started_at: start_of_history + 4.weeks) }

      it "falls back to the start date for ordering" do
        expect(velocity.sprints).to eq [first, undated_start, sprint]
      end
    end

    context "when viewing a sprint that has successors" do
      let!(:first) do
        completed_sprint(started_at: start_of_history, completed_at: start_of_history + 2.weeks)
      end
      let!(:sprint) do
        completed_sprint(started_at: start_of_history + 2.weeks, completed_at: start_of_history + 4.weeks)
      end
      let!(:later) do
        completed_sprint(started_at: start_of_history + 4.weeks, completed_at: start_of_history + 6.weeks)
      end

      it "ends with the viewed sprint" do
        expect(velocity.sprints).to eq [first, sprint]
      end
    end

    context "with sprints that were never started" do
      let!(:first) do
        completed_sprint(started_at: start_of_history, completed_at: start_of_history + 2.weeks)
      end
      let!(:stale) do
        create(:sprint,
               project:,
               status: "in_planning",
               start_date: (start_of_history + 2.weeks).to_date,
               finish_date: (start_of_history + 4.weeks).to_date)
      end
      let(:sprint) { active_sprint(started_at: start_of_history + 4.weeks) }

      it "leaves them out" do
        expect(velocity.sprints).to eq [first, sprint]
      end
    end

    context "with sprints of another project" do
      let!(:foreign) do
        create(:sprint,
               project: other_project,
               status: "completed",
               start_date: start_of_history.to_date,
               finish_date: (start_of_history + 2.weeks).to_date,
               started_at: start_of_history,
               completed_at: start_of_history + 2.weeks)
      end
      let(:sprint) { active_sprint(started_at: start_of_history + 4.weeks) }

      it "leaves them out" do
        expect(velocity.sprints).to eq [sprint]
      end
    end
  end

  describe "#committed" do
    let(:sprint) do
      completed_sprint(started_at: start_of_history + 1.day, completed_at: start_of_history + 2.weeks)
    end

    it "sums the story points of the sprint's work packages at the time it was started" do
      create_story(time: start_of_history, sprint:, story_points: 5)
      create_story(time: start_of_history, sprint:, story_points: 3, status: closed_status)

      expect(velocity.committed).to eq [8.0]
    end

    it "ignores work packages added after the start" do
      create_story(time: start_of_history, sprint:, story_points: 5)
      create_story(time: start_of_history + 3.days, sprint:, story_points: 8)

      expect(velocity.committed).to eq [5.0]
    end

    it "keeps work packages removed after the start" do
      story = create_story(time: start_of_history, sprint:, story_points: 5)
      change_story(story, time: start_of_history + 3.days, sprint: nil)

      expect(velocity.committed).to eq [5.0]
    end

    it "ignores story point changes after the start" do
      story = create_story(time: start_of_history, sprint:, story_points: 5)
      change_story(story, time: start_of_history + 3.days, story_points: 13)

      expect(velocity.committed).to eq [5.0]
    end

    it "ignores work packages of other projects" do
      create_story(time: start_of_history, sprint:, story_points: 5)
      create_story(time: start_of_history, sprint:, story_points: 8, project: other_project)

      expect(velocity.committed).to eq [5.0]
    end
  end

  describe "#completed" do
    context "for a completed sprint" do
      let(:sprint) do
        completed_sprint(started_at: start_of_history + 1.day, completed_at: start_of_history + 2.weeks)
      end

      it "sums the story points of done and closed work packages at the time it was completed" do
        create_story(time: start_of_history, sprint:, story_points: 5, status: done_status)
        create_story(time: start_of_history, sprint:, story_points: 3, status: closed_status)
        create_story(time: start_of_history, sprint:, story_points: 8)

        expect(velocity.completed).to eq [8.0]
      end

      it "ignores work packages finished after completion" do
        story = create_story(time: start_of_history, sprint:, story_points: 5)
        change_story(story, time: start_of_history + 3.weeks, status: done_status)

        expect(velocity.completed).to eq [0.0]
      end

      it "ignores story point changes after completion" do
        story = create_story(time: start_of_history, sprint:, story_points: 5, status: done_status)
        change_story(story, time: start_of_history + 3.weeks, story_points: 13)

        expect(velocity.completed).to eq [5.0]
      end

      it "ignores work packages of other projects" do
        create_story(time: start_of_history, sprint:, story_points: 5, status: done_status)
        create_story(time: start_of_history, sprint:, story_points: 8, status: closed_status, project: other_project)

        expect(velocity.completed).to eq [5.0]
      end
    end

    context "for an active sprint" do
      let(:sprint) { active_sprint(started_at: start_of_history + 1.day) }

      it "uses the current state of its work packages" do
        story = create_story(time: start_of_history, sprint:, story_points: 5)
        create_story(time: start_of_history, sprint:, story_points: 8)
        change_story(story, time: 1.minute.ago, status: done_status)

        expect(velocity.completed).to eq [5.0]
      end
    end
  end

  describe "#velocity and #average" do
    let!(:first) do
      completed_sprint(started_at: start_of_history + 1.day, completed_at: start_of_history + 2.weeks)
    end
    let!(:second) do
      completed_sprint(started_at: start_of_history + 2.weeks + 1.day, completed_at: start_of_history + 4.weeks)
    end
    let(:sprint) { active_sprint(started_at: start_of_history + 4.weeks + 1.day) }

    before do
      create_story(time: start_of_history, sprint: first, story_points: 10, status: done_status)
      create_story(time: start_of_history + 2.weeks, sprint: second, story_points: 5, status: done_status)
      create_story(time: start_of_history + 4.weeks, sprint:, story_points: 3, status: closed_status)
    end

    it "uses the completed story points of the viewed sprint as velocity" do
      expect(velocity.velocity).to eq 3.0
    end

    it "averages the completed story points of all displayed sprints" do
      expect(velocity.average).to eq 6.0
    end
  end
end
