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
require_relative "../support/components/add_existing_pane"

RSpec.describe "Team planner remove event",
               :js,
               with_ee: %i[team_planner_view],
               with_settings: { start_of_week: 1 } do
  include_context "with team planner full access"

  let!(:viewer_role) { create(:project_role, permissions: [:view_work_packages]) }

  let!(:other_user) do
    create(:user,
           firstname: "Bernd",
           member_with_permissions: { project => %w[
             view_work_packages view_team_planner
           ] })
  end

  let!(:removable_wp) do
    create(:work_package,
           project:,
           subject: "Some task",
           assigned_to: other_user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end

  let!(:non_removable_wp) do
    create(:work_package,
           project:,
           subject: "Parent work package",
           assigned_to: other_user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:wednesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday),
           derived_start_date: Time.zone.today.beginning_of_week.next_occurring(:wednesday),
           derived_due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end

  let!(:child_wp) do
    create(:work_package,
           parent: non_removable_wp,
           project:,
           assigned_to: user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:wednesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end

  before do
    team_planner.visit!
    team_planner.add_assignee other_user

    team_planner.within_lane(other_user) do
      team_planner.expect_event removable_wp
      team_planner.expect_event non_removable_wp
    end

    sleep 2
  end

  it "can remove one of the work packages" do
    team_planner.drag_to_remove_dropzone non_removable_wp, expect_removable: false
    team_planner.drag_to_remove_dropzone removable_wp, expect_removable: true
  end

  context "with the add existing open searching for the task" do
    let(:add_existing_pane) { Components::AddExistingPane.new }

    it "the removed task shows up again" do
      # Open the left hand pane
      add_existing_pane.open
      add_existing_pane.expect_empty

      # Search for the task, expect empty
      add_existing_pane.search "task"
      add_existing_pane.expect_empty

      # Remove the task
      team_planner.drag_to_remove_dropzone removable_wp, expect_removable: true

      # Should show up in add existing
      add_existing_pane.expect_result removable_wp
    end
  end
end
