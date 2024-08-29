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
require_relative "../support/onboarding_steps"

# We decrease the notification polling interval because some portions of the JS code rely on something triggering
# the Angular change detection. This is usually done by the notification polling, but we don't want to wait
RSpec.describe "boards onboarding tour",
               :js,
               with_settings: { notifications_polling_interval: 1_000 } do
  let(:next_button) { find(".enjoyhint_next_btn") }
  let(:user) do
    create(:admin,
           member_with_roles: { demo_project => role })
  end
  let(:permissions) do
    %i[
      show_board_views
      manage_board_views
      view_work_packages
      edit_work_packages
      add_work_packages
      manage_public_queries
    ]
  end
  let(:role) { create(:project_role, permissions:) }

  let(:demo_project) do
    create(:project,
           name: "Demo project",
           identifier: "demo-project",
           public: true,
           enabled_module_names: %w[work_package_tracking gantt wiki board_view])
  end
  let!(:wp_1) { create(:work_package, project: demo_project) }

  let!(:demo_board_view) { create(:board_grid_with_query, project: demo_project, name: "Kanban", query:) }
  let!(:demo_basic_board_view) { create(:board_grid_with_query, project: demo_project, name: "Basic board", query:) }
  let(:query) { create(:query, user:, project: demo_project) }

  before do
    OrderedWorkPackage.create(query:, work_package: wp_1, position: 0)
    allow(Setting).to receive(:demo_projects_available).and_return(true)
    allow(Setting).to receive(:boards_demo_data_available).and_return(true)
  end

  after do
    # Clear session to avoid that the onboarding tour starts
    page.execute_script("window.sessionStorage.clear();")
  end

  context "as a new user" do
    context "with an EE token", with_ee: %i[board_view] do
      before do
        login_as user
      end

      it "I see the board onboarding tour in the demo project" do
        # Set the tour parameter so that we can start on the wp page
        visit "/projects/#{demo_project.identifier}/work_packages?start_onboarding_tour=true"

        step_through_onboarding_wp_tour demo_project, wp_1

        step_through_onboarding_board_tour

        step_through_onboarding_main_menu_tour has_full_capabilities: true
      end
    end

    context "without an EE token" do
      before do
        login_as user
      end

      it "I see the board onboarding tour in the demo project" do
        # Set the tour parameter so that we can start on the wp page
        visit "/projects/#{demo_project.identifier}/work_packages?start_onboarding_tour=true"

        step_through_onboarding_wp_tour demo_project, wp_1

        step_through_onboarding_board_tour with_ee_token: false

        step_through_onboarding_main_menu_tour has_full_capabilities: true
      end
    end
  end
end
