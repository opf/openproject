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

RSpec.describe "Burndown chart widget", :js, with_flag: :sprint_reports do
  include Rails.application.routes.url_helpers

  let(:permissions) { %i[view_sprints view_work_packages show_board_views] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  shared_let(:project) { create(:project) }

  current_user { user }

  def visit_widget(sprint)
    visit project_backlogs_sprint_report_burndown_chart_widget_path(project, sprint)
  end

  context "when the sprint has a date range set" do
    shared_let(:sprint) do
      create(:sprint,
             project:,
             name: "Sprint 42",
             start_date: Date.yesterday,
             finish_date: Date.tomorrow,
             status: :active)
    end

    it "renders the burndown chart" do
      visit_widget(sprint)

      expect(page).to have_element(:"opce-burndown-chart")
    end

    context "when the user lacks view_sprints" do
      let(:permissions) { %i[view_work_packages show_board_views] }

      it "responds with not found" do
        visit_widget(sprint)

        expect(page).to have_http_status(:not_found)
      end
    end
  end

  describe "chart data passed to the component" do
    shared_let(:sprint) do
      create(:sprint,
             project:,
             name: "Sprint 42",
             start_date: 1.week.ago.to_date,
             finish_date: 1.week.from_now.to_date,
             status: :active)
    end

    let!(:status) { create(:status, is_default: true) }

    # Backdating the journal validity_period to the sprint start makes the story
    # points appear as remaining work on every collected day since the sprint began.
    let!(:work_package1) do
      create(:work_package, project:, sprint:, story_points: 5, status:) do |wp|
        wp.last_journal.update_columns(
          created_at: sprint.start_date.beginning_of_day,
          updated_at: sprint.start_date.beginning_of_day,
          validity_period: sprint.start_date.beginning_of_day..Float::INFINITY
        )
      end
    end
    let!(:work_package2) do
      create(:work_package, project:, sprint:, story_points: 3, status:) do |wp|
        wp.last_journal.update_columns(
          created_at: sprint.start_date.beginning_of_day,
          updated_at: sprint.start_date.beginning_of_day,
          validity_period: sprint.start_date.beginning_of_day..Float::INFINITY
        )
      end
    end

    it "sets chart-data with labels and the expected series" do
      visit_widget(sprint)

      chart_data = JSON.parse(find("opce-burndown-chart")["chart-data"])

      expect(chart_data["labels"]).to be_an(Array)
      expect(chart_data["datasets"].pluck("label")).to contain_exactly("Story points", "Story points (ideal)")

      story_points = chart_data["datasets"].find { |d| d["label"] == "Story points" }
      ideal = chart_data["datasets"].find { |d| d["label"] == "Story points (ideal)" }

      # 5 + 3 = 8 points remain on every collected day because both WPs were
      # present from the sprint start and have not been completed.
      expect(story_points["data"]).to all(eq(8.0))
      # The ideal starts at the sprint total and decreases linearly to zero.
      expect(ideal["data"].first).to eq(8.0)
      expect(ideal["data"].last).to be_within(0.001).of(0.0)
    end
  end

  context "when the sprint has no date range set" do
    shared_let(:sprint) do
      create(:sprint,
             project:,
             name: "Sprint 42",
             start_date: nil,
             finish_date: nil)
    end

    it "renders a blankslate instead of the chart" do
      visit_widget(sprint)

      expect(page).to have_no_element(:"opce-burndown-chart")
      expect(page).to have_text("No burndown data available")
    end
  end
end
