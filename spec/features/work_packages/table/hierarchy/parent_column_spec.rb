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

RSpec.describe "Work Package table parent column", :js, :selenium do
  let(:user) { create(:admin) }
  let!(:parent) { create(:work_package, project:) }
  let!(:child) { create(:work_package, project:, parent:) }
  let!(:other_wp) { create(:work_package, project:) }
  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = ["subject", "parent"]
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end
  let(:project) { create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
  end

  it "shows parent columns correctly (Regression #26951)" do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(parent, child)

    # Hierarchy mode is enabled by default
    page.within(".wp-row-#{parent.id}") do
      expect(page).to have_css("td.parent", text: "-")
    end

    page.within(".wp-row-#{child.id}") do
      expect(page).to have_css("td.parent", text: "##{parent.id}")
    end
  end

  it "can edit the parent work package (Regression #43647)" do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(parent, child)

    parent_field = wp_table.edit_field(child, :parent)
    parent_field.update other_wp.subject

    wp_table.expect_and_dismiss_toaster message: "Successful update."

    child.reload
    expect(child.parent).to eq other_wp
  end
end
