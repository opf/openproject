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

RSpec.describe "Work Package table group headers", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:category) { create(:category, project:, name: "Foo") }
  let(:category2) { create(:category, project:, name: "Bar") }

  let!(:wp_cat1) { create(:work_package, project:, category:) }
  let!(:wp_cat2) { create(:work_package, project:, category: category2) }
  let!(:wp_none) { create(:work_package, project:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { Components::WorkPackages::GroupBy.new }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "category"]
    query.show_hierarchies = false

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(wp_cat1)
    wp_table.expect_work_package_listed(wp_cat2)
    wp_table.expect_work_package_listed(wp_none)
  end

  it "shows group headers for group by category" do
    # Group by category
    group_by.enable_via_menu "Category"

    # Expect table to be grouped as WP created above
    group_by.expect_number_of_groups 3
    group_by.expect_grouped_by_value "Foo", 1
    group_by.expect_grouped_by_value "Bar", 1
    group_by.expect_grouped_by_value "-", 1

    # Update category of wp_none
    cat = wp_table.edit_field(wp_none, :category)
    cat.activate!
    cat.set_value "Foo"

    loading_indicator_saveguard

    # Expect changed groups
    group_by.expect_number_of_groups 2
    group_by.expect_grouped_by_value "Foo", 2
    group_by.expect_grouped_by_value "Bar", 1
  end

  context "with multiple versions active",
          with_settings: { work_package_multiple_versions: true } do
    let(:version_one) { create(:version, project:, name: "1.0") }
    let(:version_two) { create(:version, project:, name: "2.0") }

    let!(:wp_cat1) do
      create(:work_package, project:, category:, version: version_one)
    end
    let!(:wp_cat2) do
      create(:work_package, project:, category: category2, version: version_one).tap do |wp|
        create(:work_package_version, work_package: wp, version: version_two)
      end
    end

    it "shows one group header per target version set" do
      group_by.enable_via_menu "Target versions"

      # The version set is the group key: {1.0} and {1.0, 2.0} are separate
      # groups, work packages without target versions are grouped under "-"
      group_by.expect_number_of_groups 3
      group_by.expect_grouped_by_value "1.0", 1
      group_by.expect_grouped_by_value "1.0, 2.0", 1
      group_by.expect_grouped_by_value "-", 1
    end
  end
end
