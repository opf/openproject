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

RSpec.describe "Work package hierarchies in two embedded tables", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) do
    create(:project, :with_internal_wiki, enabled_module_names: %w[work_package_tracking wiki])
  end
  shared_let(:parent) { create(:work_package, project:, subject: "Parent") }
  shared_let(:child) { create(:work_package, project:, parent:, subject: "Child") }

  let(:query_props) do
    {
      "columns[]" => %w[id subject],
      showHierarchies: true,
      timelineVisible: false,
      groupBy: "",
      filters: JSON.dump([{ status: { operator: "o", values: [] } }]),
      sortBy: JSON.dump([%w[id asc]])
    }
  end
  let(:macro) { %(<macro class="embedded-table" data-query-props="#{CGI.escapeHTML(query_props.to_json)}"></macro>) }
  let!(:wiki_page) do
    create(:wiki_page, wiki: project.wiki, title: "Two tables", text: <<~MARKDOWN)
      ## Table A

      #{macro}

      ## Table B

      #{macro}
    MARKDOWN
  end
  let(:hierarchies) { Components::WorkPackages::Hierarchies.new }
  let(:embedded_tables) { ".wiki-content opce-macro-embedded-table" }

  before do
    login_as admin
    visit project_wiki_path(project, wiki_page)
  end

  it "collapses a hierarchy only in the table where it was toggled" do
    expect(page).to have_css("#{embedded_tables} tr", text: "Child", count: 2, wait: 10)

    first_table, second_table = page.all(embedded_tables)

    within(first_table) do
      hierarchies.toggle_row(parent)
      hierarchies.expect_hierarchy_at(parent, collapsed: true)
      hierarchies.expect_hidden(child)
    end

    within(second_table) do
      hierarchies.expect_hierarchy_at(parent, collapsed: false)
      expect(page).to have_css("tr", text: "Child")
    end
  end
end
