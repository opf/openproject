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

RSpec.describe Backlogs::SprintReports::Widgets::BurnupChart, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:open_status) { create(:status, name: "Open", is_default: true) }

  let(:monday) { Date.new(2026, 10, 12) }
  let(:saturday) { Date.new(2026, 10, 17) }
  let(:sunday) { Date.new(2026, 10, 18) }
  let(:second_friday) { Date.new(2026, 10, 23) }
  let(:now) { monday.in_time_zone + 3.days + 12.hours }

  let(:sprint) do
    create(:sprint, project:, start_date: monday, finish_date: second_friday, started_at: monday.in_time_zone + 9.hours)
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  def chart_data
    JSON.parse(rendered_component.at("opce-burnup-chart")["chart-data"])
  end

  def guideline
    chart_data["series"].find { |series| series["id"] == "guideline" }
  end

  before { week_with_saturday_and_sunday_as_weekend }

  around do |example|
    travel_to(now) { example.run }
  end

  context "when the sprint has a date range set" do
    before do
      create(:work_package, project:, sprint:, status: open_status,
                            journals: { monday.in_time_zone + 9.hours => { story_points: 10 } })
    end

    it "renders the burnup chart element" do
      expect(rendered_component).to have_element(:"opce-burnup-chart")
    end

    it "sends the unit" do
      expect(chart_data["unit"]).to eq "story_points"
    end

    it "carries each series under a stable id and a translated label" do
      expect(chart_data["series"].pluck("id", "label"))
        .to eq([["completed", "Completed work"],
                ["scope", "Total work scope"],
                ["projection", "Total work scope (projection)"],
                ["guideline", "Guideline"]])
    end

    it "sends points as x/y pairs" do
      first = chart_data["series"].find { |series| series["id"] == "scope" }["data"].first

      expect(first["x"]).to eq (monday.in_time_zone + 9.hours).utc.iso8601(3)
      expect(first["y"]).to eq 10.0
    end

    # 10 points over 9.625 days of capacity, the first Monday counting only from 09:00.
    it "rounds a value the series arrived at by division" do
      expect(guideline["data"].second["y"]).to eq 0.649
    end

    context "with a viewer east of UTC" do
      current_user do
        create(:user, member_with_roles: { project => role }, preferences: { time_zone: "Asia/Kolkata" })
      end

      it "sends the guideline's day ends as UTC instants rather than zoned ones" do
        expect(guideline["data"].second["x"]).to eq "2026-10-12T18:29:59.999Z"
      end
    end

    it "sends the step, without which the chart cannot name a tick's period" do
      expect(chart_data["step"]).to eq "hour"
    end

    it "sends the non working days of the charted range" do
      expect(chart_data["nonWorkingIntervals"])
        .to eq([{ "from" => saturday.iso8601, "to" => sunday.iso8601 }])
    end

    it "leaves out a series that has no points" do
      sprint.update!(completed_at: now)

      expect(chart_data["series"].pluck("id")).to eq %w[completed scope guideline]
    end
  end

  context "when the sprint never received a work package" do
    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burnup-chart")
      expect(rendered_component).to have_css(".blankslate", text: "No work to display")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "The burnup chart will appear here once the sprint has received a work package with estimated story points."
      )
    end
  end

  context "when the sprint only held story points before the charted window" do
    before do
      create(:work_package, project:, story_points: 5,
                            journals: { monday.in_time_zone - 2.days => { sprint_id: sprint.id },
                                        monday.in_time_zone - 1.day => {} })
    end

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burnup-chart")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "The burnup chart will appear here once the sprint has received a work package with estimated story points."
      )
    end
  end

  context "when the sprint only received work packages without story points" do
    before { create(:work_package, project:, sprint:, story_points: nil) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burnup-chart")
      expect(rendered_component).to have_css(".blankslate", text: "No work to display")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "The burnup chart will appear here once the sprint has received a work package with estimated story points."
      )
    end
  end

  context "when the project estimates in time", with_flag: { project_settings_estimation_unit: true } do
    before { project.estimation_unit = "time" }

    context "when the sprint never received a work package" do
      it "renders a blankslate asking for a work time estimate" do
        expect(rendered_component).to have_no_element(:"opce-burnup-chart")
        expect(rendered_component).to have_css(
          ".blankslate-description",
          exact_text: "The burnup chart will appear here once the sprint has received a work package with work time estimate."
        )
      end
    end
  end

  context "when the current date is before the sprint's start date and the sprint never received a work package" do
    let(:now) { monday.in_time_zone - 2.hours }
    let(:sprint) { create(:sprint, project:, start_date: monday, finish_date: second_friday) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burnup-chart")
      expect(rendered_component).to have_css(".blankslate", text: "No work to display")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "The burnup chart will appear here after the sprint starts."
      )
    end
  end

  context "when the current date is before the sprint's start date" do
    let(:now) { monday.in_time_zone - 2.hours }
    let(:sprint) { create(:sprint, project:, start_date: monday, finish_date: second_friday) }

    before { create(:work_package, project:, sprint:, story_points: 3) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burnup-chart")
      expect(rendered_component).to have_css(".blankslate", text: "No work to display")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "The burnup chart will appear here after the sprint starts."
      )
    end

    context "when the sprint was started early" do
      let(:sprint) do
        create(:sprint, project:, start_date: monday, finish_date: second_friday, started_at: now - 1.hour)
      end

      it "renders the chart" do
        expect(rendered_component).to have_element(:"opce-burnup-chart")
      end
    end

    context "with a viewer for whom the start date has already begun" do
      current_user do
        create(:user, member_with_roles: { project => role }, preferences: { time_zone: "Asia/Tokyo" })
      end

      it "renders the chart" do
        expect(rendered_component).to have_element(:"opce-burnup-chart")
      end
    end
  end

  context "when the sprint takes more than a year" do
    let(:sprint) do
      create(:sprint, project:, start_date: monday, finish_date: monday + 13.months, started_at: monday.in_time_zone + 9.hours)
    end

    before { create(:work_package, project:, sprint:) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burnup-chart")
      expect(rendered_component).to have_css(".blankslate", text: "No chart to display")
      expect(rendered_component).to have_css(
        ".blankslate",
        text: "The sprint duration exceeded the 1-year limit of the burnup chart's timespan."
      )
    end
  end

  context "when the sprint has no date range set" do
    let(:sprint) { create(:sprint, project:, start_date: nil, finish_date: nil) }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "with the estimation unit feature active", with_flag: { project_settings_estimation_unit: true } do
    before { project.estimation_unit = estimation_unit }

    context "when estimation unit is story points" do
      let(:estimation_unit) { "story_points" }

      before do
        create(:work_package, project:, sprint:, status: open_status,
                              journals: { monday.in_time_zone + 9.hours => { story_points: 10 } })
      end

      it "renders the widget" do
        expect(rendered_component).to have_element(:"opce-burnup-chart")
      end
    end

    context "when estimation unit is time" do
      let(:estimation_unit) { "time" }

      before do
        create(:work_package, project:, sprint:, status: open_status,
                              journals: { monday.in_time_zone + 9.hours => { estimated_hours: 10 } })
      end

      it "renders the widget" do
        expect(rendered_component).to have_element(:"opce-burnup-chart")
      end

      it "sends the unit" do
        expect(chart_data["unit"]).to eq "time"
      end
    end

    context "when estimation unit is none" do
      let(:estimation_unit) { "none" }

      it "renders nothing" do
        expect(rendered_component.to_s).to be_empty
      end
    end
  end
end
