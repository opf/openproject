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
require_relative './../support/board_index_page'
require_relative './../support/board_page'

describe 'Assignee action board',
         type: :feature,
         driver: :firefox_headless_en,
         js: true do
  let(:bobself_user) do
    FactoryBot.create(:user,
                      firstname: 'Bob',
                      lastname: 'Self',
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


  # Set up other assignees

  let!(:foobar_user) do
    FactoryBot.create(:user,
                      firstname: 'Foo',
                      lastname: 'Bar',
                      member_in_project: project,
                      member_through_role: role)
  end

  let!(:work_package) { FactoryBot.create :work_package,
                                          project: project,
                                          assigned_to: bobself_user,
                                          subject: 'Some Task' }

  before do
    with_enterprise_token :board_view
    login_as(bobself_user)
  end

  it 'allows to move a task between two assignees' do
    # Move to the board index page
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: :Assignee, expect_empty: true

    # Expect no assignees to be present
    board_page.expect_empty

    # Add myself to the board list
    board_page.add_list option: 'Bob Self'
    board_page.expect_list 'Bob Self'

    # Add the other user to the board list
    board_page.add_list option: 'Foo Bar'
    board_page.expect_list 'Foo Bar'

    board_page.board(reload: true) do |board|
      expect(board.name).to eq 'Action board (assignee)'
      queries = board.contained_queries
      expect(queries.count).to eq(2)

      bob = queries.first
      foo = queries.last

      expect(bob.name).to eq 'Bob Self'
      expect(foo.name).to eq 'Foo Bar'

      expect(bob.filters.first.name).to eq :assigned_to_id
      expect(bob.filters.first.values).to eq [bobself_user.id.to_s]

      expect(foo.filters.first.name).to eq :assigned_to_id
      expect(foo.filters.first.values).to eq [foobar_user.id.to_s]
    end

    # First, expect work package to be assigned to "Bob self"
    # For this, test the Bob self column to contain the work package
    board_page.expect_card 'Bob Self', 'Some Task'

    # Then, move the work package from one column to the next one
    board_page.move_card(0, from: 'Bob Self', to: 'Foo Bar')

    # Then, the work package should be in the other column
    # and assigned to "Foo Bar" user
    board_page.expect_card 'Foo Bar', 'Some Task'
    board_page.expect_card 'Bob Self', 'Some Task', present: false

    # Expect to have changed the avatar
    expect(page).to have_selector('.wp-card--assignee .avatar-default', text: 'FB', wait: 10)

    work_package.reload
    expect(work_package.assigned_to).to eq(foobar_user)
  end
end
