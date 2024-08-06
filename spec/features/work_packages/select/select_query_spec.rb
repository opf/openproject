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

RSpec.describe "Query selection" do
  let(:project) { create(:project, identifier: "test_project", public: false) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end

  let(:default_status) { create(:default_status) }
  let(:wp_page) { Pages::WorkPackagesTable.new project }
  let(:filters) { Components::WorkPackages::Filters.new }

  let(:query) do
    build(:query, project:, public: true).tap do |query|
      query.filters.clear
      query.add_filter("assigned_to_id", "=", ["me"])
      query.add_filter("done_ratio", ">=", [10])
      query.save!
      create(:view_work_packages_table,
             query:)

      query
    end
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before do
    default_status

    login_as(current_user)
  end

  context "default view, without a query selected" do
    before do
      work_packages_page.visit_index
      filters.open
    end

    it "shows the default (status) filter", :js do
      filters.expect_filter_count 1
      filters.expect_filter_by "Status", "open", nil
    end
  end

  context "when a query is selected" do
    before do
      query

      work_packages_page.select_query query
    end

    it "shows the saved filters", :js do
      filters.open
      filters.expect_filter_by "Assignee", "is (OR)", ["me"]
      filters.expect_filter_by "Percent Complete", ">=", ["10"], "percentageDone"

      expect(page).to have_css("#{test_selector('wp-filter-button')} .badge", text: "2")
    end
  end

  context "when the selected query is changed" do
    let(:query2) do
      create(:query_with_view_work_packages_table,
             project:,
             public: true)
    end

    before do
      query
      query2

      work_packages_page.select_query query
    end

    it "updates the page upon query switching", :js do
      wp_page.expect_title query.name, editable: false

      find(".op-submenu--item-action", text: query2.name).click
    end
  end
end
