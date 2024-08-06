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
require "features/work_packages/work_packages_page"

RSpec.describe "Select work package row", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  describe "sorting by version" do
    let(:work_package_1) do
      create(:work_package, project:)
    end
    let(:work_package_2) do
      create(:work_package, project:)
    end

    let(:version_1) do
      create(:version, project:,
                       name: "aaa_version")
    end
    let(:version_2) do
      create(:version, project:,
                       name: "zzz_version")
    end
    let(:columns) { Components::WorkPackages::Columns.new }
    let(:sort_by) { Components::WorkPackages::SortBy.new }

    before do
      login_as(user)

      work_package_1
      work_package_2

      work_packages_page.visit_index
    end

    include_context "work package table helpers"

    context "sorting by version" do
      before do
        work_package_1.update_attribute(:version_id, version_2.id)
        work_package_2.update_attribute(:version_id, version_1.id)
      end

      it "sorts by version although version is not selected as a column" do
        sort_by.open_modal
        sort_by.update_nth_criteria(0, "Version")
        expect_work_packages_to_be_in_order([work_package_1, work_package_2])
      end
    end
  end

  describe "sorting modal" do
    let(:sort_by) { Components::WorkPackages::SortBy.new }

    before do
      login_as user
      wp_table.visit!
    end

    it "provides the default sortation and allows using the value at another level (Regression WP#26792)" do
      # Expect current criteria
      sort_by.expect_criteria(["-", "asc"])

      # Expect we can change the criteria and reuse that value
      sort_by.open_modal
      sort_by.update_nth_criteria(0, "Type", descending: true)
      sort_by.update_nth_criteria(0, "ID", descending: true)
      sort_by.update_nth_criteria(1, "Type")

      sort_by.apply_changes
      sort_by.expect_criteria(["ID", "desc"], ["Type", "asc"])
    end
  end

  describe "parent sorting" do
    let(:sort_by) { Components::WorkPackages::SortBy.new }

    let(:parent) do
      create(:work_package,
             project:)
    end
    let(:child1) do
      create(:work_package,
             project:,
             parent:)
    end
    let(:child2) do
      create(:work_package,
             project:,
             parent:)
    end
    let(:grand_child1) do
      create(:work_package,
             project:,
             parent: child1)
    end
    let(:grand_child2) do
      create(:work_package,
             project:,
             parent: child2)
    end
    let(:grand_child3) do
      create(:work_package,
             project:,
             parent: child1)
    end

    before do
      allow(Setting).to receive(:per_page_options).and_return "4"

      parent
      child1
      grand_child1
      child2
      grand_child2
      grand_child3

      login_as user
      wp_table.visit!
    end

    it "default sortation (id) does not order depth first (Reverted in #29122)" do
      wp_table.expect_work_package_listed parent, child1, grand_child1, child2
      wp_table.expect_work_package_order parent.id, child1.id, grand_child1.id, child2
    end
  end
end
