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

  it "renders the graph with counts scoped to the sprint, and without the group-by select" do
    visit_sprint_report(sprint)

    expect(page).to have_element(:"opce-wp-overview-graph")

    within "opce-wp-overview-graph" do
      expect(page).to have_css("#chart-desc", text: "3 #{status_new.name}", visible: :all)
      expect(page).to have_css("#chart-desc", text: "1 #{status_in_progress.name}", visible: :all)
      expect(page).to have_css("#chart-desc", text: "2 #{status_closed.name}", visible: :all)

      # The group-by select is explicitly hidden for this widget.
      expect(page).to have_no_select
    end
  end
end
