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
require_relative "shared_context"

RSpec.describe "Team planner index", :js, :with_cuprite, with_ee: %i[team_planner_view] do
  shared_let(:project) do
    create(:project)
  end

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

  let(:current_user) { user_with_full_permissions }

  before do
    login_as current_user
    visit project_team_planners_path(project)
  end

  it "shows a create button" do
    team_planner.expect_create_button
  end

  it "can create an action through the sidebar" do
    find_test_selector("team_planner--create-button").click

    team_planner.expect_no_toaster
    team_planner.expect_title
  end

  context "with no views" do
    it "shows an empty index action" do
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

    context "as a user with full permissions within a project" do
      let(:current_user) { user_with_full_permissions }

      it "shows views" do
        team_planner.expect_views_rendered(query, private_query, other_query)
      end

      it "shows management buttons" do
        team_planner.expect_delete_buttons_for(query, private_query, other_query)
      end

      context "and as the author of a private view" do
        it "shows my private view" do
          team_planner.expect_views_rendered(query, private_query, other_query)

          team_planner.expect_delete_buttons_for(query, private_query, other_query)
        end
      end
    end

    context "as a user with limited permissions within a project" do
      let(:current_user) { user_with_limited_permissions }

      it "does not show the management buttons" do
        team_planner.expect_no_create_button
        team_planner.expect_no_delete_buttons_for(query, other_query)
      end

      it "shows public views only" do
        team_planner.expect_views_rendered(query, other_query)
      end
    end
  end
end
