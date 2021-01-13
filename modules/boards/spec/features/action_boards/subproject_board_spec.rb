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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative './../support//board_index_page'
require_relative './../support/board_page'

describe 'Subproject action board', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:type) { FactoryBot.create(:type_standard) }
  let(:project) { FactoryBot.create(:project, name: 'Parent', types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:subproject1) { FactoryBot.create(:project, parent: project, name: 'Child 1', types: [type], enabled_module_names: %i[work_package_tracking]) }
  let(:subproject2) { FactoryBot.create(:project, parent: project, name: 'Child 2', types: [type], enabled_module_names: %i[work_package_tracking]) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:permissions) {
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries move_work_packages]
  }

  let!(:priority) { FactoryBot.create :default_priority }
  let!(:open_status) { FactoryBot.create :default_status, name: 'Open' }
  let!(:work_package) { FactoryBot.create :work_package, project: subproject1, subject: 'Foo', status: open_status }

  before do
    with_enterprise_token :board_view
    project
    subproject1
    subproject2
    login_as(user)
  end

  context 'without the move_work_packages permission' do
    let(:permissions) {
      %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries]
    }

    let(:user) do
      FactoryBot.create(:user,
                        member_in_projects: [project, subproject1, subproject2],
                        member_through_role: role)
    end

    it 'does not allow to move work packages' do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: :Subproject, expect_empty: true

      # Expect we can add a child 1
      board_page.add_list option: 'Child 1'
      board_page.expect_list 'Child 1'

      # Expect one work package there
      board_page.expect_card 'Child 1', 'Foo'
      board_page.expect_movable 'Child 1', 'Foo', movable: false
    end
  end

  context 'with permissions in all subprojects' do
    let(:user) do
      FactoryBot.create(:user,
                        member_in_projects: [project, subproject1, subproject2],
                        member_through_role: role)
    end

    let(:only_parent_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_through_role: role)
    end

    it 'allows management of subproject work packages' do
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: :Subproject, expect_empty: true

      # Expect we can add a child 1
      board_page.add_list option: 'Child 1'
      board_page.expect_list 'Child 1'

      # Expect one work package there
      board_page.expect_card 'Child 1', 'Foo'

      # Expect move permission to be granted
      board_page.expect_movable 'Child 1', 'Foo', movable: true

      board_page.board(reload: true) do |board|
        expect(board.name).to eq 'Action board (subproject)'
        queries = board.contained_queries
        expect(queries.count).to eq(1)

        query = queries.first
        expect(query.name).to eq 'Child 1'

        expect(query.filters.first.name).to eq :only_subproject_id
        expect(query.filters.first.values).to eq [subproject1.id.to_s]
      end

      # Create new list
      board_page.add_list option: 'Child 2'
      board_page.expect_list 'Child 2'

      board_page.expect_cards_in_order 'Child 2'

      # Add item
      board_page.add_card 'Child 1', 'Task 1'
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 2
      first = queries.find_by(name: 'Child 1')
      second = queries.find_by(name: 'Child 2')
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :project_id)
      expect(subjects).to match_array [['Task 1', subproject1.id]]

      # Move item to Child 2 list
      board_page.move_card(0, from: 'Child 1', to: 'Child 2')

      board_page.expect_card('Child 1', 'Task 1', present: false)
      board_page.expect_card('Child 2', 'Task 1', present: true)

      # Expect work package to be saved in query second
      retry_block do
        raise "first should be empty" if first.reload.ordered_work_packages.any?
        raise "second should have one item" if second.reload.ordered_work_packages.count != 1
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :project_id)
      expect(subjects).to match_array [['Task 1', subproject2.id]]

      # Trying to access the same board as a different user
      login_as only_parent_user
      board_page.visit!

      # We will see an error for the two boards pages
      expect(page).to have_selector('.notification-box.-error', count: 2)
    end
  end
end
