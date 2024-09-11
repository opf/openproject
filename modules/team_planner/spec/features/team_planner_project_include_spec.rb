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
require "features/work_packages/project_include/project_include_shared_examples"
require_relative "../support/pages/team_planner"

RSpec.describe "Team planner project include", :js, with_ee: %i[team_planner_view] do
  shared_let(:enabled_modules) { %w[work_package_tracking team_planner_view] }
  shared_let(:permissions) do
    %w[view_work_packages edit_work_packages add_work_packages
       view_team_planner manage_team_planner
       save_queries manage_public_queries]
  end

  it_behaves_like "has a project include dropdown" do
    let(:work_package_view) { Pages::TeamPlanner.new(project) }
    let(:dropdown) { Components::ProjectIncludeComponent.new }

    it "correctly filters work packages by project" do
      dropdown.expect_count 1

      # Make sure the filter gets set once
      dropdown.toggle!
      dropdown.expect_open
      dropdown.click_button "Apply"
      dropdown.expect_closed

      work_package_view.expect_empty_state
      work_package_view.expect_assignee(user, present: false)
      work_package_view.expect_assignee(other_user, present: false)

      retry_block do
        work_package_view.add_assignee user.name
      end

      retry_block do
        work_package_view.add_assignee other_user.name
      end

      work_package_view.expect_assignee user
      work_package_view.expect_assignee other_user

      work_package_view.within_lane(user) do
        work_package_view.expect_event task, present: true
        work_package_view.expect_event sub_bug, present: true
        work_package_view.expect_event sub_sub_bug, present: true
      end

      work_package_view.within_lane(other_user) do
        work_package_view.expect_event other_task
        work_package_view.expect_event other_other_task, present: false
      end

      dropdown.toggle!
      dropdown.toggle_checkbox(sub_sub_sub_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 1

      work_package_view.within_lane(user) do
        work_package_view.expect_event task
        work_package_view.expect_event sub_bug, present: true
        work_package_view.expect_event sub_sub_bug
      end

      dropdown.toggle!
      dropdown.toggle_checkbox(other_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 2

      work_package_view.within_lane(other_user) do
        work_package_view.expect_event other_task
        work_package_view.expect_event other_other_task
      end

      page.refresh

      work_package_view.within_lane(other_user) do
        work_package_view.expect_event other_task
        work_package_view.expect_event other_other_task
      end

      work_package_view.within_lane(user) do
        work_package_view.expect_event task
        work_package_view.expect_event sub_bug, present: true
        work_package_view.expect_event sub_sub_bug
      end
    end
  end
end
