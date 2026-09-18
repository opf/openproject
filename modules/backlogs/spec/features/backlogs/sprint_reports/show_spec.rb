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
  shared_let(:sprint_goal) { create(:sprint_goal, sprint:, project:, text: "Add sprint goal widget") }

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
  end

  describe "widget area" do
    let(:core_widgets) do
      [
        [:text, "Add sprint goal widget"],
        [:text, "Work packages within the sprint"],
        [:css, "opce-wp-overview-graph"],
        [:css, "opce-burndown-chart"]
      ]
    end

    let(:pro_widgets) do
      [
        [:text, "Completed work packages"],
        [:text, "Unfinished work packages"],
        [:text, "Sprint scope increase"],
        [:text, "Sprint scope decrease"]
      ]
    end

    before { visit_sprint_report }

    shared_examples "sprint report widgets" do
      let(:widget_boxes) { page.all(".widget-boxes .widget-box", count: expected_widgets.count) }

      it "renders the widgets in order", :aggregate_failures do
        expected_widgets.each_with_index do |(matcher, expected), index|
          expect(widget_boxes[index]).to send("have_#{matcher}", expected)
        end
      end
    end

    context "without enterprise token" do
      let(:expected_widgets) { core_widgets }

      it_behaves_like "sprint report widgets"
    end

    context "with baseline_comparison", with_ee: :baseline_comparison do
      let(:expected_widgets) { core_widgets }

      it_behaves_like "sprint report widgets"
    end

    context "with baseline_comparison and sprint_report_pro_widgets",
            with_ee: %i[baseline_comparison sprint_report_pro_widgets] do
      let(:expected_widgets) { core_widgets + pro_widgets }

      it_behaves_like "sprint report widgets"
    end
  end
end
