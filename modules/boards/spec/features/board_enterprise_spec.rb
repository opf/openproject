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
require_relative "support/board_index_page"
require_relative "support/board_page"

RSpec.describe "Boards enterprise spec", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }

  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:status) { create(:default_status) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  shared_let(:manual_board) { create(:board_grid_with_query, name: "My board", project:) }
  shared_let(:action_board) do
    create(:subproject_board,
           name: "Subproject board",
           project:,
           projects_columns: [])
  end

  context "when EE inactive" do
    before do
      login_as(admin)
      board_index.visit!
    end

    it "disabled all action boards" do
      page.find('[data-test-selector="add-board-button"]', text: "Board").click

      expect(page).to have_css("#{test_selector('op-tile-block')}:not(.-disabled)", text: "Basic")
      expect(page).to have_css("#{test_selector('op-tile-block')}.-disabled", count: 5)
    end

    it "shows a banner on the action board" do
      # Expect both existing boards to show
      expect(page).to have_content "My board"
      expect(page).to have_content "Subproject board"

      board_page = board_index.open_board(manual_board)
      board_page.expect_query "My board"
      expect(page).not_to have_enterprise_banner

      board_index.visit!
      board_page = board_index.open_board(action_board)
      board_page.expect_query "Subproject board"
      expect(page).to have_enterprise_banner
    end
  end

  context "when EE active", with_ee: %i[board_view] do
    before do
      login_as(admin)
      board_index.visit!
    end

    it "enables all options" do
      page.find('[data-test-selector="add-board-button"]', text: "Board").click

      expect(page).to have_css("#{test_selector('op-tile-block')}:not(.-disabled)", count: 6)
    end

    it "shows the action board" do
      # Expect both existing boards to show
      expect(page).to have_content "My board"
      expect(page).to have_content "Subproject board"

      board_page = board_index.open_board(manual_board)
      board_page.expect_query "My board"
      expect(page).not_to have_enterprise_banner

      board_index.visit!
      board_page = board_index.open_board(action_board)
      board_page.expect_query "Subproject board"
      expect(page).not_to have_enterprise_banner
    end
  end
end
