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

describe 'Priority action board', type: :feature, js: true do
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

  let!(:normal_priority) { FactoryBot.create :default_priority, name: 'Normal'  }
  let!(:other_priority) { FactoryBot.create :priority, name: 'Whatever' }
  let!(:low_priority) { FactoryBot.create :priority, name: 'Low' }
  let!(:open_status) { FactoryBot.create :default_status, name: 'Open' }
  let!(:work_package_normal) { FactoryBot.create :work_package, project: project, subject: 'Foo', priority: normal_priority, status: open_status }

  let(:filters) { ::Components::WorkPackages::Filters.new }


  before do
    open_status
    normal_priority
    work_package_normal
    with_enterprise_token :board_view
    project
    login_as(user)
  end

  context 'with full boards permissions' do
    it 'allows management of boards' do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: :Priority

      # expect lists of Normal priority
      board_page.expect_list 'Normal'

      board_page.add_list option: 'Low'
      board_page.expect_list 'Low'

      board_page.board(reload: true) do |board|
        expect(board.name).to eq 'Action board (priority)'
        queries = board.contained_queries
        expect(queries.count).to eq(2)

        normal = queries.first
        low = queries.last

        expect(normal.name).to eq 'Normal'
        expect(low.name).to eq 'Low'

        expect(normal.filters.first.name).to eq :priority_id
        expect(normal.filters.first.values).to eq [normal_priority.id.to_s]

        expect(low.filters.first.name).to eq :priority_id
        expect(low.filters.first.values).to eq [low_priority.id.to_s]
      end

      # Create new list
      board_page.add_list option: 'Whatever'
      board_page.expect_list 'Whatever'

      # Add item
      board_page.add_card 'Normal', 'Task 1'
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 3
      first = queries.find_by(name: 'Normal')
      second = queries.find_by(name: 'Low')
      third = queries.find_by(name: 'Whatever')
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :priority_id)
      expect(subjects).to match_array [['Task 1', normal_priority.id]]

      # Move item to Low
      board_page.move_card(0, from: 'Normal', to: 'Low')
      board_page.expect_card('Normal', 'Task 1', present: false)
      board_page.expect_card('Low', 'Task 1', present: true)

      # Expect work package to be saved in query second
      sleep 2
      retry_block do
        expect(first.reload.ordered_work_packages).to be_empty
        expect(second.reload.ordered_work_packages.count).to eq(1)
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :priority_id)
      expect(subjects).to match_array [['Task 1', low_priority.id]]

      board_page.move_card(0, from: 'Low', to: 'Whatever')
      board_page.expect_card('Normal', 'Task 1', present: false)
      board_page.expect_card('Whatever', 'Task 1', present: true)

      # Add filter
      # Filter for Task
      filters.expect_filter_count 0
      filters.open

      # Expect that priority is not available for global filter selection
      filters.expect_available_filter 'Priority', present: false

      filters.quick_filter 'Task'
      board_page.expect_changed
      sleep 2

      board_page.expect_card('Whatever', 'Task 1', present: true)

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
      board_page.remove_list 'Normal'
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq(2)
      expect(queries.first.name).to eq 'Low'
      expect(queries.last.name).to eq 'Whatever'
      expect(queries.first.ordered_work_packages).to be_empty

      subjects = WorkPackage.where(id: third.ordered_work_packages.pluck(:work_package_id))
      expect(subjects.pluck(:subject, :priority_id)).to match_array [['Task 1', other_priority.id]]

      # Open remaining in split view
      wp = third.ordered_work_packages.first.work_package
      card = board_page.card_for(wp)
      split_view = card.open_details_view
      split_view.expect_subject
      split_view.edit_field(:priority).update('Low')
      split_view.expect_and_dismiss_notification message: 'Successful update.'

      wp.reload
      expect(wp.priority).to eq(low_priority)

      board_page.expect_card('Low', 'Task 1', present: true)
      board_page.expect_card('Whatever', 'Task 1', present: false)

    end
  end
end
