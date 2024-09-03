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
require_relative "../support/board_index_page"
require_relative "../support/board_page"

RSpec.describe "Assignee action board", :js,
               with_ee: %i[board_view] do
  let(:bobself_user) do
    create(:user,
           firstname: "Bob",
           lastname: "Self",
           member_with_roles: { project => role })
  end
  let(:admin) { create(:admin) }
  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:project_without_members) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { create(:project_role, permissions:) }

  let(:board_index) { Pages::BoardIndex.new(project) }
  let(:other_board_index) { Pages::BoardIndex.new(project_without_members) }

  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries work_package_assigned]
  end

  let!(:priority) { create(:default_priority) }

  # Set up other assignees

  let!(:foobar_user) do
    create(:user,
           firstname: "Foo",
           lastname: "Bar",
           member_with_roles: { project => role })
  end

  let!(:group) do
    create(:group, name: "Grouped").tap do |group|
      create(:member,
             principal: group,
             project:,
             roles: [role])
    end
  end

  let!(:work_package) do
    create(:work_package,
           project:,
           assigned_to: bobself_user,
           subject: "Some Task")
  end

  context "in a project with members" do
    before do
      login_as(bobself_user)
    end

    it "allows to move a task between two assignees" do
      # Move to the board index page
      board_index.visit!

      # Create new board
      board_page = board_index.create_board title: "My Assignee Board",
                                            action: "Assignee",
                                            expect_empty: true

      # Expect no assignees to be present
      board_page.expect_empty

      # Add myself to the board list
      board_page.add_list option: "Bob Self"
      board_page.expect_list "Bob Self"

      # Add the other user to the board list
      board_page.add_list option: "Foo Bar"
      board_page.expect_list "Foo Bar"

      # Add grouped list
      board_page.add_list option: "Grouped"
      board_page.expect_list "Grouped"

      # There is now only the none option left
      board_page.expect_list_option "(none)"

      board_page.board(reload: true) do |board|
        expect(board.name).to eq "My Assignee Board"
        queries = board.contained_queries
        expect(queries.count).to eq(3)

        bob = queries.first
        foo = queries.second
        grouped = queries.last

        expect(bob.name).to eq "Bob Self"
        expect(foo.name).to eq "Foo Bar"
        expect(grouped.name).to eq "Grouped"

        expect(bob.filters.first.name).to eq :assigned_to_id
        expect(bob.filters.first.values).to eq [bobself_user.id.to_s]

        expect(foo.filters.first.name).to eq :assigned_to_id
        expect(foo.filters.first.values).to eq [foobar_user.id.to_s]

        expect(grouped.filters.first.name).to eq :assigned_to_id
        expect(grouped.filters.first.values).to eq [group.id.to_s]
      end

      # First, expect work package to be assigned to "Bob self"
      # For this, test the Bob self column to contain the work package
      board_page.expect_card "Bob Self", "Some Task"

      # Then, move the work package from one column to the next one
      board_page.move_card(0, from: "Bob Self", to: "Foo Bar")

      # Then, the work package should be in the other column
      # and assigned to "Foo Bar" user
      board_page.expect_card "Foo Bar", "Some Task"
      board_page.expect_card "Bob Self", "Some Task", present: false

      # Expect to have changed the avatar
      within_test_selector("op-wp-single-card--content-assignee") do
        expect(page).to have_css(".op-avatar_mini", text: "FB", wait: 10)
      end

      work_package.reload
      expect(work_package.assigned_to).to eq(foobar_user)

      # Move to group column
      board_page.move_card(0, from: "Foo Bar", to: "Grouped")
      board_page.expect_card "Grouped", "Some Task"
      board_page.expect_card "Foo Bar", "Some Task", present: false
      board_page.expect_card "Bob Self", "Some Task", present: false

      # Expect to have changed the avatar
      within_test_selector("op-wp-single-card--content-assignee") do
        expect(page).to have_css(".op-avatar_mini", text: "G", wait: 10)
      end

      work_package.reload
      expect(work_package.assigned_to).to eq(group)

      # Open remaining in split view
      card = board_page.card_for(work_package)
      split_view = card.open_details_view
      split_view.expect_subject
      split_view.edit_field(:assignee).update("Foo Bar")
      split_view.expect_and_dismiss_toaster message: "Successful update."

      work_package.reload
      expect(work_package.assigned_to).to eq(foobar_user)

      board_page.expect_card("Foo Bar", "Some Task", present: true)
      board_page.expect_card("Grouped", "Some Task", present: false)

      # Reassign to grouped
      board_page.reference "Grouped", work_package
      board_page.expect_card("Grouped", "Some Task", present: true)
      board_page.expect_card("Foo Bar", "Some Task", present: false)
    end
  end

  context "in a project without members" do
    before do
      login_as(admin)
    end

    it "shows a warning when there are no members to add as a list with a link to add a new member" do
      # Move to the board index page
      other_board_index.visit!

      # Create new board
      board_page = other_board_index.create_board action: :Assignee, expect_empty: true

      # Expect no assignees to be present
      board_page.expect_empty

      # Add none to the list
      board_page.add_list option: "(none)"
      board_page.expect_list "(none)"

      board_page.open_add_list_modal
      board_page.add_list_modal_shows_warning true, with_link: true
    end
  end
end
