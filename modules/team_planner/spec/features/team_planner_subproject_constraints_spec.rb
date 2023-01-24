#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_relative './shared_context'

describe 'Team planner constraints for a subproject', js: true do
  before do
    with_enterprise_token(:team_planner_view)
  end

  include_context 'with team planner full access'

  let!(:other_user) do
    create :user,
           firstname: 'Bernd',
           member_in_project: project,
           member_with_permissions: %w[
             view_work_packages view_team_planner work_package_assigned
           ]
  end

  let!(:subproject) { create :project, parent: project }
  let!(:role) { create :role, permissions: %i[view_work_packages edit_work_packages work_package_assigned] }
  let!(:member) { create :member, principal: user, project: subproject, roles: [role] }
  let(:project_include) { Components::ProjectIncludeComponent.new }

  let!(:work_package) do
    create :work_package,
           project: subproject,
           assigned_to: user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday)
  end

  it 'shows a visual aid that the other user cannot be assigned' do
    team_planner.visit!

    team_planner.add_assignee user
    retry_block do
      team_planner.add_assignee other_user
    end

    # Include the subproject
    project_include.toggle!
    project_include.toggle_checkbox(subproject.id)
    project_include.click_button 'Apply'
    project_include.expect_count 1

    team_planner.within_lane(user) do
      team_planner.expect_event work_package
    end

    retry_block do
      # Ensure we're not dragging anything
      drag_release

      # Try to drag work package to other user
      start_dragging team_planner.event(work_package)
      drag_element_to find(".fc-timeline-lane[data-resource-id='/api/v3/users/#{other_user.id}']")

      # Expect background event on other user
      page.find(".fc-timeline-lane[data-resource-id='/api/v3/users/#{other_user.id}'] .fc-bg-event")
      drag_element_to find(".fc-timeline-lane[data-resource-id='/api/v3/users/#{user.id}']")
      drag_release

      unless page.has_no_selector?(".fc-timeline-lane[data-resource-id='/api/v3/users/#{other_user.id}'] .fc-bg-event")
        raise "Expected to have no bg-event after release"
      end
    end
  end
end
