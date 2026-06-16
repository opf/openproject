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
require_relative "../../../support/pages/sprints"

RSpec.describe "Sprint index", :js do
  shared_let(:project) { create(:project) }
  shared_let(:sprint) do
    create(:sprint,
           project:,
           name: "Initial sprint",
           start_date: Date.new(2025, 9, 5),
           finish_date: Date.new(2025, 9, 10))
  end
  shared_let(:other_sprint) do
    create(:sprint,
           project:,
           name: "Other sprint",
           start_date: Date.new(2025, 9, 11),
           finish_date: Date.new(2025, 9, 15))
  end
  shared_let(:past_sprint_with_other_name) do
    create(:sprint,
           project:,
           name: "Past sprint with other name",
           start_date: Date.new(2025, 9, 1),
           finish_date: Date.new(2025, 9, 4))
  end
  shared_let(:past_sprint) do
    create(:sprint,
           project:,
           name: "Past sprint",
           start_date: Date.new(2025, 9, 1),
           finish_date: Date.new(2025, 9, 4))
  end

  let(:sprints_page) { Pages::Sprints.new(project) }
  let(:all_permissions) { %i[view_sprints view_work_packages create_sprints] }
  let(:permissions) { all_permissions }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "shows the correct breadcrumb menu" do
    sprints_page.visit!

    within ".PageHeader-breadcrumbs" do
      expect(page).to have_link(href: project_path(project), text: project.name)
      expect(page).to have_link(href: project_backlogs_backlog_path(project), text: "Backlogs")
      expect(page).to have_text("All sprints")
    end
  end

  it "orders the sprints by date first, and then by name" do
    sprints_page.visit!

    sprints_page.expect_sprints_in_order(sprints: [past_sprint, past_sprint_with_other_name, sprint, other_sprint])
  end

  it "shows the correct values per column" do
    create(:work_package, project:, sprint:)
    create(:work_package, project:, sprint: other_sprint)
    create(:work_package, project:, sprint: other_sprint)

    sprints_page.visit!

    sprints_page.expect_sprint_row_values(sprint, work_package_count: 1)
    sprints_page.expect_sprint_row_values(other_sprint, work_package_count: 2)
    sprints_page.expect_sprint_row_values(past_sprint)
  end

  it "paginates the sprints table" do
    sprints_page.set_items_per_page! 2
    sprints_page.visit!

    sprints_page.expect_pagination_range(from: 1, to: 2, total: 4)
    sprints_page.expect_sprint_present(past_sprint)
    sprints_page.expect_sprint_present(past_sprint_with_other_name)
    sprints_page.expect_sprint_not_present(sprint)
    sprints_page.expect_sprint_not_present(other_sprint)

    sprints_page.go_to_page!(2)

    sprints_page.expect_pagination_range(from: 3, to: 4, total: 4)
    sprints_page.expect_sprint_present(sprint)
    sprints_page.expect_sprint_present(other_sprint)
    sprints_page.expect_sprint_not_present(past_sprint)
    sprints_page.expect_sprint_not_present(past_sprint_with_other_name)
  end

  context "when there are no sprints" do
    let(:empty_project) { create(:project) }
    let(:sprints_page) { Pages::Sprints.new(empty_project) }

    current_user { create(:user, member_with_permissions: { empty_project => permissions }) }

    it "shows an empty state in the table" do
      sprints_page.visit!

      sprints_page.expect_empty_state
    end
  end

  context "when a sprint is shared from another project" do
    let(:source_project) do
      create(:project, sprint_sharing: Projects::SprintSharing::SHARE_ALL_PROJECTS)
    end
    let(:receiving_project) do
      create(:project, sprint_sharing: Projects::SprintSharing::RECEIVE_SHARED)
    end
    let(:sprints_page) { Pages::Sprints.new(receiving_project) }
    let!(:shared_sprint) do
      create(:sprint,
             project: source_project,
             name: "Shared sprint",
             status: :in_planning,
             start_date: Date.new(2025, 9, 1),
             finish_date: Date.new(2025, 9, 7))
    end

    current_user do
      create(:user, member_with_permissions: { receiving_project => permissions })
    end

    it "shows the shared sprint and links it to the receiving project" do
      sprints_page.visit!

      sprints_page.expect_sprint_present(shared_sprint)
      sprints_page.expect_sprint_name_link(shared_sprint, href: project_backlogs_backlog_path(receiving_project))
    end
  end

  context "when rendering sprint name links" do
    let!(:planning_sprint) do
      create(:sprint,
             project:,
             name: "Planning sprint",
             status: :in_planning,
             start_date: Date.new(2025, 9, 20),
             finish_date: Date.new(2025, 9, 25))
    end
    let!(:active_sprint) do
      create(:sprint,
             project:,
             name: "Active sprint",
             status: :active,
             start_date: Date.new(2025, 9, 26),
             finish_date: Date.new(2025, 10, 2))
    end
    let!(:active_board) { create(:board_grid, project:, linked: active_sprint, name: "Active sprint board") }
    let!(:completed_sprint) do
      create(:sprint,
             project:,
             name: "Completed sprint",
             status: :completed,
             start_date: Date.new(2025, 8, 1),
             finish_date: Date.new(2025, 8, 10))
    end
    let!(:invalid_status_sprint) do
      create(:sprint,
             project:,
             name: "Invalid status sprint",
             start_date: Date.new(2025, 10, 3),
             finish_date: Date.new(2025, 10, 8)).tap do |sprint|
        sprint.update_column(:status, "invalid")
      end
    end

    it "links the sprint name according to status" do
      sprints_page.visit!

      sprints_page.expect_sprint_name_link(planning_sprint, href: project_backlogs_backlog_path(project))
      sprints_page.expect_sprint_name_link(active_sprint, href: project_work_package_board_path(project, active_board))

      default_columns = Setting.work_package_list_default_columns.map(&:to_s)
      completed_link = project_work_packages_path(
        project,
        query_props: {
          f: [{ n: "sprintId", o: "=", v: [completed_sprint.id.to_s] }],
          t: "position:asc",
          c: default_columns | ["sprint"]
        }.to_json
      )

      sprints_page.expect_sprint_name_link(completed_sprint, href: completed_link)
      sprints_page.expect_sprint_name_not_linked(invalid_status_sprint)
    end
  end
end
