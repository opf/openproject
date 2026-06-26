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

RSpec.describe "Sprint report routing" do
  context "with sprint_reports feature flag", with_flag: :sprint_reports do
    describe "routing" do
      it "routes GET report to sprint_reports#show" do
        expect(get("/projects/project_42/backlogs/sprints/21/report")).to route_to(
          controller: "backlogs/sprint_reports",
          action: "show",
          project_id: "project_42",
          sprint_id: "21"
        )
      end

      it "routes GET report/widgets/burndown_chart to sprint_reports/widgets#burndown_chart" do
        expect(get("/projects/project_42/backlogs/sprints/21/report/widgets/burndown_chart")).to route_to(
          controller: "backlogs/sprint_reports/widgets",
          action: "burndown_chart",
          project_id: "project_42",
          sprint_id: "21"
        )
      end
    end

    describe "named routing" do
      it "generates the sprint report path" do
        expect(project_backlogs_sprint_report_path("project_42", "21"))
          .to eq("/projects/project_42/backlogs/sprints/21/report")
      end

      it "generates the burndown chart widget path" do
        expect(project_backlogs_sprint_report_burndown_chart_widget_path("project_42", "21"))
          .to eq("/projects/project_42/backlogs/sprints/21/report/widgets/burndown_chart")
      end
    end
  end

  context "without sprint_reports feature flag" do
    it "does not route GET report" do
      expect(get("/projects/project_42/backlogs/sprints/21/report")).not_to route_to(
        controller: "backlogs/sprint_reports",
        action: "show"
      )
    end

    it "does not route GET report/widgets/burndown_chart" do
      expect(get("/projects/project_42/backlogs/sprints/21/report/widgets/burndown_chart")).not_to route_to(
        controller: "backlogs/sprint_reports/widgets",
        action: "burndown_chart"
      )
    end
  end
end
