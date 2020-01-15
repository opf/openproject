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
require_relative './support/board_index_page'
require_relative './support/board_page'

describe 'Board remote changes resolution', type: :feature, js: true do
  let(:user1) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:type) { FactoryBot.create(:type_standard) }
  let(:project) { FactoryBot.create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries]
  end

  let!(:priority) { FactoryBot.create :default_priority }
  let!(:open_status) { FactoryBot.create :default_status, name: 'Open' }
  let!(:work_package1) { FactoryBot.create :work_package, project: project, subject: 'Work package A', status: open_status }
  let!(:work_package2) { FactoryBot.create :work_package, project: project, subject: 'Work package B', status: open_status }

  before do
    with_enterprise_token :board_view
    project
    login_as(user1)
  end

  it 'update boards in the background' do
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: :Status

    # expect lists of default status
    board_page.expect_list 'Open'

    board_page.expect_card('Open', work_package1.subject)
    board_page.expect_card('Open', work_package2.subject)

    board_page.expect_cards_in_order('Open', work_package1, work_package2)

    board_query = Query.last
    board_query.ordered_work_packages.replace [
      board_query.ordered_work_packages.create(work_package_id: work_package2.id, position: 0),
      board_query.ordered_work_packages.create(work_package_id: work_package1.id, position: 16384)
    ]

    board_query.touch

    sleep(3)

    board_page.expect_cards_in_order('Open', work_package2, work_package1)
  end
end
