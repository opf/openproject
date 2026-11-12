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
require "rails_helper"

RSpec.describe SprintNeighbors do
  shared_let(:project) { create(:project) }
  shared_let(:active_sprint) do
    create(:sprint, project:, name: "Active", status: :active,
                    start_date: Date.yesterday, finish_date: Date.tomorrow)
  end
  shared_let(:planned_sprint) do
    create(:sprint, project:, name: "Planned", status: :in_planning,
                    start_date: 10.days.from_now, finish_date: 20.days.from_now)
  end
  shared_let(:recent_sprint) do
    create(:sprint, project:, name: "Recent", status: :completed,
                    start_date: 20.days.ago, finish_date: 10.days.ago)
  end
  shared_let(:oldest_sprint) do
    create(:sprint, project:, name: "Oldest", status: :completed,
                    start_date: 40.days.ago, finish_date: 30.days.ago)
  end
  shared_let(:other_project_sprint) do
    create(:sprint, project: create(:project), name: "Elsewhere", status: :completed,
                    start_date: 15.days.ago, finish_date: 12.days.ago)
  end

  let(:permissions) { %i[view_sprints] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  subject(:neighbors) { described_class.new(sprint:, project:, user:) }

  context "for a sprint in the middle of the chronological order" do
    let(:sprint) { active_sprint }

    it "returns the sprints before and after it, regardless of status and other projects", :aggregate_failures do
      expect(neighbors.previous_sprint).to eq(recent_sprint)
      expect(neighbors.next_sprint).to eq(planned_sprint)
    end
  end

  context "for the earliest sprint" do
    let(:sprint) { oldest_sprint }

    it "has no previous sprint", :aggregate_failures do
      expect(neighbors.previous_sprint).to be_nil
      expect(neighbors.next_sprint).to eq(recent_sprint)
    end
  end

  context "for the latest sprint" do
    let(:sprint) { planned_sprint }

    it "has no next sprint", :aggregate_failures do
      expect(neighbors.previous_sprint).to eq(active_sprint)
      expect(neighbors.next_sprint).to be_nil
    end
  end

  context "for a user without permission to view the project's sprints" do
    let(:sprint) { planned_sprint }
    let(:permissions) { %i[view_work_packages] }

    it "has no neighbors", :aggregate_failures do
      expect(neighbors.previous_sprint).to be_nil
      expect(neighbors.next_sprint).to be_nil
    end
  end

  context "for a sprint not belonging to the project" do
    let(:sprint) { other_project_sprint }

    it "has no neighbors", :aggregate_failures do
      expect(neighbors.previous_sprint).to be_nil
      expect(neighbors.next_sprint).to be_nil
    end
  end
end
