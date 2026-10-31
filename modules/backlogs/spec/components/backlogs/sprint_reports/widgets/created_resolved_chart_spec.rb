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

RSpec.describe Backlogs::SprintReports::Widgets::CreatedResolvedChart,
               type: :component,
               with_ee: %i[sprint_report_pro_widgets] do
  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages]) }
  shared_let(:open_status) { create(:status, name: "Open", is_default: true) }
  shared_let(:closed_status) { create(:status, name: "Closed", is_closed: true) }

  let(:monday) { Date.new(2026, 10, 12) }
  let(:saturday) { Date.new(2026, 10, 17) }
  let(:sunday) { Date.new(2026, 10, 18) }
  let(:second_friday) { Date.new(2026, 10, 23) }
  let(:sprint_start) { monday.in_time_zone + 9.hours }
  let(:now) { monday.in_time_zone + 3.days + 12.hours }

  let(:sprint) do
    create(:sprint, project:, start_date: monday, finish_date: second_friday, started_at: sprint_start)
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  def chart_data
    JSON.parse(rendered_component.at("opce-created-resolved-chart")["chart-data"])
  end

  before { week_with_saturday_and_sunday_as_weekend }

  around do |example|
    travel_to(now) { example.run }
  end

  context "when the sprint has a date range set" do
    before do
      create(:work_package, project:, sprint:, status: open_status,
                            journals: { sprint_start => { subject: "Open one" } })
      create(:work_package, project:, sprint:, status: closed_status,
                            journals: { sprint_start => { subject: "Closed one", status_id: closed_status.id } })
    end

    it "renders the created vs resolved chart element" do
      expect(rendered_component).to have_element(:"opce-created-resolved-chart")
    end

    it "carries each series under a stable id and a translated label" do
      expect(chart_data["series"].pluck("id", "label"))
        .to eq([["created", "Created work packages"],
                ["resolved", "Resolved work packages"]])
    end

    it "sends points as x/y pairs, counting what the sprint held at each tick" do
      created, resolved = chart_data["series"].map { it["data"].first }

      expect(created["x"]).to eq sprint_start.utc.iso8601(3)
      expect(created["y"]).to eq 2.0
      expect(resolved["y"]).to eq 1.0
    end

    # Both series are counted at the same ticks, which is what lets the chart match them by index.
    it "samples both series at the very same instants" do
      created, resolved = chart_data["series"].map { it["data"].pluck("x") }

      expect(created).to eq resolved
    end

    it "sends the step, without which the chart cannot name a tick's period" do
      expect(chart_data["step"]).to eq "hour"
    end

    # These counts stop at the current moment, but the burndown beside them is drawn to the
    # planned finish. The axis follows the window so that the two span the same interval.
    it "sends the charted window, which reaches past where the counts stop" do
      expect(chart_data["range"]["from"]).to eq sprint_start.utc.iso8601(3)
      expect(chart_data["range"]["to"]).to eq second_friday.in_time_zone.end_of_day.utc.iso8601(3)
      expect(chart_data["series"].first["data"].last["x"]).to eq now.utc.iso8601(3)
    end

    it "sends the non working days of the charted range" do
      expect(chart_data["nonWorkingIntervals"])
        .to eq([{ "from" => saturday.iso8601, "to" => sunday.iso8601 }])
    end

    context "when the sprint has not started yet" do
      let(:sprint) do
        create(:sprint, project:, start_date: monday, finish_date: second_friday)
      end
      let(:now) { monday.in_time_zone - 7.days }

      # Nothing has been created in a sprint that has not begun, and a flat zero would invite the
      # reader to believe that was measured. The frontend turns the empty payload into a blankslate.
      it "leaves out both series rather than sending a measured zero" do
        expect(chart_data["series"]).to be_empty
      end
    end
  end

  context "when the sprint has no date range set" do
    let(:sprint) { create(:sprint, project:, start_date: nil, finish_date: nil) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-created-resolved-chart")
      expect(rendered_component).to have_text("No created vs resolved chart data available")
    end
  end
end
