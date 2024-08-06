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

RSpec.describe "Subtasks action board", :js, with_ee: %i[board_view] do
  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { create(:project_role, permissions:) }

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let(:board_index) { Pages::BoardIndex.new(project) }

  let!(:priority) { create(:default_priority) }
  let!(:open_status) { create(:default_status, name: "Open") }
  let!(:parent) { create(:work_package, project:, subject: "Parent WP", status: open_status) }
  let!(:child) { create(:work_package, project:, subject: "Child WP", parent:, status: open_status) }

  before do
    login_as(user)
  end

  context "without the manage_subtasks permission" do
    let(:permissions) do
      %i[show_board_views manage_board_views add_work_packages
         edit_work_packages view_work_packages manage_public_queries]
    end

    it "does not allow to move work packages" do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: "Parent-child", expect_empty: true

      # Expect we can add a work package column
      board_page.add_list option: "Parent WP"
      board_page.expect_list "Parent WP"

      # Expect one work package there
      board_page.expect_card "Parent WP", "Child"
      board_page.expect_movable "Parent WP", "Child", movable: false
    end
  end

  context "with all permissions" do
    let!(:other_wp) { create(:work_package, project:, subject: "Other WP", status: open_status) }

    let(:permissions) do
      %i[show_board_views manage_board_views add_work_packages
         edit_work_packages view_work_packages manage_public_queries manage_subtasks]
    end

    it "allows management of subtasks work packages" do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board title: "My Parent-child Board",
                                            action: "Parent-child",
                                            expect_empty: true

      # Expect we can add a child 1
      board_page.add_list option: "Parent WP"
      board_page.expect_list "Parent WP"

      # Expect one work package there
      board_page.expect_card "Parent WP", "Child"

      # Expect move permission to be granted
      board_page.expect_movable "Parent WP", "Child", movable: true

      board_page.board(reload: true) do |board|
        expect(board.name).to eq "My Parent-child Board"
        queries = board.contained_queries
        expect(queries.count).to eq(1)

        query = queries.first
        expect(query.name).to eq "Parent WP"

        expect(query.filters.first.name).to eq :parent
        expect(query.filters.first.values).to eq [parent.id.to_s]
      end

      # Create new list
      board_page.add_list option: "Other WP"
      board_page.expect_list "Other WP"

      board_page.expect_cards_in_order "Other WP"

      # Add item
      board_page.add_card "Parent WP", "Second child"
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 2
      first = queries.find_by(name: "Parent WP")
      second = queries.find_by(name: "Other WP")
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      wp = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).first
      expect(wp.parent_id).to eq parent.id

      # Move item to Child 2 list
      board_page.move_card(0, from: "Parent WP", to: "Other WP")
      board_page.wait_for_lists_reload

      board_page.expect_card("Parent WP", "Second child", present: false)
      board_page.expect_card("Other WP", "Second child", present: true)

      # Expect work package to be saved in query second
      sleep 2
      retry_block do
        expect(first.reload.ordered_work_packages).to be_empty
        expect(second.reload.ordered_work_packages.count).to eq(1)
      end

      wp = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).first
      expect(wp.parent_id).to eq other_wp.id

      # Reference back
      board_page.reference("Parent WP", wp)

      board_page.expect_card("Parent WP", "Second child", present: true)
      board_page.expect_card("Other WP", "Second child", present: false)
    end

    it "prevents adding a work package to its own column" do
      board_index.visit!
      board_page = board_index.create_board action: "Parent-child", expect_empty: true
      board_page.add_list option: "Parent WP"
      board_page.expect_list "Parent WP"
      board_page.expect_card "Parent WP", "Child"

      board_page.add_list option: "Child WP"
      board_page.expect_list "Child WP"

      # Try to move child to itself
      board_page.move_card(0, from: "Parent WP", to: "Child WP")

      board_page.expect_and_dismiss_toaster type: :error,
                                            message: I18n.t("js.boards.error_cannot_move_into_self")

      child.reload
      expect(child.parent).to eq parent
    end
  end

  describe "with German language (regression #40031)" do
    let!(:german_user) { create(:admin, language: :de) }
    let(:permissions) do
      %i[show_board_views manage_board_views add_work_packages
         edit_work_packages view_work_packages manage_public_queries]
    end

    before do
      I18n.locale = :de
      login_as german_user
    end

    it "can add lists via the add modal" do
      board_index.visit!
      board_page = board_index.create_board action: I18n.t("js.boards.board_type.board_type_title.subtasks"), expect_empty: true
      board_page.add_list option: "Parent WP"
      board_page.expect_list "Parent WP"
      board_page.expect_card "Parent WP", "Child"
    end
  end
end
