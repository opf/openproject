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
require_relative "../../support/pages/backlog"
require_relative "../../../../boards/spec/features/support/board_page"

RSpec.describe "Start and finish sprints", :js do
  shared_let(:project) do
    create(:project, enabled_module_names: %i[backlogs work_package_tracking board_view])
  end
  shared_let(:default_status) { create(:default_status) }

  let(:permissions) do
    %i[view_sprints add_work_packages view_work_packages create_sprints manage_sprint_items
       start_complete_sprint show_board_views manage_board_views save_queries
       manage_public_queries]
  end
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:planning_page) { Pages::Backlog.new(project) }
  let(:story_type) { create(:type_feature) }
  let(:task_type) do
    type = create(:type_task)
    project.types << type

    type
  end
  let(:task_statuses) { task_type.statuses }
  let!(:first_sprint) do
    create(:sprint,
           project:,
           start_date: Date.new(2025, 9, 5),
           finish_date: Date.new(2025, 9, 15))
  end
  let!(:second_sprint) do
    create(:sprint,
           project:,
           start_date: Date.new(2025, 9, 16),
           finish_date: Date.new(2025, 9, 26))
  end
  let!(:closed_sprint) do
    create(:sprint,
           project:,
           status: "completed",
           start_date: Date.new(2025, 8, 25),
           finish_date: Date.new(2025, 9, 4))
  end

  before do
    login_as(user)

    create(:workflow, type: task_type, old_status: default_status, new_status: default_status, role: create(:project_role))

    planning_page.visit!
  end

  it "starts the sprint and redirects to the board" do
    planning_page.click_start_sprint_button(first_sprint)

    expect_and_dismiss_flash type: :success, message: "The sprint was started."

    sprint = first_sprint.reload
    board = sprint.task_board_for(project)
    board_page = Pages::Board.new(board)

    expect(page).to have_current_path(%r{/projects/#{project.identifier}/boards/\d+})
    expect(sprint).to be_active
    expect(board).to be_present

    board_page.expect_path
    task_statuses.each do |status|
      board_page.expect_list(status.name)
    end

    board_page.board(reload: true) do |persisted_board|
      expect(persisted_board.linked).to eq(sprint)
      expect(persisted_board.options[:type]).to eq("action")
      expect(persisted_board.options[:attribute]).to eq("status")
      expect(persisted_board.options[:filters]).to eq(
        [{ sprint_id: { operator: "=", values: [sprint.id.to_s] } }]
      )

      queries = persisted_board.contained_queries.to_a
      expect(queries.count).to eq(task_statuses.count)

      query_status_values = queries.map do |query|
        status_filter = query.filters.find { |filter| filter.name == :status_id }

        expect(status_filter).not_to be_nil

        status_filter.values
      end

      expect(query_status_values).to match_array(task_statuses.map { |status| [status.id.to_s] })
    end
  end

  context "when the sprint is active" do
    let!(:first_sprint) do
      create(:sprint,
             project:,
             status: "active",
             start_date: Date.new(2025, 9, 5),
             finish_date: Date.new(2025, 9, 15))
    end
    let!(:task_board) { create(:board_grid_with_query, project:, linked: first_sprint) }

    it "completes the sprint and returns to the backlog" do
      planning_page.click_complete_sprint_button(first_sprint)

      planning_page.expect_current_path
      expect_and_dismiss_flash type: :success, message: "The sprint was completed."
      expect(first_sprint.reload).to be_completed
      planning_page.expect_sprint_names_in_order(second_sprint.name)
    end

    context "with unfinished work packages" do
      let(:closed_status) { create(:status, is_closed: true) }
      let!(:closed_work_package) do
        create(:work_package,
               project:,
               subject: "Finished work package",
               sprint: first_sprint,
               status: closed_status)
      end
      let!(:unfinished_work_package1) do
        create(:work_package,
               subject: "First unfinished work package",
               sprint: first_sprint,
               project:)
      end
      let!(:unfinished_work_package2) do
        create(:work_package,
               subject: "Second unfinished work package",
               sprint: first_sprint,
               project:)
      end
      let!(:wp_in_next_sprint) do
        create(:work_package,
               subject: "Work package in next sprint",
               sprint: second_sprint,
               project:)
      end
      let!(:backlog_work_package) do
        create(:work_package,
               subject: "Backlog work package",
               sprint: nil,
               project:)
      end

      # This exists to test that sprints just present in the project
      # because of work packages but not because they are genuinely shared, are not options to move
      # work packages to.
      let!(:sprint_from_other_project) do
        create(:sprint,
               project: create(:project),
               start_date: Date.new(2025, 9, 5),
               finish_date: Date.new(2025, 9, 15)) do |sprint|
          create(:work_package,
                 subject: "Work package in other sprint",
                 sprint:,
                 project:)
        end
      end

      before do
        # closed_status is a lazy `let` created after the shared_let(:project), so
        # it is not present when the backlogs module is first enabled on the project
        # and therefore not auto-seeded by the MODULE_ENABLED event. We add it manually here.
        project.done_statuses << closed_status unless project.done_statuses.include?(closed_status)
      end

      it "allows moving unfinished work packages to the next sprint" do
        planning_page.click_to_complete_sprint(first_sprint)

        planning_page.expect_sprint_completing_modal

        planning_page.expect_sprints_to_choose_for_moving_unfinished_work_packages_to second_sprint
        planning_page.choose_to_move_unfinished_work_packages_to_sprint second_sprint.name

        planning_page.expect_and_dismiss_flash type: :success, message: "The sprint was completed."

        planning_page.expect_sprint_names_in_order(sprint_from_other_project.name, second_sprint.name)

        planning_page.expect_work_packages_in_sprint_in_order(second_sprint,
                                                              work_packages: [unfinished_work_package1,
                                                                              unfinished_work_package2,
                                                                              wp_in_next_sprint])

        planning_page.expect_work_packages_in_inbox_in_order(work_packages: [backlog_work_package])
      end

      it "allows moving unfinished work packages to the top of the backlog" do
        planning_page.click_to_complete_sprint(first_sprint)

        planning_page.expect_sprint_completing_modal
        planning_page.choose_to_move_unfinished_work_packages_to_top_of_backlog

        planning_page.expect_and_dismiss_flash type: :success, message: "The sprint was completed."

        planning_page.expect_sprint_names_in_order(sprint_from_other_project.name, second_sprint.name)

        planning_page.expect_work_packages_in_inbox_in_order(work_packages: [unfinished_work_package1,
                                                                             unfinished_work_package2,
                                                                             backlog_work_package])
      end

      it "allows moving unfinished work packages to the bottom of the backlog" do
        planning_page.click_to_complete_sprint(first_sprint)

        planning_page.expect_sprint_completing_modal
        planning_page.choose_to_move_unfinished_work_packages_to_bottom_of_backlog

        planning_page.expect_and_dismiss_flash type: :success, message: "The sprint was completed."

        planning_page.expect_sprint_names_in_order(sprint_from_other_project.name, second_sprint.name)

        planning_page.expect_work_packages_in_inbox_in_order(work_packages: [backlog_work_package,
                                                                             unfinished_work_package1,
                                                                             unfinished_work_package2])
      end
    end
  end
end
