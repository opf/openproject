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

describe 'Version action board', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_projects: [project, second_project],
                      member_through_role: role)
  end

  let(:second_user) do
    FactoryBot.create(:user,
                      member_in_projects: [project, second_project],
                      member_through_role: role_board_manager)
  end
  let(:type) { FactoryBot.create(:type_standard) }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:status) { FactoryBot.create :default_status }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:role_board_manager) { FactoryBot.create(:role, permissions: permissions_board_manager) }

  let(:project) { FactoryBot.create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:second_project) { FactoryBot.create(:project) }

  let(:board_index) { Pages::BoardIndex.new(project) }
  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages manage_versions
       edit_work_packages view_work_packages manage_public_queries assign_versions]
  end
  let(:permissions_board_manager) do
    %i[show_board_views manage_board_views view_work_packages manage_public_queries]
  end

  let!(:open_version) { FactoryBot.create :version, project: project, name: 'Open version' }
  let!(:other_version) { FactoryBot.create :version, project: project, name: 'A second version' }
  let!(:different_project_version_) { FactoryBot.create :version, project: second_project, name: 'Version of another project' }
  let!(:shared_version) { FactoryBot.create :version, project: second_project, name: 'Shared version', sharing: 'system' }
  let!(:closed_version) { FactoryBot.create :version, project: project, status: 'closed', name: 'Closed version' }

  let!(:work_package) { FactoryBot.create :work_package, project: project, subject: 'Foo', version: open_version }
  let!(:closed_version_wp) { FactoryBot.create :work_package, project: project, subject: 'Closed', version: closed_version }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  def create_new_version_board
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: :Version

    # expect lists of open versions
    board_page.expect_list 'Open version'
    board_page.expect_list 'A second version'
    board_page.expect_no_list 'Shared version'
    board_page.expect_no_list 'Closed version'
    board_page.expect_no_list 'Version of another project'

    board_page
  end

  before do
    with_enterprise_token :board_view
    project
  end

  context 'with full boards permissions' do
    before do
      login_as(user)
    end

    it 'allows management of boards' do
      board_page = create_new_version_board

      board_page.expect_card 'Open version', work_package.subject, present: true

      board_page.expect_list_option 'Shared version'
      board_page.expect_list_option 'Closed version'

      board_page.board(reload: true) do |board|
        expect(board.name).to eq 'Action board (version)'
        queries = board.contained_queries
        expect(queries.count).to eq(2)

        open = queries.detect { |q| q.name == 'Open version'}
        second_open = queries.detect { |q| q.name == 'A second version'}

        expect(open.name).to eq 'Open version'
        expect(second_open.name).to eq 'A second version'

        expect(open.filters.first.name).to eq :version_id
        expect(open.filters.first.values).to eq [open_version.id.to_s]

        expect(second_open.filters.first.name).to eq :version_id
        expect(second_open.filters.first.values).to eq [other_version.id.to_s]
      end

      # Add item
      board_page.add_list option: 'Shared version'
      board_page.add_card 'Open version', 'Task 1'
      sleep 2

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq 3
      first = queries.find_by(name: 'Open version')
      second = queries.find_by(name: 'A second version')
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :version_id)
      # Only the explicitly added item is now contained in sort order
      expect(subjects).to match_array [['Task 1', open_version.id]]

      # Move item to Closed
      board_page.move_card(0, from: 'Open version', to: 'A second version')
      board_page.expect_card('Open version', 'Task 1', present: false)
      board_page.expect_card('A second version', 'Task 1', present: true)

      # Expect work package to be saved in query second
      sleep 2
      retry_block do
        expect(first.reload.ordered_work_packages.count).to eq(0)
        expect(second.reload.ordered_work_packages.count).to eq(1)
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :version_id)
      expect(subjects).to match_array [['Task 1', other_version.id]]

      # Expect that version is not available for global filter selection
      filters.expect_available_filter 'Version', present: false

      # Add filter
      # Filter for Task
      filters.expect_filter_count 0
      filters.open

      filters.quick_filter 'Task'
      board_page.expect_changed
      sleep 2

      board_page.expect_card('Open version', 'Foo', present: false)
      board_page.expect_card('A second version', 'Task 1', present: true)

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
      board_page.remove_list 'Shared version'
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq(2)
      expect(queries.map(&:name)).to contain_exactly 'Open version', 'A second version'

      board_page.expect_card('Open version', 'Foo', present: false)
      board_page.expect_card('A second version', 'Task 1', present: true)

      subjects = WorkPackage.where(id: second.ordered_work_packages.pluck(:work_package_id)).pluck(:subject, :version_id)
      expect(subjects).to match_array [['Task 1', other_version.id]]

      # Open remaining in split view
      work_package = second.ordered_work_packages.first.work_package
      card = board_page.card_for(work_package)
      split_view = card.open_details_view
      split_view.expect_subject
      split_view.edit_field(:version).update('Open version')
      split_view.expect_and_dismiss_notification message: 'Successful update.'

      work_package.reload
      expect(work_package.version).to eq(open_version)

      board_page.expect_card('Open version', 'Task 1', present: true)
      board_page.expect_card('A second version', 'Task 1', present: false)
    end

    it 'allows adding new and closed versions from within the board' do
      board_page = create_new_version_board

      # Add new version (and list)
      board_page.add_list_with_new_value 'Completely new version'
      board_page.expect_list 'Completely new version'

      visit settings_versions_project_path(project)
      expect(page).to have_content 'Completely new version'
      expect(page).to have_content 'Closed version'

      board_page.visit!

      board_page.expect_list 'Open version'
      board_page.expect_list 'A second version'
      board_page.expect_list 'Completely new version'
      board_page.expect_card('Open version', 'Foo')

      queries = board_page.board(reload: true).contained_queries
      closed = queries.find_by(name: 'Closed version')
      expect(closed).to be_nil

      retry_block(screenshot: true) do
        board_page.add_list option: closed_version.name
      end

      board_page.expect_list 'Closed version'
      expect(page).to have_selector('.version-board-header.-closed')

      # Can open that version
      board_page.click_list_dropdown 'Closed version', 'Open version'
      expect(page).to have_no_selector('.version-board-header.-closed')

      closed_version.reload
      expect(closed_version.status).to eq 'open'

      # Can lock that version
      board_page.click_list_dropdown 'Closed version', 'Lock version'
      expect(page).to have_selector('.version-board-header.-locked')

      closed_version.reload
      expect(closed_version.status).to eq 'locked'

      # We can move out of the locked version
      board_page.move_card(0, from: 'Closed version', to: 'Open version')

      board_page.expect_card('Open version', 'Closed', present: true)
      board_page.expect_card('Closed version', 'Closed', present: false)

      # Expect work package to be saved in query second
      sleep 2

      queries = board_page.board(reload: true).contained_queries
      open = queries.find_by(name: 'Open version')
      closed = queries.find_by(name: 'Closed version')

      retry_block do
        expect(open.reload.ordered_work_packages.count).to eq(2)
        expect(closed.reload.ordered_work_packages.count).to eq(0)
      end

      ids = open.ordered_work_packages.pluck(:work_package_id)
      expect(ids).to match_array [work_package.id, closed_version_wp.id]

      closed_version_wp.reload
      expect(closed_version_wp.version_id).to eq(open_version.id)

      # But we can not move back to closed
      board_page.move_card(0, from: 'Open version', to: 'Closed version')
      board_page.expect_card('Open version', 'Closed', present: true)
      board_page.expect_card('Closed version', 'Closed', present: false)
      board_page.expect_card('Closed version', 'Foo', present: false)
    end
  end

  context 'a user with edit_work_packages, but missing assign_versions permissions' do
    let(:no_version_edit_user) do
      FactoryBot.create(:user,
                        member_in_projects: [project],
                        member_through_role: no_version_edit_role)
    end
    let(:no_version_edit_role) { FactoryBot.create(:role, permissions: no_version_edit_permissions) }
    let(:no_version_edit_permissions) do
      %i[show_board_views manage_board_views add_work_packages manage_versions
       edit_work_packages view_work_packages manage_public_queries]
    end

    it 'can not move cards or add cards' do
      # Create version board first
      login_as user
      board_page = create_new_version_board

      # Login in with restricted user
      login_as no_version_edit_user

      # Reload the page
      board_page.visit!
      board_page.expect_editable_board(true)
      board_page.expect_editable_list(false)

      expect(page).to have_no_selector('.wp-card.-draggable')
    end
  end

  context 'with limited permissions' do
    before do
      login_as(second_user)
    end

    it 'does not allow to create new versions from within the board' do
      board_page = create_new_version_board

      board_page.open_and_fill_add_list_modal 'Completely new version'

      expect(page).not_to have_selector('.ng-option', text: 'Completely new version')
    end
  end
end
