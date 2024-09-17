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
require_relative "../../support/onboarding/onboarding_steps"

RSpec.describe "team planner onboarding tour",
               :js,
               with_cuprite: false,
               with_ee: %i[team_planner_view],
               # We decrease the notification polling interval because some portions
               # of the JS code rely on something triggering the Angular change detection.
               # This is usually done by the notification polling, but we don't want to wait
               with_settings: { notifications_polling_interval: 1_000 } do
  let(:next_button) { find(".enjoyhint_next_btn") }

  let(:demo_project) do
    create(:project,
           name: "Demo project",
           identifier: "demo-project",
           public: true,
           enabled_module_names: %w[work_package_tracking gantt wiki team_planner_view])
  end

  let(:user) do
    create(:admin,
           member_with_permissions: { demo_project => %w[view_work_packages edit_work_packages add_work_packages
                                                         view_team_planner manage_team_planner save_queries
                                                         manage_public_queries work_package_assigned] })
  end

  let!(:wp1) do
    create(:work_package,
           project: demo_project,
           assigned_to: user,
           start_date: Time.zone.today,
           due_date: Time.zone.today)
  end

  let(:query) { create(:query, user:, project: demo_project, public: true, name: "Team planner") }
  let(:team_plan) do
    create(:view_team_planner,
           query:,
           assignees: [user],
           projects: [demo_project])
  end

  before do
    team_plan
    login_as user

    allow(Setting).to receive(:demo_projects_available).and_return(true)
    allow(Setting).to receive(:demo_view_of_type_team_planner_seeded).and_return(true)
  end

  after do
    # Clear session to avoid that the onboarding tour starts
    page.execute_script("window.sessionStorage.clear();")
  end

  context "as a new user" do
    it "I see the team planner onboarding tour in the demo project" do
      # Set the tour parameter so that we can start on the wp page
      visit "/projects/#{demo_project.identifier}/work_packages?start_onboarding_tour=true"

      step_through_onboarding_wp_tour demo_project, wp1

      step_through_onboarding_team_planner_tour

      step_through_onboarding_main_menu_tour has_full_capabilities: true
    end
  end
end
