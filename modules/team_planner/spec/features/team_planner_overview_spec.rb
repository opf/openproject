# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"
require_relative "shared_context"

RSpec.describe "Team planner overview",
               :with_cuprite,
               with_ee: %i[team_planner_view] do
  # The order the Projects are created in is important. By naming `project` alphanumerically
  # after `other_project`, we can ensure that subsequent specs that assert sorting is
  # correct for the right reasons (sorting by Project name and not id)
  shared_let(:project) { create(:project, name: "Project 2") }
  shared_let(:other_project) { create(:project, name: "Project 1") }

  shared_let(:admin) { create(:admin) }
  shared_let(:user_with_full_permissions) do
    create(:user,
           member_with_permissions: { project => %w[
             view_work_packages edit_work_packages add_work_packages
             view_team_planner manage_team_planner
             save_queries manage_public_queries
             work_package_assigned
           ] })
  end
  shared_let(:user_with_limited_permissions) do
    create(:user,
           firstname: "Bernd",
           member_with_permissions: { project => %w[view_work_packages view_team_planner] })
  end

  let(:team_planner) { Pages::TeamPlanner.new(project) }

  let(:current_user) { admin }

  before do
    login_as current_user
    visit team_planners_path
  end

  it "renders a global menu with its item selected" do
    within "#main-menu" do
      expect(page).to have_css ".selected", text: "Team planners"
    end
  end

  it "shows a create button" do
    team_planner.expect_create_button
  end

  context "with no views" do
    it "shows an empty overview action" do
      team_planner.expect_no_views_rendered
    end
  end

  context "with existing views" do
    shared_let(:query) do
      create(:public_query, user: user_with_full_permissions, project:)
    end
    shared_let(:team_plan) do
      create(:view_team_planner, query:)
    end

    shared_let(:other_query) do
      create(:public_query, user: user_with_full_permissions, project:)
    end
    shared_let(:other_team_plan) do
      create(:view_team_planner, query: other_query)
    end

    shared_let(:private_query) do
      create(:private_query, user: user_with_full_permissions, project:)
    end
    shared_let(:private_team_plan) do
      create(:view_team_planner, query: private_query)
    end

    shared_let(:other_project_query) do
      create(:public_query, user: user_with_full_permissions, project: other_project)
    end
    shared_let(:other_project_team_plan) do
      create(:view_team_planner, query: other_project_query)
    end

    context "as an admin" do
      let(:current_user) { admin }

      it "shows those views" do
        team_planner.expect_views_rendered(query, other_query, other_project_query)

        team_planner.expect_no_delete_buttons_for(query, other_query, other_project_query)
      end
    end

    context "as a user with full permissions within a project" do
      let(:current_user) { user_with_full_permissions }

      it "shows views in projects the user is a member of" do
        team_planner.expect_views_rendered(query, private_query, other_query)

        team_planner.expect_no_delete_buttons_for(query, private_query, other_query)
      end

      context "and as the author of a private view" do
        it "shows my private view" do
          team_planner.expect_views_rendered(query, private_query, other_query)

          team_planner.expect_no_delete_buttons_for(query, private_query, other_query)
        end
      end
    end

    context "as a user with limited permissions within a project" do
      let(:current_user) { user_with_limited_permissions }

      it "does not show the management buttons" do
        team_planner.expect_no_create_button
        team_planner.expect_no_delete_buttons_for(query, other_query)
      end

      it "shows views in projects the user is a member of" do
        team_planner.expect_views_rendered(query, other_query)
      end
    end

    describe "sorting" do
      let(:current_user) { admin }

      it "allows sorting by all columns" do
        # Initial sort is Name ASC
        # We can assert this by expecting the order to be
        # 1. query
        # 2. other_query
        # 3. other_project_query
        aggregate_failures "Sorting by Name" do
          team_planner.expect_views_listed_in_order(query, other_query, other_project_query)
          team_planner.click_to_sort_by("Name")
          team_planner.expect_views_listed_in_order(other_project_query, other_query, query)
        end

        aggregate_failures "Sorting by Project" do
          team_planner.click_to_sort_by("Project")
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
          team_planner.expect_views_listed_in_order(other_project_query, other_query, query)
          team_planner.click_to_sort_by("Project")
          team_planner.expect_views_listed_in_order(other_query, query, other_project_query)
        end

        aggregate_failures "Sorting by Created on" do
          team_planner.click_to_sort_by("Created on")
          team_planner.expect_views_listed_in_order(query, other_query, other_project_query)
          team_planner.click_to_sort_by("Created on")
          team_planner.expect_views_listed_in_order(other_project_query, other_query, query)
        end
      end
    end
  end
end
