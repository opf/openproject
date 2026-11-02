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

RSpec.describe "Work package pagination", :js do
  shared_let(:admin) { create(:admin) }

  let(:project) do
    create(:project, name: "project1", identifier: "project1")
  end

  shared_examples_for "paginated work package list" do
    let!(:work_package_1) { create(:work_package, project:) }
    let!(:work_package_2) { create(:work_package, project:) }
    let(:hierarchies) { Components::WorkPackages::Hierarchies.new }
    let(:pagination) { Components::TablePagination.new }

    before do
      login_as(admin)
      allow(Setting).to receive(:per_page_options).and_return "1, 50, 100"

      visit path
      expect(page).to have_current_path(expected_path, ignore_query: true)
    end

    it do
      expect(page).to have_content("All open")

      expect(page).to have_test_selector("op-breadcrumbs--item", text: "Work packages")
      expect(page).to have_css(".op-breadcrumbs--current", text: "All open", aria: { current: "page" })

      within(".work-packages-partitioned-query-space--container") do
        expect(page).to have_content(work_package_1.subject)
        expect(page).to have_no_content(work_package_2.subject)
      end
      hierarchies.disable_via_header
      wp_table.expect_row_positions(rowcount: 4, rows: [1, 2, 4])

      pagination.go_to_page(2)

      within(".work-packages-partitioned-query-space--container") do
        expect(page).to have_content(work_package_2.subject)
        expect(page).to have_no_content(work_package_1.subject)
      end
      wp_table.expect_row_positions(rowcount: 4, rows: [1, 3, 4])

      pagination.select_per_page(50)

      within(".work-packages-partitioned-query-space--container") do
        expect(page).to have_content(work_package_1.subject)
        expect(page).to have_content(work_package_2.subject)
      end
      wp_table.expect_row_positions(rowcount: 4, rows: [1, 2, 3, 4])
    end
  end

  context "with project scope" do
    it_behaves_like "paginated work package list" do
      let(:path) { project_work_packages_path(project) }
      let(:wp_table) { Pages::WorkPackagesTable.new(project) }
      let(:expected_path) { "/projects/project1/work_packages" }
    end
  end

  context "globally" do
    it_behaves_like "paginated work package list" do
      let(:path) { work_packages_path }
      let(:wp_table) { Pages::WorkPackagesTable.new }
      let(:expected_path) { "/work_packages" }
    end
  end
end
