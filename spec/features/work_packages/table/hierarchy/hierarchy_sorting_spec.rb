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

RSpec.describe "Work Package table hierarchy and sorting", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }
  let(:sort_by) { Components::WorkPackages::SortBy.new }

  let!(:wp_root) do
    create(:work_package,
           project:,
           subject: "Parent",
           start_date: 10.days.ago,
           due_date: Date.current)
  end

  let!(:wp_child1) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: "Child at end",
           start_date: 2.days.ago,
           due_date: Date.current)
  end

  let!(:wp_child2) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: "Middle child",
           start_date: 5.days.ago,
           due_date: 3.days.ago)
  end

  let!(:wp_child3) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: "Child at beginning",
           start_date: 10.days.ago,
           due_date: 9.days.ago)
  end

  before do
    login_as(user)
  end

  it "can show hierarchies and sort by start_date" do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    # Expect order to be by IDs
    wp_table.expect_work_package_order wp_root, wp_child1, wp_child2, wp_child3

    # Enable sort by start date
    sort_by.update_criteria ["Start date", "asc"]
    loading_indicator_saveguard

    # Hierarchy still exists
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    # Expect order to be by dates
    wp_table.expect_work_package_order wp_root, wp_child3, wp_child2, wp_child1
  end
end
