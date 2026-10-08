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

require "rails_helper"

RSpec.describe Backlogs::SprintReports::Widgets::VelocityChart, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints] }) }

  let(:previous_sprint) { build_stubbed(:sprint, project:, name: "Sprint 1") }
  let(:sprint) { build_stubbed(:sprint, :active, project:, name: "Sprint 2") }

  let(:velocity) do
    instance_double(Backlogs::Velocity,
                    sprints: [previous_sprint, sprint],
                    committed: [21.4, 13.0],
                    completed: [20.0, 8.6],
                    velocity: 8.6,
                    average: 14.31)
  end

  current_user { user }

  before { allow(Backlogs::Velocity).to receive(:new).with(sprint, project).and_return(velocity) }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  def chart_data
    JSON.parse(rendered_component.at("opce-velocity-chart")["chart-data"])
  end

  it "renders the widget title" do
    expect(rendered_component).to have_text("Velocity chart")
  end

  it "labels the bars with the sprint names" do
    expect(chart_data["labels"]).to eq ["Sprint 1", "Sprint 2"]
  end

  it "passes committed and completed story points rounded to whole numbers" do
    expect(chart_data["datasets"]).to eq [
      { "label" => "Committed", "data" => [21, 13] },
      { "label" => "Completed", "data" => [20, 9] }
    ]
  end

  it "passes the average rounded to one decimal" do
    expect(chart_data["average"]).to eq 14.3
  end

  it "passes the axis title" do
    expect(chart_data["yAxisTitle"]).to eq "Story points"
  end

  it "summarizes the velocity of the viewed sprint" do
    expect(rendered_component).to have_text("Sprint 2: 9 SP", normalize_ws: true)
  end

  it "summarizes the average with the actual number of sprints" do
    expect(rendered_component).to have_text("Average of last 2 sprints: 14.3 SP", normalize_ws: true)
  end

  context "with a whole-numbered average" do
    let(:velocity) do
      instance_double(Backlogs::Velocity,
                      sprints: [sprint], committed: [10.0], completed: [8.0], velocity: 8.0, average: 8.0)
    end

    it "omits the decimal" do
      expect(rendered_component).to have_text("Average of last sprint: 8 SP", normalize_ws: true)
    end
  end

  context "when the sprint was never started" do
    let(:sprint) { build_stubbed(:sprint, project:, status: "in_planning", start_date: nil, finish_date: nil) }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the completed sprint has no dates" do
    let(:sprint) do
      build_stubbed(:sprint, project:, status: "completed", start_date: nil, finish_date: nil,
                             started_at: nil, completed_at: nil)
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the project allows multiple active sprints" do
    before { project.update!(allow_multiple_active_sprints: true) }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the user lacks the view_sprints permission" do
    let(:user) { create(:user, member_with_permissions: { project => [] }) }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end
end
