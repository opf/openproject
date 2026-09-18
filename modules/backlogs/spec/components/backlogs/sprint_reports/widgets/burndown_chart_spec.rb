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

RSpec.describe Backlogs::SprintReports::Widgets::BurndownChart, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:open_status) { create(:status, name: "Open", is_default: true) }

  let(:monday) { Date.new(2026, 10, 12) }
  let(:friday) { Date.new(2026, 10, 16) }
  let(:saturday) { Date.new(2026, 10, 17) }
  let(:sunday) { Date.new(2026, 10, 18) }
  let(:second_friday) { Date.new(2026, 10, 23) }
  let(:now) { monday.in_time_zone + 3.days + 12.hours }

  let(:sprint) do
    create(:sprint, project:, start_date: monday, finish_date: second_friday, started_at: monday.in_time_zone + 9.hours)
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  def chart_data
    JSON.parse(rendered_component.at("opce-burndown-chart")["chart-data"])
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

    it "renders the burndown chart element" do
      expect(rendered_component).to have_element(:"opce-burndown-chart")
    end

    it "carries each series under a stable id and a translated label" do
      expect(chart_data["series"].pluck("id", "label"))
        .to eq([["remaining", "Remaining story points"],
                ["guideline", "Guideline"],
                ["projection", "Remaining story points (projection)"]])
    end

    it "sends points as x/y pairs with UTC timestamps" do
      first = chart_data["series"].first["data"].first

      expect(first["x"]).to eq (monday.in_time_zone + 9.hours).utc.iso8601(3)
      expect(first["y"]).to eq 10.0
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

      expect(chart_data["series"].pluck("id")).to eq %w[remaining guideline]
    end
  end

  context "when the sprint has no date range set" do
    let(:sprint) { create(:sprint, project:, start_date: nil, finish_date: nil) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-burndown-chart")
      expect(rendered_component).to have_text("No burndown data available")
    end
  end
end
