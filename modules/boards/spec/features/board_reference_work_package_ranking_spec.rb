# frozen_string_literal: true

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
require_relative "support/board_page"

RSpec.describe "Board 'Add existing work package' ranks exact matches first",
               :js,
               :selenium do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) do
    create(:project_role,
           permissions: %i[show_board_views manage_board_views add_work_packages view_work_packages
                           edit_work_packages manage_public_queries save_queries])
  end
  let(:user) { create(:user, member_with_roles: { project => role }) }
  let(:board_view) { create(:board_grid_with_query, project:) }
  let(:board_page) { Pages::Board.new(board_view) }

  let!(:priority) { create(:default_priority) }
  let!(:status) { create(:default_status) }

  let!(:prefix_match) do
    create(:work_package, project:, updated_at: 1.minute.ago, skip_semantic_id_allocation: true)
  end
  let!(:exact_match) do
    create(:work_package, project:, updated_at: 2.days.ago, skip_semantic_id_allocation: true)
  end
  let!(:prefix_alias) do
    create(:work_package_semantic_alias, work_package: prefix_match, identifier: "BOARDRANK-50")
  end
  let!(:exact_alias) do
    create(:work_package_semantic_alias, work_package: exact_match, identifier: "BOARDRANK-5")
  end

  before do
    board_view
    login_as(user)
    board_page.visit!
  end

  it "shows the exact identifier match first in the 'Add existing' dropdown" do
    board_page.within_list("List 1") do
      page.find('[data-test-selector="op-board-list--card-dropdown-add-button"]').click
    end

    page.find(".menu-item", text: "Add existing").click

    dropdown = search_autocomplete(page.find("ng-select.wp-inline-create--reference-autocompleter"),
                                   query: "#BOARDRANK-5",
                                   results_selector: "body")

    within(dropdown) do
      option_texts = all(".ng-option").map(&:text)

      expect(option_texts.first).to include("##{exact_match.id}")
    end
  end
end
