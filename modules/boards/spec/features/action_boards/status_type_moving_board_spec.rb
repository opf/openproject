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
require_relative "../support//board_index_page"
require_relative "../support/board_page"

RSpec.describe "Status action board", :js, with_ee: %i[board_view] do
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries]
  end
  let(:role) { create(:project_role, permissions:) }

  let(:type_bug) { create(:type_bug) }
  let(:type_task) { create(:type_task) }

  let(:project) do
    create(:project, types: [type_task, type_bug], enabled_module_names: %i[work_package_tracking board_view])
  end
  let(:board_index) { Pages::BoardIndex.new(project) }

  let!(:priority) { create(:default_priority) }
  let!(:open_status) { create(:default_status, name: "Open") }
  let!(:closed_status) { create(:status, is_closed: true, name: "Closed") }

  let(:task_wp) do
    create(:work_package,
           project:,
           type: type_task,
           subject: "Open task item",
           status: open_status)
  end
  let(:bug_wp) do
    create(:work_package,
           project:,
           type: type_bug,
           subject: "Closed bug item",
           status: closed_status)
  end

  let!(:workflow_task) do
    create(:workflow,
           type: type_task,
           role:,
           old_status_id: open_status.id,
           new_status_id: closed_status.id)
  end
  let!(:workflow_task_back) do
    create(:workflow,
           type: type_task,
           role:,
           old_status_id: closed_status.id,
           new_status_id: open_status.id)
  end

  let!(:workflow_bug) do
    create(:workflow,
           type: type_bug,
           role:,
           old_status_id: open_status.id,
           new_status_id: closed_status.id)
  end
  let!(:workflow_bug_back) do
    create(:workflow,
           type: type_bug,
           role:,
           old_status_id: closed_status.id,
           new_status_id: open_status.id)
  end

  let(:filters) { Components::WorkPackages::Filters.new }

  before do
    task_wp
    bug_wp
    login_as(user)
  end

  it "allows moving of types between lists without changing filters (Regression #30817)" do
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: "Status"

    # expect lists of default status
    board_page.expect_list "Open"

    board_page.add_list option: "Closed"
    board_page.expect_list "Closed"

    filters.expect_filter_count 0
    filters.open

    filters.add_filter_by("Type", "is (OR)", [type_task.name, type_bug.name])
    filters.expect_filter_by("Type", "is (OR)", [type_task.name, type_bug.name])

    # Wait a bit before saving the page to ensure both values are processed
    sleep 2

    board_page.expect_changed
    board_page.save

    # Move task to closed
    board_page.move_card(0, from: "Open", to: "Closed")

    board_page.expect_card("Closed", "Open task item", present: true)

    # Expect type unchanged
    board_page.card_for(task_wp).expect_type "Task"
    board_page.card_for(bug_wp).expect_type "Bug"

    # Wait a bit before moving the items too fast
    sleep 2

    # Move bug to open
    board_page.move_card_by_name("Closed bug item", from: "Closed", to: "Open")
    board_page.wait_for_lists_reload

    board_page.expect_card("Closed", "Closed bug item", present: false)
    board_page.expect_card("Open", "Closed bug item", present: true)

    # Expect type unchanged
    board_page.card_for(task_wp).expect_type "Task"
    board_page.card_for(bug_wp).expect_type "Bug"

    sleep 2

    task_wp.reload
    bug_wp.reload

    expect(task_wp.type).to eq(type_task)
    expect(bug_wp.type).to eq(type_bug)
  end
end
