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

RSpec.describe "Sprint report page", :js, with_flag: :sprint_reports do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:sprint) do
    create(:sprint,
           project:,
           name: "Sprint 42",
           start_date: Date.yesterday,
           finish_date: Date.tomorrow,
           status: :active)
  end

  let(:permissions) { %i[view_sprints view_work_packages show_board_views] }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  def visit_sprint_report
    visit project_backlogs_sprint_report_path(project, sprint)
  end

  describe "authorization" do
    context "when the user lacks view_sprints" do
      let(:permissions) { %i[view_work_packages show_board_views] }

      it "responds with not found" do
        visit_sprint_report
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  describe "page header" do
    before { visit_sprint_report }

    it "shows the sprint report title" do
      expect(page).to have_heading("Sprint 42 report", level: 2)
    end

    it "shows the correct breadcrumbs" do
      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link(project.name, href: project_overview_path(project))
        expect(page).to have_link("Backlogs", href: project_backlogs_backlog_path(project))
        expect(page).to have_link("Sprint 42", href: project_backlogs_sprints_path(project))
        expect(page).to have_text("Report")
      end
    end
  end

  describe "widget area" do
    before { visit_sprint_report }

    it "renders the burndown chart turbo frame pointing to the widget endpoint" do
      expect(page).to have_css(
        "turbo-frame##{Backlogs::SprintReports::Widgets::BurndownChart::FRAME_ID}[src]"
      )

      frame = find("turbo-frame##{Backlogs::SprintReports::Widgets::BurndownChart::FRAME_ID}")
      expect(frame["src"]).to end_with(
        project_backlogs_sprint_report_burndown_chart_widget_path(project, sprint)
      )
    end

    it "loads the burndown chart widget into the frame" do
      within "turbo-frame##{Backlogs::SprintReports::Widgets::BurndownChart::FRAME_ID}" do
        expect(page).to have_element(:"opce-burndown-chart")
      end
    end
  end
end
