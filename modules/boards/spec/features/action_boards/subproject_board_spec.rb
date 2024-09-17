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

RSpec.describe "Subproject action board", :js, with_ee: %i[board_view] do
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:type) { create(:type_standard) }
  let(:project) do
    create(:project, name: "Parent", types: [type], enabled_module_names: %i[work_package_tracking board_view])
  end
  let(:subproject1) do
    create(:project, parent: project, name: "Child 1", types: [type], enabled_module_names: %i[work_package_tracking])
  end
  let(:subproject2) do
    create(:project, parent: project, name: "Child 2", types: [type], enabled_module_names: %i[work_package_tracking])
  end
  let(:role) { create(:project_role, permissions:) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries move_work_packages]
  end

  let!(:priority) { create(:default_priority) }
  let!(:open_status) { create(:default_status, name: "Open") }
  let!(:work_package) { create(:work_package, project: subproject1, subject: "Foo", status: open_status) }

  before do
    subproject1
    subproject2
    project.reload
    login_as(user)
  end

  context "without the move_work_packages permission" do
    let(:permissions) do
      %i[show_board_views manage_board_views add_work_packages
         edit_work_packages view_work_packages manage_public_queries]
    end

    let(:user) do
      create(:user, member_with_roles: { project => role, subproject1 => role, subproject2 => role })
    end

    it "does not allow to move work packages" do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: "Subproject", expect_empty: true

      # Expect we can add a child 1
      board_page.add_list option: "Child 1"
      board_page.expect_list "Child 1"

      # Expect one work package there
      board_page.expect_card "Child 1", "Foo"
      board_page.expect_movable "Child 1", "Foo", movable: false
    end
  end

  context "with permissions in all subprojects" do
    let(:user) do
      create(:user, member_with_roles: { project => role, subproject1 => role, subproject2 => role })
    end

    let(:only_parent_user) do
      create(:user,
             member_with_roles: { project => role })
    end

    it "allows management of subproject work packages" do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board title: "My Subproject Board",
                                            action: "Subproject",
                                            expect_empty: true

      # Expect we can add a child 1
      board_page.add_list option: "Child 1"
      board_page.expect_list "Child 1"

      # Expect one work package there
      board_page.expect_card "Child 1", "Foo"

      # Expect move permission to be granted
      board_page.expect_movable "Child 1", "Foo", movable: true

      board_page.board(reload: true) do |board|
        expect(board.name).to eq "My Subproject Board"
        queries = board.contained_queries
        expect(queries.count).to eq(1)

        query = queries.first
        expect(query.name).to eq "Child 1"

        expect(query.filters.first.name).to eq :only_subproject_id
        expect(query.filters.first.values).to eq [subproject1.id.to_s]
      end

      # Create new list
      board_page.add_list option: "Child 2"
      board_page.expect_list "Child 2"

      board_page.expect_cards_in_order "Child 2"

      # Add item
      board_page.add_card "Child 1", "Task 1"
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 2
      first = queries.find_by(name: "Child 1")
      second = queries.find_by(name: "Child 2")
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :project_id)
      expect(subjects).to contain_exactly(["Task 1", subproject1.id])

      # Move item to Child 2 list
      board_page.move_card(0, from: "Child 1", to: "Child 2")

      # TODO: The board reloading is flickering after the move_card action.
      # It needs to be fixed.

      board_page.expect_card("Child 1", "Task 1", present: false)
      board_page.expect_card("Child 2", "Task 1", present: true)

      # Expect work package to be saved in query second
      retry_block(args: { tries: 3, base_interval: 5 }) do
        raise "first should be empty" if first.reload.ordered_work_packages.any?
        raise "second should have one item" if second.reload.ordered_work_packages.count != 1
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :project_id)
      expect(subjects).to contain_exactly(["Task 1", subproject2.id])
    end
  end

  context "with permissions in only one subproject" do
    let(:user) do
      create(:user,
             # The membership in subproject2 gets removed later on
             member_with_roles: { project => role, subproject1 => role, subproject2 => role })
    end

    let!(:board) do
      create(:subproject_board,
             project:,
             projects_columns: [subproject1, subproject2])
    end

    let(:board_page) { Pages::Board.new(board) }
    let!(:invisible_work_package) do
      create(:work_package, project: subproject2, status: open_status)
    end

    before do
      # The membership needs to first be present in order to create the board
      # which is created as the current_user, in this case :user.
      # After setup, we do not want to have the user to have the permissions within the project any more
      # as this is the goal of the test.
      Member.where(project: subproject2, principal: user).destroy_all
    end

    it "displays only the columns for the projects in which the current user has permission" do
      board_page.visit!

      board_page.expect_card subproject1.name, work_package.subject

      # No error is to be displayed as erroneous columns are filtered out
      expect(page).to have_no_css(".op-toast.-error")
      board_page.expect_no_list(subproject2.name)

      expect(page)
        .to have_no_content invisible_work_package.subject
    end
  end

  context "with an archived subproject" do
    let(:user) do
      create(:user, member_with_roles: { project => role, subproject1 => role, subproject2 => role })
    end

    let!(:board) do
      create(:subproject_board,
             project:,
             projects_columns: [subproject1])
    end

    let(:board_page) { Pages::Board.new(board) }

    before do
      # Archive the second project
      subproject2.update! active: false
    end

    it "displays only the columns for the projects in which the current user has permission" do
      board_page.visit!

      board_page.expect_list subproject1.name
      board_page.expect_no_list(subproject2.name)

      board_page.open_and_fill_add_list_modal subproject2.name

      expect(page).to have_no_css(".ng-option", text: subproject2.name)
    end
  end
end
