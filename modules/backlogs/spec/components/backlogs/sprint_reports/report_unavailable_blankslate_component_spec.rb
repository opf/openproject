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

RSpec.describe Backlogs::SprintReports::ReportUnavailableBlankslateComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(timeframe: Sprints::Timeframe.new(sprint))) }

  context "when the sprint has no dates" do
    let(:sprint) { build_stubbed(:sprint, start_date: nil, finish_date: nil) }

    it "asks for the dates the report is measured over", :aggregate_failures do
      expect(rendered_component).to have_css(".blankslate", text: "Missing sprint dates")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "Sprint start and finish dates are necessary for the report to show."
      )
    end
  end

  context "when the sprint was never started and its planned dates have passed" do
    let(:sprint) { build_stubbed(:sprint, start_date: 10.days.ago.to_date, finish_date: 3.days.ago.to_date) }

    it "asks for dates in the future, the sprint having never been executed", :aggregate_failures do
      expect(rendered_component).to have_css(".blankslate", text: "Planned sprint dates are in the past")
      expect(rendered_component).to have_css(
        ".blankslate-description",
        exact_text: "The sprint was planned, but it was never executed. " \
                    "Change the planned start and finish dates to a future time in order to see the sprint report."
      )
    end
  end

  context "when the sprint's report has an interval to cover" do
    let(:sprint) do
      build_stubbed(:sprint, start_date: 10.days.ago.to_date, finish_date: 3.days.ago.to_date, started_at: 10.days.ago)
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end
end
