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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'
require_relative './support/board_index_page'
require_relative './support/board_page'

describe 'Work Package boards sorting spec', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:board_index) { Pages::BoardIndex.new(project) }
  let!(:status) { create :default_status }
  let(:version) { @version ||= create(:version, project: project) }

  before do
    with_enterprise_token :board_view
    project
    login_as(admin)
    board_index.visit!
  end

  # By adding each board the sort of table will change
  # The currently added board should be at the top
  it 'sorts the boards grid and menu based on their names' do
    board_page = board_index.create_board action: nil
    board_page.back_to_index

    expect(page.first('[data-qa-selector="boards-table-column--name"]'))
      .to have_text('Unnamed board')
    expect(page.first('[data-qa-selector="boards-menu--item"]'))
      .to have_text('Unnamed board')

    board_page = board_index.create_board action: :Version, expect_empty: true
    board_page.back_to_index

    expect(page.first('[data-qa-selector="boards-table-column--name"]'))
      .to have_text('Action board (version)')
    expect(page.first('[data-qa-selector="boards-menu--item"]'))
      .to have_text('Action board (version)')

    board_page = board_index.create_board action: :Status
    board_page.back_to_index

    expect(page.first('[data-qa-selector="boards-table-column--name"]'))
      .to have_text('Action board (status)')
    expect(page.first('[data-qa-selector="boards-menu--item"]'))
      .to have_text('Action board (status)')
  end
end
