#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative './../support//board_index_page'
require_relative './../support/board_page'

describe 'Status action board', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:type) { FactoryBot.create(:type_standard) }
  let(:project) { FactoryBot.create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:permissions) {
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries]
  }

  let!(:priority) { FactoryBot.create :default_priority }
  let!(:open_status) { FactoryBot.create :default_status, name: 'Open' }
  let!(:other_status) { FactoryBot.create :status, name: 'Whatever' }
  let!(:closed_status) { FactoryBot.create :status, is_closed: true, name: 'Closed' }
  let!(:work_package) { FactoryBot.create :work_package, project: project, subject: 'Foo', status: other_status }

  let(:filters) { ::Components::WorkPackages::Filters.new }

  let!(:workflow_type) {
    FactoryBot.create(:workflow,
                      type: type,
                      role: role,
                      old_status_id: open_status.id,
                      new_status_id: closed_status.id)
  }
  let!(:workflow_type_back) {
    FactoryBot.create(:workflow,
                      type: type,
                      role: role,
                      old_status_id: other_status.id,
                      new_status_id: open_status.id)
  }
  let!(:workflow_type_back_open) {
    FactoryBot.create(:workflow,
                      type: type,
                      role: role,
                      old_status_id: closed_status.id,
                      new_status_id: open_status.id)
  }

  before do
    with_enterprise_token :board_view
    project
    login_as(user)
  end

  context 'with full boards permissions' do
    it 'allows management of boards' do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: :Status

      # expect lists of default status
      board_page.expect_list 'Open'

      board_page.add_list option: 'Closed'
      board_page.expect_list 'Closed'

      board_page.board(reload: true) do |board|
        expect(board.name).to eq 'Action board (status)'
        queries = board.contained_queries
        expect(queries.count).to eq(2)

        open = queries.first
        closed = queries.last

        expect(open.name).to eq 'Open'
        expect(closed.name).to eq 'Closed'

        expect(open.filters.first.name).to eq :status_id
        expect(open.filters.first.values).to eq [open_status.id.to_s]

        expect(closed.filters.first.name).to eq :status_id
        expect(closed.filters.first.values).to eq [closed_status.id.to_s]
      end

      # Create new list
      board_page.add_list option: 'Whatever'
      board_page.expect_list 'Whatever'

      # Add item
      board_page.add_card 'Open', 'Task 1'
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 3
      first = queries.find_by(name: 'Open')
      second = queries.find_by(name: 'Closed')
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :status_id)
      expect(subjects).to match_array [['Task 1', open_status.id]]

      # Move item to Closed
      board_page.move_card(0, from: 'Open', to: 'Closed')
      board_page.expect_card('Open', 'Task 1', present: false)
      board_page.expect_card('Closed', 'Task 1', present: true)

      # Expect work package to be saved in query second
      sleep 2
      retry_block do
        expect(first.reload.ordered_work_packages).to be_empty
        expect(second.reload.ordered_work_packages.count).to eq(1)
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :status_id)
      expect(subjects).to match_array [['Task 1', closed_status.id]]

      # Try to drag to whatever, which has no workflow
      board_page.move_card(0, from: 'Closed', to: 'Whatever')
      board_page.expect_and_dismiss_notification(
        type: :error,
        message: "Status is invalid because no valid transition exists from old to new status for the current user's roles."
      )
      board_page.expect_card('Open', 'Task 1', present: false)
      board_page.expect_card('Whatever', 'Task 1', present: false)
      board_page.expect_card('Closed', 'Task 1', present: true)

      # Add filter
      # Filter for Task
      filters.expect_filter_count 0
      filters.open

      # Expect that status is not available for global filter selection
      filters.expect_available_filter 'Status', present: false

      filters.quick_filter 'Task'
      board_page.expect_changed
      sleep 2

      board_page.expect_card('Closed', 'Task 1', present: true)
      board_page.expect_card('Whatever', work_package.subject, present: false)

      # Expect query props to be present
      url = URI.parse(page.current_url).query
      expect(url).to include("query_props=")

      # Save that filter
      board_page.save

      # Expect filter to be saved in board
      board_page.board(reload: true) do |board|
        expect(board.options['filters']).to eq [{ 'search' => { 'operator' => '**', 'values' => ['Task'] } }]
      end

      # Revisit board
      board_page.visit!

      # Expect filter to be present
      filters.expect_filter_count 1
      filters.open
      filters.expect_quick_filter 'Task'

      # No query props visible
      board_page.expect_not_changed

      # Remove query
      board_page.remove_list 'Whatever'
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq(2)
      expect(queries.first.name).to eq 'Open'
      expect(queries.last.name).to eq 'Closed'
      expect(queries.first.ordered_work_packages).to be_empty

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :status_id)
      expect(subjects).to match_array [['Task 1', closed_status.id]]

      # Open remaining in split view
      wp = second.ordered_work_packages.first.work_package
      card = board_page.card_for(wp)
      split_view = card.open_details_view
      split_view.expect_subject
      split_view.edit_field(:status).update('Open')
      split_view.expect_and_dismiss_notification message: 'Successful update.'

      wp.reload
      expect(wp.status).to eq(open_status)

      board_page.expect_card('Open', 'Task 1', present: true)
      board_page.expect_card('Closed', 'Task 1', present: false)
    end
  end
end
