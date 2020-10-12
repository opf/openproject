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
  let(:permissions) {
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries]
  }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }


  let(:type_bug) { FactoryBot.create(:type_bug) }
  let(:type_task) { FactoryBot.create(:type_task) }

  let(:project) { FactoryBot.create(:project, types: [type_task, type_bug], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:board_index) { Pages::BoardIndex.new(project) }

  let!(:priority) { FactoryBot.create :default_priority }
  let!(:open_status) { FactoryBot.create :default_status, name: 'Open' }
  let!(:closed_status) { FactoryBot.create :status, is_closed: true, name: 'Closed' }

  let(:task_wp) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type_task,
                      subject: 'Open task item',
                      status: open_status
  end
  let(:bug_wp) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type_bug,
                      subject: 'Closed bug item',
                      status: closed_status
  end

  let!(:workflow_task) {
    FactoryBot.create(:workflow,
                      type: type_task,
                      role: role,
                      old_status_id: open_status.id,
                      new_status_id: closed_status.id)
  }
  let!(:workflow_task_back) {
    FactoryBot.create(:workflow,
                      type: type_task,
                      role: role,
                      old_status_id: closed_status.id,
                      new_status_id: open_status.id)
  }

  let!(:workflow_bug) {
    FactoryBot.create(:workflow,
                      type: type_bug,
                      role: role,
                      old_status_id: open_status.id,
                      new_status_id: closed_status.id)
  }
  let!(:workflow_bug_back) {
    FactoryBot.create(:workflow,
                      type: type_bug,
                      role: role,
                      old_status_id: closed_status.id,
                      new_status_id: open_status.id)
  }

  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    with_enterprise_token :board_view
    task_wp
    bug_wp
    login_as(user)
  end

  it 'allows moving of types between lists without changing filters (Regression #30817)' do
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: :Status

    # expect lists of default status
    board_page.expect_list 'Open'

    board_page.add_list option: 'Closed'
    board_page.expect_list 'Closed'

    filters.expect_filter_count 0
    filters.open

    filters.add_filter_by('Type', 'is', [type_task.name, type_bug.name])
    filters.expect_filter_by('Type', 'is', [type_task.name, type_bug.name])

    # Wait a bit before saving the page to ensure both values are processed
    sleep 2

    board_page.expect_changed
    board_page.save

    # Move task to closed
    board_page.move_card(0, from: 'Open', to: 'Closed')
    board_page.expect_card('Open', 'Open task item', present: false)
    board_page.expect_card('Closed', 'Open task item', present: true)

    # Expect type unchanged
    board_page.card_for(task_wp).expect_type 'Task'
    board_page.card_for(bug_wp).expect_type 'Bug'

    # Wait a bit before moving the items too fast
    sleep 2

    # Move bug to open
    board_page.move_card(0, from: 'Closed', to: 'Open')
    board_page.expect_card('Closed', 'Closed bug item', present: false)
    board_page.expect_card('Open', 'Closed bug item', present: true)

    # Expect type unchanged
    board_page.card_for(task_wp).expect_type 'Task'
    board_page.card_for(bug_wp).expect_type 'Bug'

    sleep 2

    task_wp.reload
    bug_wp.reload

    expect(task_wp.type).to eq(type_task)
    expect(bug_wp.type).to eq(type_bug)
  end
end
