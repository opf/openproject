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

RSpec.describe "Refreshing in inline-create row", :flaky, :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "category"]
    query.filters.clear

    query.save!
    query
  end

  before do
    login_as user
    wp_table.visit_query(query)
  end

  it "correctly updates the set of active columns" do
    expect(page).to have_css(".wp--row", count: 0)

    wp_table.click_inline_create
    expect(page).to have_css(".wp--row", count: 1)

    expect(page).to have_css(".wp-inline-create-row")
    expect(page).to have_css(".wp-inline-create-row .wp-table--cell-td.subject")
    expect(page).to have_css(".wp-inline-create-row .wp-table--cell-td.category")

    columns.add "% Complete"
    expect(page).to have_css(".wp-inline-create-row .wp-table--cell-td.wp-table--cell-td.percentageDone")
  end
end
