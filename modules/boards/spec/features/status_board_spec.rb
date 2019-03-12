#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
require_relative './support/board_index_page'
require_relative './support/board_page'

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

  let!(:workflow_type) {
    FactoryBot.create(:workflow,
                      type: type,
                      role: role,
                      old_status_id: open_status.id,
                      new_status_id: closed_status.id)
  }

  before do
    project
    login_as(user)
  end

  context 'with full boards permissions' do
    it 'allows management of boards' do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: :Status

      # expect lists of default and closed status
      board_page.expect_list 'Open'
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
      board_page.add_list nil, value: 'Whatever'
      board_page.expect_list 'Whatever'

      # Add item
      board_page.add_card 'Open', 'Task 1'

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 3
      first = queries.find_by(name: 'Open')
      second = queries.find_by(name: 'Closed')
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages).pluck(:subject, :status_id)
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

      subjects = WorkPackage.where(id: second.ordered_work_packages).pluck(:subject, :status_id)
      expect(subjects).to match_array [['Task 1', closed_status.id]]

      # Try to drag to whatever, which has no workflow
      board_page.move_card(0, from: 'Closed', to: 'Whatever')
      board_page.expect_notification(
        type: :error,
        message: "Status is invalid because no valid transition exists from old to new status for the current user's roles."
      )
      board_page.expect_card('Open', 'Task 1', present: false)
      board_page.expect_card('Whatever', 'Task 1', present: false)
      board_page.expect_card('Closed', 'Task 1', present: true)

      # Remove query
      board_page.remove_list 'Whatever'
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq(2)
      expect(queries.first.name).to eq 'Open'
      expect(queries.last.name).to eq 'Closed'
      expect(queries.first.ordered_work_packages).to be_empty

      subjects = WorkPackage.where(id: second.ordered_work_packages).pluck(:subject, :status_id)
      expect(subjects).to match_array [['Task 1', closed_status.id]]
    end
  end
end
