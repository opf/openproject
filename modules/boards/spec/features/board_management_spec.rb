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

describe 'Board management spec', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:project) { FactoryBot.create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  before do
    project
    login_as(user)
  end

  context 'with full boards permissions' do
    let(:permissions) do
      %i[
        show_board_views
        manage_board_views
        add_work_packages
        view_work_packages
        edit_work_packages
        manage_public_queries
      ]
    end
    let(:board_view) { FactoryBot.create :board_grid_with_query, project: project }

    let!(:priority) { FactoryBot.create :default_priority }
    let!(:status) { FactoryBot.create :default_status }

    it 'allows management of boards' do
      board_view
      board_index.visit!

      board_page = board_index.open_board board_view
      board_page.expect_query 'List 1', editable: true
      board_page.expect_editable true
      board_page.back_to_index

      board_index.expect_board board_view.name

      # Create new board
      board_page = board_index.create_board action: nil
      board_page.rename_board 'Board test'

      # Rename through toolbar
      board_page.rename_board 'Board foo', through_dropdown: true

      board_page.rename_list 'Unnamed list', 'First'
      board_page.board(reload: true) do |board|
        expect(board.name).to eq 'Board foo'
        queries = board.contained_queries
        expect(queries.count).to eq(1)
        expect(queries.first.name).to eq 'First'
      end

      # Create new list
      board_page.add_list 'Second'

      # Add item
      board_page.add_card 'First', 'Task 1'

      # Expect added to query
      queries = board_page.board(reload: true).contained_queries
      first = queries.find_by(name: 'First')
      second = queries.find_by(name: 'Second')
      expect(first.ordered_work_packages.count).to eq(1)
      expect(second.ordered_work_packages).to be_empty

      # Expect work package to be saved in query first
      subjects = WorkPackage.where(id: first.ordered_work_packages).pluck(:subject)
      expect(subjects).to match_array ['Task 1']

      # Move item to Second list
      board_page.move_card(0, from: 'First', to: 'Second')
      board_page.expect_card('First', 'Task 1', present: false)
      board_page.expect_card('Second', 'Task 1', present: true)

      # Expect work package to be saved in query second
      sleep 2
      retry_block do
        expect(first.reload.ordered_work_packages).to be_empty
        expect(second.reload.ordered_work_packages.count).to eq(1)
      end

      subjects = WorkPackage.where(id: second.ordered_work_packages).pluck(:subject)
      expect(subjects).to match_array ['Task 1']

      # Remove query
      board_page.remove_list 'Second'
      queries = board_page.board(reload: true).contained_queries
      expect(queries.count).to eq(1)
      expect(queries.first.name).to eq 'First'
      expect(queries.first.ordered_work_packages).to be_empty

      # Remove entire board
      board_page.delete_board
      board_index.expect_board 'Board foo', present: false
    end
  end

  context 'with view boards + work package permission' do
    let(:permissions) { %i[show_board_views view_work_packages] }
    let(:board_view) { FactoryBot.create :board_grid_with_query, project: project }

    it 'allows viewing boards index and boards' do
      board_view
      board_index.visit!

      board_page = board_index.open_board board_view
      board_page.expect_query 'List 1', editable: false
      board_page.expect_editable false
      board_page.back_to_index

      board_index.expect_board board_view.name
    end
  end

  context 'with view permission only' do
    let(:permissions) { %i[show_board_views] }

    it 'does not allow viewing of boards' do
      board_index.visit!
      expect(page).to have_selector('#errorExplanation', text: I18n.t(:notice_not_authorized))

      board_index.expect_editable false
    end
  end

  context 'with no permission only' do
    let(:permissions) { %i[] }

    it 'does not allow viewing of boards' do
      board_index.visit!
      expect(page).to have_selector('#errorExplanation', text: I18n.t(:notice_not_authorized))
    end
  end
end
