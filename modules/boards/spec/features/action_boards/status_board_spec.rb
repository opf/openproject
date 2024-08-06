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
require_relative "../support//board_index_page"
require_relative "../support/board_page"

RSpec.describe "Status action board", :js, with_ee: %i[board_view] do
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { create(:project_role, permissions:) }
  let!(:anon_role) do
    create(:anonymous_role, permissions: %i[view_project view_work_packages view_wiki_pages show_board_views])
  end

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages move_work_packages view_work_packages manage_public_queries]
  end

  let!(:priority) { create(:default_priority) }
  let!(:open_status) { create(:default_status, name: "Open") }
  let!(:whatever_status) { create(:status, name: "Whatever") }
  let!(:closed_status) { create(:status, is_closed: true, name: "Closed") }
  let!(:work_package) { create(:work_package, project:, subject: "Foo", status: whatever_status) }

  let(:filters) { Components::WorkPackages::Filters.new }

  let!(:workflow_type) do
    create(:workflow,
           type:,
           role:,
           old_status_id: open_status.id,
           new_status_id: closed_status.id)
  end
  let!(:workflow_type_back) do
    create(:workflow,
           type:,
           role:,
           old_status_id: whatever_status.id,
           new_status_id: open_status.id)
  end
  let!(:workflow_type_back_open) do
    create(:workflow,
           type:,
           role:,
           old_status_id: closed_status.id,
           new_status_id: open_status.id)
  end
  let!(:workflow_type_open_to_whatever) do
    create(:workflow,
           type:,
           role:,
           old_status_id: open_status.id,
           new_status_id: whatever_status.id)
  end

  before do
    project
    login_as(user)
  end

  context "with full boards permissions" do
    it "can add a case-insensitive list (Regression #35744)" do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: "Status"

      # expect lists of default status
      board_page.expect_list "Open"

      board_page.add_list option: "Closed", query: "closed"
      board_page.expect_list "Closed"
    end

    it "does not change moving card project when filtering on projects (Bug #44895)" do
      other_project = create(:project,
                             types: [type],
                             enabled_module_names: %i[work_package_tracking board_view],
                             members: { user => role })
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: "Status"

      board_page.add_list option: "Whatever"
      board_page.expect_list "Whatever"

      # Add item
      board_page.add_card "Open", "New Task"

      # Add projects filter
      board_page.filters.open
      # binding.pry
      # board_page.filters.add_filter('Project')
      # board_page.filters.add_filter_by('Project', 'is (OR)', [other_project.name, project.name])

      board_page.filters.add_filter_by("Project", "is not", other_project.name)
      board_page.filters.expect_filter_count 1

      # wait for the chain of debounces:
      # - 250ms in frontend/src/app/features/work-packages/components/filters/filter-project/filter-project.component.ts
      # - 500ms in frontend/src/app/features/work-packages/components/filters/query-filters/query-filters.component.ts
      # - 250ms in frontend/src/app/features/boards/board/board-filter/board-filter.component.ts
      sleep(1)
      # wait for the loading indicators to disappear
      loading_indicator_saveguard

      # move card
      board_page.move_card(0, from: "Open", to: "Whatever")
      board_page.wait_for_lists_reload

      board_page.expect_card("Whatever", "New Task", present: true)

      wp_task = WorkPackage.find_by(subject: "New Task")

      expect(wp_task.status).to eq(whatever_status), "Moving the card should have updated the status"
      expect(wp_task.project).to eq(project), "Moving the card should not change the project"
    end

    it "allows management of boards", with_settings: { login_required: false } do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board title: "My Status Board",
                                            action: "Status"

      # expect lists of default status
      board_page.expect_list "Open"

      board_page.add_list option: "Closed"
      board_page.expect_list "Closed"

      board_page.board(reload: true) do |board|
        expect(board.name).to eq "My Status Board"
        queries = board.contained_queries
        expect(queries.count).to eq(2)

        open = queries.first
        closed = queries.last

        expect(open.name).to eq "Open"
        expect(closed.name).to eq "Closed"

        expect(open.filters.first.name).to eq :status_id
        expect(open.filters.first.values).to eq [open_status.id.to_s]

        expect(closed.filters.first.name).to eq :status_id
        expect(closed.filters.first.values).to eq [closed_status.id.to_s]
      end

      # Create new list
      board_page.add_list option: "Whatever"
      board_page.expect_list "Whatever"

      # Add item
      board_page.add_card "Open", "Task 1"
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 3
      first = queries.find_by(name: "Open")
      second = queries.find_by(name: "Closed")
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :status_id)
      expect(subjects).to contain_exactly(["Task 1", open_status.id])

      # Move item to Closed
      board_page.move_card(0, from: "Open", to: "Closed")
      board_page.expect_card("Open", "Task 1", present: false)
      board_page.expect_card("Closed", "Task 1", present: true)

      # Expect work package to be saved in query second
      sleep 2
      retry_block do
        expect(first.reload.ordered_work_packages).to be_empty
        expect(second.reload.ordered_work_packages.count).to eq(1)
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :status_id)
      expect(subjects).to contain_exactly(["Task 1", closed_status.id])

      # Try to drag to whatever, which has no workflow
      board_page.move_card(0, from: "Closed", to: "Whatever")
      board_page.expect_and_dismiss_toaster(
        type: :error,
        message: "Status is invalid because no valid transition exists from old to new status for the current user's roles."
      )
      board_page.expect_card("Open", "Task 1", present: false)
      board_page.expect_card("Whatever", "Task 1", present: false)
      board_page.expect_card("Closed", "Task 1", present: true)

      # Add filter
      # Filter for Task
      filters.expect_filter_count 0
      filters.open

      # Expect that status is not available for global filter selection
      filters.open_available_filter_list
      filters.expect_available_filter "Status", present: false

      filters.quick_filter "Task"
      board_page.expect_changed
      sleep 2

      board_page.expect_card("Closed", "Task 1", present: true)
      board_page.expect_card("Whatever", work_package.subject, present: false)

      # Expect query props to be present
      url = URI.parse(page.current_url).query
      expect(url).to include("query_props=")

      # Save that filter
      board_page.save

      # Expect filter to be saved in board
      board_page.board(reload: true) do |board|
        expect(board.options[:filters]).to eq [{ search: { operator: "**", values: ["Task"] } }]
      end

      # Revisit board
      board_page.visit!

      # Expect filter to be present
      filters.expect_filter_count 1
      filters.open
      filters.expect_quick_filter "Task"

      # No query props visible
      board_page.expect_not_changed

      # Remove query
      board_page.remove_list "Whatever"
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq(2)
      expect(queries.first.name).to eq "Open"
      expect(queries.last.name).to eq "Closed"
      expect(queries.first.ordered_work_packages).to be_empty

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id))
      expect(subjects.pluck(:subject, :status_id)).to contain_exactly(["Task 1", closed_status.id])

      # Open remaining in split view
      wp = second.ordered_work_packages.first.work_package
      card = board_page.card_for(wp)
      split_view = card.open_details_view
      split_view.expect_subject
      split_view.edit_field(:status).update("Open")
      split_view.expect_and_dismiss_toaster message: "Successful update."

      wp.reload
      expect(wp.status).to eq(open_status)

      board_page.expect_card("Open", "Task 1", present: true)
      board_page.expect_card("Closed", "Task 1", present: false)

      # Re-add task 1 to closed
      board_page.reference("Closed", subjects.first)

      board_page.expect_card("Open", "Task 1", present: false)
      board_page.expect_card("Closed", "Task 1", present: true)

      aggregate_failures "allows to access the board publicly (Regression #51850)" do
        project.update!(public: true)
        login_as User.anonymous

        board_page.visit!
        board_page.expect_card("Closed", "Task 1", present: true)
      end
    end

    it "shows the default column only once (regression #40858)" do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: "Status"

      # expect lists of default status
      board_page.expect_list "Open"
      expect(board_page.list_count).to eq(1)

      board_index.visit!
      # Create another status board
      second_board_page = board_index.create_board action: "Status", via_toolbar: false

      # Expect only one list with the default status
      second_board_page.expect_list "Open"
      expect(second_board_page.list_count).to eq(1)
    end
  end
end
