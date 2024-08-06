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
require_relative "support/board_overview_page"

RSpec.describe "Work Package Boards Overview",
               :with_cuprite,
               with_ee: %i[board_view] do
  # The identifier is important to test https://community.openproject.com/wp/29754
  shared_let(:project) do
    create(:project,
           name: "Project 2",
           identifier: "boards",
           enabled_module_names: %i[work_package_tracking board_view])
  end
  shared_let(:other_project) do
    create(:project,
           name: "Project 1",
           enabled_module_names: %i[work_package_tracking board_view])
  end

  shared_let(:management_role) do
    create(:project_role,
           permissions: %i[
             show_board_views
             manage_board_views
             add_work_packages
             view_work_packages
             manage_public_queries
           ])
  end

  shared_let(:view_only_role) do
    create(:project_role,
           permissions: %i[
             show_board_views
             add_work_packages
             view_work_packages
           ])
  end

  shared_let(:admin) do
    create(:admin)
  end
  shared_let(:user_with_full_permissions) do
    create(:user,
           member_with_roles: { project => management_role })
  end
  shared_let(:user_with_limited_permissions) do
    create(:user,
           member_with_roles: { project => view_only_role })
  end
  shared_let(:user_without_permissions) do
    create(:user, member_with_permissions: { project => [] })
  end

  shared_let(:priority) { create(:default_priority) }
  shared_let(:status) { create(:default_status) }

  let(:current_user) { admin }
  let(:board_overview) { Pages::BoardOverview.new }

  before do
    login_as current_user
    board_overview.visit!
  end

  it "renders the global menu with its item selected" do
    board_overview.expect_global_menu_item_selected
  end

  describe "create button" do
    context "as a user with board management permissions" do
      let(:current_user) { user_with_full_permissions }

      it "is shown" do
        board_overview.expect_create_button
      end
    end

    context "as a user with view only permissions" do
      let(:current_user) { user_with_limited_permissions }

      it "is shown" do
        board_overview.expect_no_create_button
      end
    end
  end

  context "when no boards exist" do
    it "displays the empty message" do
      board_overview.expect_no_boards_listed
    end
  end

  context "when boards exist" do
    shared_let(:board_view) do
      create(:board_grid_with_query,
             name: "My board",
             project:)
    end
    shared_let(:other_board_view) do
      create(:board_grid_with_query,
             name: "My other board",
             project:)
    end
    shared_let(:other_project_board_view) do
      create(:board_grid_with_query,
             name: "Other Project Board",
             project: other_project)
    end

    context "as an admin" do
      let(:current_user) { admin }

      it "lists all boards" do
        board_overview.expect_boards_listed(board_view,
                                            other_board_view,
                                            other_project_board_view)
      end
    end

    context "as a project member" do
      let(:current_user) { user_with_full_permissions }

      it "lists the boards" do
        board_overview.expect_boards_listed(board_view, other_board_view)
        board_overview.expect_boards_not_listed(other_project_board_view)
      end
    end

    it "does not render delete links" do
      board_overview.expect_no_delete_buttons(board_view,
                                              other_board_view,
                                              other_project_board_view)
    end

    describe "sorting" do
      it 'allows sorting by "Name", "Project" and "Created on"' do
        # Initial sort is Name ASC
        # We can assert this behavior by expected the order to be
        # 1. board_view
        # 2. other_board_view
        # 3. other_project_board_view
        # upon page load
        aggregate_failures "Sorting by Name" do
          board_overview.expect_boards_listed_in_order(board_view,
                                                       other_board_view,
                                                       other_project_board_view)

          board_overview.click_to_sort_by("Name")
          board_overview.expect_boards_listed_in_order(other_project_board_view,
                                                       other_board_view,
                                                       board_view)
        end

        aggregate_failures "Sorting by Project" do
          board_overview.click_to_sort_by("Project")
          # Sorting is performed on multiple columns at a time, taking into account
          # previous sorting criteria and using the latest clicked column as
          # the first column in the +ORDER BY+ clause and previously sorted by columns after.
          #
          # This is unintuitive to a user who is visually being informed by arrows in table headers
          # that only one column is taken into account for sorting.
          # TODO:
          #   Fix sorting behavior to un-toggle previous columns sorted by or provide
          #   visual feedback of all columns currently being taken into account for
          #   sorting.
          board_overview.expect_boards_listed_in_order(other_project_board_view,
                                                       other_board_view,
                                                       board_view)
          board_overview.click_to_sort_by("Project")
          board_overview.expect_boards_listed_in_order(other_board_view,
                                                       board_view,
                                                       other_project_board_view)
        end

        aggregate_failures "Sorting by Created on" do
          board_overview.click_to_sort_by("Created on")
          board_overview.expect_boards_listed_in_order(board_view,
                                                       other_board_view,
                                                       other_project_board_view)

          board_overview.click_to_sort_by("Created on")
          board_overview.expect_boards_listed_in_order(other_project_board_view,
                                                       other_board_view,
                                                       board_view)
        end
      end
    end

    it "paginates results", with_settings: { per_page_options: "1" } do
      # First page displays the historically last meeting
      board_overview.expect_boards_listed(board_view)
      board_overview.expect_boards_not_listed(other_board_view,
                                              other_project_board_view)
      board_overview.expect_to_be_on_page(1)

      board_overview.to_page(2)
      board_overview.expect_boards_listed(other_board_view)
      board_overview.expect_boards_not_listed(board_view, other_project_board_view)
      board_overview.expect_to_be_on_page(2)

      board_overview.to_page(3)
      board_overview.expect_boards_listed(other_project_board_view)
      board_overview.expect_boards_not_listed(board_view, other_board_view)
      board_overview.expect_to_be_on_page(3)
    end
  end
end
