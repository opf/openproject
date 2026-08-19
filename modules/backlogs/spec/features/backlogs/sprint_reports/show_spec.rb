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
    before { visit_sprint_report }

    let(:widget_boxes) { page.all(".widget-boxes .widget-box", minimum: 2) }

    it "renders the sprint goal widget first" do
      expect(widget_boxes[0]).to have_text("Add sprint goal widget")
    end

    it "renders the work package overview widget second" do
      expect(widget_boxes[1]).to have_text("Work packages within the sprint")
    end

    it "renders the burndown chart widget third" do
      expect(widget_boxes[2]).to have_css("opce-burndown-chart")
    end
  end
end
