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

RSpec.describe Backlogs::SprintReports::Widgets::WorkPackageGraph, type: :component do
  let(:project) { create(:project) }
  let(:sprint) { create(:sprint, project:) }
  let(:user) { build_stubbed(:user) }

  # Statuses are charted in their configured order, which is the order they were created in here.
  let(:status_new) { create(:status, name: "New", color: create(:color, hexcode: "#1A67A3")) }
  let(:status_in_progress) { create(:status, name: "In progress", color: create(:color, hexcode: "#FFA500")) }
  let(:status_closed) { create(:closed_status, name: "Closed") }

  let(:status_counts) { { status_new.id => 3, status_in_progress.id => 1, status_closed.id => 2 } }
  let(:breakdown) { instance_double(Sprints::WorkPackageBreakdown, status_counts:) }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project, breakdown, current_user: user)) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(:view_sprints, project:)
    end
  end

  def chart_data
    JSON.parse(rendered_component.at("opce-sprint-work-package-graph")["chart-data"])
  end

  it "renders the work package graph element" do
    expect(rendered_component).to have_element(:"opce-sprint-work-package-graph")
  end

  it "labels one bar per status, in the configured status order" do
    expect(chart_data["labels"]).to eq ["New", "In progress", "Closed"]
  end

  it "passes the count of each status" do
    expect(chart_data["data"]).to eq [3, 1, 2]
  end

  it "passes each status' own color, and nothing for a status without one" do
    expect(chart_data["colors"]).to eq ["#1A67A3", "#FFA500", nil]
  end

  it "passes an accessible summary of the chart" do
    expect(chart_data["summary"])
      .to eq "Bar chart of the work packages currently in the sprint, by status: " \
             "3 New; 1 In progress; 2 Closed."
  end

  context "when the sprint has been completed" do
    let(:sprint) { create(:sprint, :completed, project:) }

    it "says the summary describes the moment the sprint was completed" do
      expect(chart_data["summary"])
        .to eq "Bar chart of the work packages in the sprint when it was completed, by status: " \
               "3 New; 1 In progress; 2 Closed."
    end
  end

  it "passes the headers of the accessible data table" do
    expect(chart_data["statusColumnTitle"]).to eq "Status"
    expect(chart_data["countColumnTitle"]).to eq "Work packages"
  end

  context "when a status has been deleted since" do
    let(:status_counts) { { status_new.id => 3, status_closed.id => 2, 0 => 1 } }

    it "charts only the statuses that still exist" do
      expect(chart_data["labels"]).to eq ["New", "Closed"]
      expect(chart_data["data"]).to eq [3, 2]
    end
  end

  context "when the sprint holds no work package" do
    let(:status_counts) { {} }

    it "renders a blankslate instead of the graph" do
      expect(rendered_component).to have_no_element(:"opce-sprint-work-package-graph")
      expect(rendered_component).to have_css(".blankslate", text: "No work to display")
      expect(rendered_component).to have_css(
        ".blankslate",
        text: "The work package graph will appear here once the sprint has received a work package."
      )
    end
  end

  context "when the user lacks view_sprints" do
    before do
      mock_permissions_for(user, &:forbid_everything)
    end

    it "does not render" do
      expect(rendered_component).to have_no_element(:"opce-sprint-work-package-graph")
    end
  end
end
