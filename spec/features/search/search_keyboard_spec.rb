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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "support/shared/embedded_keyboard_table_examples"

RSpec.describe "Search work packages keyboard navigation", :js, with_settings: { per_page_options: "5" } do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_packages) do
    (1..7).map do |n|
      Timecop.freeze("2016-11-21 #{n}:00".to_datetime) do
        create(:work_package, subject: "Keyboard search #{n}", project:)
      end
    end
  end

  let(:rows) { work_packages.last(5).reverse }
  let(:wp_table) do
    Pages::EmbeddedWorkPackagesTable.new(
      find(".work-packages-embedded-view--container"),
      entry_control: -> { find_button("Advanced filter") }
    )
  end

  before do
    login_as admin
    visit search_path(project, q: "Keyboard search", filter: "work_packages", scope: "current_project")
    wp_table.expect_work_package_listed(*rows)
  end

  it_behaves_like "an embedded keyboard table", editable: false do
    let(:first_row_controls) { [rows.first.id.to_s] }
    let(:next_control) { { element: :em, text: "1" } }
    let(:axe_states) { [-> { wp_table.press_keys(select_all_chord) }] }
  end

  it "opens the column menu with Enter and returns focus to the header with Escape" do
    wp_table.tab_into_table
    wp_table.press_keys(:right, :right, :up)
    wp_table.expect_focus_on_column_header("Subject")

    wp_table.press_keys(:enter)
    expect(page).to have_selector(:menuitem, focused: true)

    wp_table.press_keys(:escape)
    expect(page).to have_no_css("#column-context-menu")
    wp_table.expect_focus_on_column_header("Subject")
  end

  it "numbers the rows of the page" do
    wp_table.tab_into_table
    wp_table.expect_row_positions(rowcount: 8, rows: [1, 2, 3, 4, 5, 6])
  end
end
