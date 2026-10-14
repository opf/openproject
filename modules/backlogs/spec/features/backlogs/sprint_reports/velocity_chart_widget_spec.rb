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

RSpec.describe "Velocity chart widget", :js, with_flag: :sprint_reports do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:done_status) { create(:status, is_closed: true) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages show_board_views] })
  end

  shared_let(:previous_sprint) do
    create(:sprint,
           project:,
           name: "Sprint 1",
           status: :completed,
           start_date: 4.weeks.ago.to_date,
           finish_date: 2.weeks.ago.to_date,
           started_at: 4.weeks.ago,
           completed_at: 2.weeks.ago)
  end
  shared_let(:sprint) do
    create(:sprint,
           project:,
           name: "Sprint 2",
           status: :active,
           start_date: 1.week.ago.to_date,
           finish_date: 1.week.from_now.to_date,
           started_at: 1.week.ago)
  end

  current_user { user }

  before do
    travel_to(5.weeks.ago) do
      create(:work_package, project:, sprint: previous_sprint, status: done_status, story_points: 3)
    end
    travel_to(2.weeks.ago) do
      create(:work_package, project:, sprint:, status: done_status, story_points: 5)
    end
  end

  def visit_sprint_report(sprint)
    visit project_backlogs_sprint_report_path(project, sprint)
  end

  it "renders the velocity of the active sprint and the average" do
    visit_sprint_report(sprint)

    expect(page).to have_text("Velocity chart")

    within("#backlogs-sprint-reports-widgets-velocity-chart-box") do
      expect(page).to have_text("Sprint 2: 5 SP")
      expect(page).to have_text("Average of last 2 sprints: 4 SP")
      expect(page).to have_css("opce-velocity-chart canvas")
    end
  end

  it "renders only the sprints up to the viewed completed sprint" do
    visit_sprint_report(previous_sprint)

    within("#backlogs-sprint-reports-widgets-velocity-chart-box") do
      expect(page).to have_text("Sprint 1: 3 SP")
      expect(page).to have_text("Average of last sprint: 3 SP")
    end
  end

  context "when the project allows multiple active sprints" do
    before { project.update!(allow_multiple_active_sprints: true) }

    it "does not render the velocity chart" do
      visit_sprint_report(sprint)

      expect(page).to have_text("Sprint 2")
      expect(page).to have_no_text("Velocity chart")
    end
  end
end
