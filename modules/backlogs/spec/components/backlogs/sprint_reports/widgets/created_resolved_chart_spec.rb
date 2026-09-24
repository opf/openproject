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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

# This is just a quick smoke test of the created vs resolved chart.
# Long term, ideally there should be a proper integration test that inspects what the user
# can actually see. For now, this is too time-intensive.
RSpec.describe Backlogs::SprintReports::Widgets::CreatedResolvedChart, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:sprint) { build_stubbed(:sprint, project:, start_date: 1.week.ago.to_date, finish_date: 1.week.from_now.to_date) }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  context "when the sprint has a date range set" do
    let(:created_resolved) do
      instance_double(
        CreatedResolved,
        days: [Time.zone.today - 2.days, Time.zone.today - 1.day, Time.zone.today],
        series: { wp_created: [1.0, 2.0, 0.0], wp_resolved: [0.0, 1.0, 4.0] }
      )
    end

    before { allow(CreatedResolved).to receive(:new).with(sprint, project).and_return(created_resolved) }

    it "renders the created vs resolved chart element" do
      expect(rendered_component).to have_element(:"opce-created-resolved-chart")
    end

    it "sets chart-data with labels and the expected dataset labels" do
      chart_data = JSON.parse(rendered_component.at("opce-created-resolved-chart")["chart-data"])

      expect(chart_data["labels"]).to be_an(Array)
      expect(chart_data["datasets"].pluck("label")).to contain_exactly("Created", "Resolved")
    end
  end

  context "when the sprint has no date range set" do
    let(:sprint) { build_stubbed(:sprint, project:, start_date: nil, finish_date: nil) }

    it "renders a blankslate instead of the chart" do
      expect(rendered_component).to have_no_element(:"opce-created-resolved-chart")
      expect(rendered_component).to have_text("No created vs resolved chart data available")
    end
  end
end
