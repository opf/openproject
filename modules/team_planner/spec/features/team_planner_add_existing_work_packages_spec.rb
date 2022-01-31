#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require_relative '../support/components/add_existing_pane'

describe 'Team planner add existing work packages', type: :feature, js: true do
  include_context 'with team planner full access'

  let(:closed_status) { create :status, is_closed: true }

  let!(:other_user) do
    create :user,
                      firstname: 'Bernd',
                      member_in_project: project,
                      member_with_permissions: %w[
                        view_work_packages view_team_planner
                      ]
  end

  let!(:first_wp) do
    create :work_package,
                      project: project,
                      subject: 'Task 1',
                      assigned_to: user,
                      start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
                      due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday)
  end
  let!(:second_wp) do
    create :work_package,
                      project: project,
                      subject: 'Task 2',
                      parent: first_wp,
                      assigned_to: other_user,
                      start_date: 10.days.from_now,
                      due_date: 12.days.from_now
  end
  let!(:third_wp) do
    create :work_package,
                      project: project,
                      subject: 'TA Aufgabe 3',
                      status: closed_status
  end

  let(:add_existing_pane) { ::Components::AddExistingPane.new }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  context 'with full permissions' do
    before do
      with_enterprise_token(:team_planner_view)
      team_planner.visit!

      team_planner.add_assignee user

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp, present: false
      end

      # Open the left hand pane
      team_planner.find('.fc-addExisting-button').click

      add_existing_pane.expect_open
      add_existing_pane.expect_empty
    end

    it 'allows to add work packages via drag&drop from the left hand shortlist' do
      # Search for a work package
      add_existing_pane.search 'Task'
      add_existing_pane.expect_result second_wp

      sleep 2

      # Drag it to the team planner...
      add_existing_pane.drag_wp_by_pixel second_wp, 750, 50

      team_planner.expect_and_dismiss_toaster(message: "Successful update.")

      # ... and thus update its attributes. Thereby the duration is maintained
      second_wp.reload
      expect(second_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:tuesday))
      expect(second_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:thursday))
      expect(second_wp.assigned_to_id).to eq(user.id)

      # Search for another work package
      add_existing_pane.search 'Ta'
      add_existing_pane.expect_result third_wp

      sleep 2

      # Drag it to the team planner...
      add_existing_pane.drag_wp_by_pixel third_wp, 750, -50

      team_planner.expect_and_dismiss_toaster(message: "Successful update.")

      # ... and thus update its attributes. Since no dates were set before, start and end date are set to the same day
      third_wp.reload
      expect(third_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:tuesday))
      expect(third_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:tuesday))
      expect(third_wp.assigned_to_id).to eq(user.id)

      # New events are directly clickable
      split_view = team_planner.open_split_view(third_wp)
      split_view.expect_open
    end

    it 'the search applies the filter from the team planner' do
      # Search for a work package
      add_existing_pane.search 'Task'
      add_existing_pane.expect_result second_wp
      add_existing_pane.expect_result third_wp, visible: false

      # WP that are already shown in the team planner are not shown again
      add_existing_pane.expect_result first_wp, visible: false

      filters.expect_filter_count 1
      filters.open
      filters.expect_filter_by 'Status', 'all', nil

      # Change the filter for the whole page
      filters.set_filter 'Status', 'open', nil

      # Search again, and the filter criteria are applied
      add_existing_pane.search 'Ta'
      add_existing_pane.expect_result second_wp
      add_existing_pane.expect_result third_wp, visible: false
    end
  end

  context 'without permission to edit' do
    current_user { other_user }

    before do
      team_planner.visit!
    end

    it 'does not show the button to add existing work packages' do
      expect(page).not_to have_selector('.fc-addExisting-button')
      add_existing_pane.expect_closed
    end
  end
end
