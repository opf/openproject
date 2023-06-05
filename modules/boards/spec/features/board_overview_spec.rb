#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_relative './support/board_overview_page'

RSpec.describe 'Work Package boards overview spec', with_ee: %i[board_view], with_flag: { more_global_index_pages: true } do
  let(:user) do
    create(:user,
           member_in_project: project,
           member_through_role: role)
  end
  # The identifier is important to test https://community.openproject.com/wp/29754
  let(:project) { create(:project, identifier: 'boards', enabled_module_names: %i[work_package_tracking board_view]) }
  let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:permissions) { %i[show_board_views manage_board_views add_work_packages view_work_packages manage_public_queries] }
  let(:role) { create(:role, permissions:) }
  let!(:priority) { create(:default_priority) }
  let!(:status) { create(:default_status) }
  let(:board_overview) { Pages::BoardOverview.new }
  let(:board_view) { create(:board_grid_with_query, name: 'My board', project:) }
  let(:other_board_view) { create(:board_grid_with_query, name: 'My other board', project:) }
  let(:other_project_board_view) { create(:board_grid_with_query, name: 'Unseeable Board', project: other_project) }

  before do
    login_as(user)
  end

  context 'when no boards exist' do
    it 'displays the empty message' do
      board_overview.visit!

      board_overview.expect_no_boards_listed
    end
  end

  context 'when only boards exist that the user does not have access to' do
    before do
      other_project_board_view
    end

    it 'displays the empty message' do
      board_overview.visit!

      board_overview.expect_no_boards_listed
    end
  end

  context 'when boards exists' do
    before do
      board_view
      other_board_view
      other_project_board_view
    end

    it 'lists the boards' do
      board_overview.visit!

      board_overview.expect_boards_listed(board_view, other_board_view)
      board_overview.expect_boards_not_listed(other_project_board_view)
    end

    it 'paginates results', with_settings: { per_page_options: '1' } do
      # First page displays the historically last meeting
      board_overview.visit!
      board_overview.expect_boards_listed(board_view)
      board_overview.expect_boards_not_listed(other_board_view)

      board_overview.expect_to_be_on_page(1)

      board_overview.to_page(2)
      board_overview.expect_boards_listed(other_board_view)
      board_overview.expect_boards_not_listed(board_view)
    end
  end
end
