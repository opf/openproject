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

RSpec.describe "Work Package table child relations", :js do
  let(:user) { create(:admin) }

  let(:type) { create(:type) }
  let(:type2) { create(:type) }
  let(:project) { create(:project, types: [type, type2]) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:relations) { Components::WorkPackages::Relations.new(relations) }
  let(:columns) { Components::WorkPackages::Columns.new }

  let!(:parent) { create(:work_package, project:, type: type2) }
  let!(:child1) { create(:work_package, project:, type:, parent:) }
  let!(:child2) { create(:work_package, project:, type:, parent:) }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject"]
    query.filters.clear

    query.save!
    query
  end

  before do
    login_as(user)
  end

  it "displays expandable child relation columns" do
    # Now visiting the query for category
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(parent, child1, child2)

    columns.add("Children")

    parent_row = wp_table.row(parent)
    child1_row = wp_table.row(child1)

    # Expect count for parent in both columns to be two
    expect(parent_row).to have_css(".relationChild .wp-table--relation-count", text: "2")

    # Expect count for child1 in both columns to be not rendered
    expect(child1_row).to have_no_css(".relationChild .wp-table--relation-count")

    # Expand first column
    parent_row.find(".relationChild .wp-table--relation-indicator").click
    expect(page).to have_css(".__relations-expanded-from-#{parent.id}", count: 2)
    related_row = page.first(".__relations-expanded-from-#{parent.id}")
    expect(related_row).to have_css("td.wp-table--relation-cell-td", text: "Child")

    # Collapse
    parent_row.find(".relationChild .wp-table--relation-indicator").click
    expect(page).to have_no_css(".__relations-expanded-from-#{parent.id}")
  end
end
