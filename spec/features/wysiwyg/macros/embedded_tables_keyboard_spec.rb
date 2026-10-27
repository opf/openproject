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

RSpec.describe "Wiki embedded work package table keyboard navigation", :js do
  include_context "with axe on Cuprite"

  create_shared_association_defaults_for_work_package_factory

  shared_let(:admin) { create(:admin) }
  shared_let(:project) do
    create(:project, :with_internal_wiki, enabled_module_names: %w[work_package_tracking wiki])
  end

  let(:query_props) do
    {
      "columns[]" => %w[id subject],
      showHierarchies: false,
      timelineVisible: false,
      groupBy: "",
      filters: JSON.dump([{ status: { operator: "o", values: [] } }]),
      sortBy: JSON.dump([%w[id asc]])
    }
  end
  let(:macro) { %(<macro class="embedded-table" data-query-props="#{CGI.escapeHTML(query_props.to_json)}"></macro>) }
  let!(:wiki_page) do
    create(:wiki_page, wiki: project.wiki, title: "Keyboard tables", text: <<~MARKDOWN)
      [prelink](https://example.com/)

      #{macro}
    MARKDOWN
  end
  let(:wp_table) do
    Pages::EmbeddedWorkPackagesTable.new(
      find(".wiki-content opce-macro-embedded-table"),
      entry_control: -> { find_link("prelink") }
    )
  end

  before do
    login_as admin
    visit project_wiki_path(project, wiki_page)
  end

  context "with a flat table" do
    shared_let(:work_packages) do
      (1..3).map { |n| create(:work_package, project:, subject: "Macro keyboard #{n}") }
    end
    let(:rows) { work_packages }

    before do
      wp_table.expect_work_package_listed(*rows)
      wp_table.expect_inline_create_button
    end

    it_behaves_like "an embedded keyboard table", editable: true do
      let(:first_row_controls) { [rows.first.id.to_s] }
      let(:next_control) { { role: :button, name: "Create new work package" } }
      let(:axe_states) do
        [lambda do
          wp_table.click_inline_create
          wait_for_network_idle
        end]
      end
    end

    it "numbers the rows of the table" do
      wp_table.tab_into_table
      wp_table.expect_row_positions(rowcount: 5, rows: [1, 2, 3, 4, 5])
    end

    it "keeps the Cancel link on the line of the create row's input" do
      wp_table.click_inline_create

      creation_row = wp_table.creation_row
      expect(creation_row).to have_selector(:link, accessible_name: "Cancel", obscured: false)
      expect(creation_row).to have_field("Subject", obscured: false)
      expect(creation_row).to have_css("td", count: wp_table.table_container.all("thead th").count)

      field_top, field_bottom, link_top, link_bottom = page.evaluate_script(<<~JS, creation_row)
        (function (row) {
          const field = row.querySelector("input").getBoundingClientRect();
          const link = row.querySelector(".wp-table--cancel-create-link").getBoundingClientRect();
          return [field.top, field.bottom, link.top, link.bottom];
        })(arguments[0])
      JS
      expect(link_top).to be < field_bottom
      expect(link_bottom).to be > field_top

      creation_row.find(:link, accessible_name: "Cancel").click
      expect(wp_table.table_container).to have_no_css(".wp-inline-create-row")
    end
  end

  context "with a hierarchy" do
    shared_let(:parent) { create(:work_package, project:, subject: "Macro parent") }
    shared_let(:child) { create(:work_package, project:, parent:, subject: "Macro child") }

    let(:hierarchies) { Components::WorkPackages::Hierarchies.new }
    let(:query_props) { super().merge(showHierarchies: true) }

    before do
      wp_table.expect_work_package_listed(parent, child)
      wp_table.focus_row_by_keyboard(parent)
    end

    it "collapses and expands the parent with Left and Right" do
      wp_table.press_keys(:left)
      hierarchies.expect_hierarchy_at(parent, collapsed: true)
      hierarchies.expect_hidden(child)

      wp_table.press_keys(:right)
      hierarchies.expect_hierarchy_at(parent, collapsed: false)
      expect(page).to have_css(wp_table.row_selector(child))
    end

    it "has no axe violations expanded and collapsed" do
      expect(page).to be_axe_clean.within(wp_table.axe_scope)

      wp_table.press_keys(:left)
      hierarchies.expect_hierarchy_at(parent, collapsed: true)
      expect(page).to be_axe_clean.within(wp_table.axe_scope)
    end

    it "numbers the rows without a total" do
      wp_table.expect_row_positions(rowcount: -1, rows: [1, 2, 3, 4])
    end
  end
end
