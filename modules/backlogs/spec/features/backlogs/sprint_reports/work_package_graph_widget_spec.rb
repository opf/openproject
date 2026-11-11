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

require "spec_helper"

RSpec.describe "Work package graph widget", :js, with_flag: :sprint_reports do
  include Rails.application.routes.url_helpers

  let(:permissions) { %i[view_sprints view_work_packages] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  shared_let(:project) { create(:project) }

  shared_let(:status_new) { create(:status, name: "Graph widget new") }
  shared_let(:status_in_progress) { create(:status, name: "Graph widget in progress") }
  shared_let(:status_closed) { create(:closed_status, name: "Graph widget closed") }

  shared_let(:sprint) do
    create(:sprint,
           project:,
           name: "Sprint 42",
           start_date: Date.yesterday,
           finish_date: Date.tomorrow,
           status: :active)
  end

  shared_let(:other_sprint) { create(:sprint, project:, name: "Sprint 41") }

  shared_let(:work_packages) do
    [
      create(:work_package, project:, sprint:, status: status_new),
      create(:work_package, project:, sprint:, status: status_new),
      create(:work_package, project:, sprint:, status: status_new),
      create(:work_package, project:, sprint:, status: status_in_progress),
      create(:work_package, project:, sprint:, status: status_closed),
      create(:work_package, project:, sprint:, status: status_closed),
      create(:work_package, project:, sprint: other_sprint, status: status_new)
    ]
  end

  current_user { user }

  def visit_sprint_report(sprint)
    visit project_backlogs_sprint_report_path(project, sprint)
  end

  def expect_chart_summary(text)
    within "opce-sprint-work-package-graph" do
      summary_id = find("canvas[aria-labelledby]", wait: 20)["aria-labelledby"]

      expect(page).to have_css("##{summary_id}", exact_text: text, visible: :all)
    end
  end

  it "renders the graph with counts scoped to the sprint" do
    visit_sprint_report(sprint)

    expect(page).to have_element(:"opce-sprint-work-package-graph")

    expect_chart_summary(
      "Bar chart of the work packages currently in the sprint, by status: " \
      "3 #{status_new.name}; 1 #{status_in_progress.name}; 2 #{status_closed.name}."
    )
  end

  context "when the sprint has been completed" do
    shared_let(:completed_sprint) do
      create(:sprint, :completed, project:, name: "Sprint 40",
                                  start_date: 10.days.ago.to_date, finish_date: 3.days.ago.to_date,
                                  started_at: 10.days.ago, completed_at: 3.days.ago)
    end

    shared_let(:reopened_work_package) do
      create(:work_package, project:, sprint: completed_sprint, status: status_new,
                            journals: { 9.days.ago => { status_id: status_closed.id }, 1.day.ago => {} })
    end

    it "charts the statuses the work packages held at completion, not since" do
      visit_sprint_report(completed_sprint)

      expect_chart_summary(
        "Bar chart of the work packages in the sprint when it was completed, by status: " \
        "1 #{status_closed.name}."
      )
    end
  end
end
