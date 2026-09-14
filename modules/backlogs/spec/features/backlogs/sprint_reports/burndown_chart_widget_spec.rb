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

  def visit_sprint_report(sprint)
    visit project_backlogs_sprint_report_path(project, sprint)
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
      visit_sprint_report(sprint)

      expect(page).to have_element(:"opce-burndown-chart")
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
      visit_sprint_report(sprint)

      expect(page).to have_no_element(:"opce-burndown-chart")
      expect(page).to have_text("No burndown data available")
    end
  end
end
