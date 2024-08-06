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

RSpec.describe "work package reports", :js do
  let(:project) { create(:project_with_types, types: [type_a]) }
  let(:user) { create(:user, member_with_permissions: { project => %i(view_work_packages) }) }

  let(:type_a) do
    create(:type_with_workflow, name: "Type A").tap do |t|
      t.statuses.last.update_attribute(:is_closed, true)
    end
  end

  let!(:wp1) { create(:work_package, project:, type: type_a, status: type_a.statuses.first) }
  let!(:wp2) { create(:work_package, project:, type: type_a, status: type_a.statuses.last) }

  let(:wp_table_page) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
  end

  it "allows navigating to the reports page and drilling down" do
    wp_table_page.visit!

    within ".main-menu--children" do
      click_on "Summary"
    end

    expect(page)
      .to have_content "TYPE"
    expect(page)
      .to have_content "PRIORITY"
    expect(page)
      .to have_content "ASSIGNEE"
    expect(page)
      .to have_content "ACCOUNTABLE"

    expect(page)
      .to have_css "thead th:nth-of-type(2)", text: type_a.statuses.first.name.upcase
    expect(page)
      .to have_css "thead th:nth-of-type(3)", text: type_a.statuses.last.name.upcase

    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(1)", text: type_a.name
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(4)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(5)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(6)", text: 2

    # Clicking on the further analyze link will lead to a page focusing on type
    click_link "Further analyze: Type"

    expect(page)
      .to have_content "TYPE"
    expect(page)
      .to have_no_content "PRIORITY"
    expect(page)
      .to have_no_content "ASSIGNEE"
    expect(page)
      .to have_no_content "ACCOUNTABLE"

    expect(page)
      .to have_css "thead th:nth-of-type(2)", text: type_a.statuses.first.name.upcase
    expect(page)
      .to have_css "thead th:nth-of-type(3)", text: type_a.statuses.last.name.upcase

    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(1)", text: type_a.name
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(4)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(5)", text: 1
    expect(page)
      .to have_css "tbody tr:nth-of-type(1) td:nth-of-type(6)", text: 2

    # Clicking on a number in the table will lead to the wp list filtered by the type
    within "tbody tr:first-of-type td:nth-of-type(2)" do
      click_link "1"
    end

    wp_table_page.expect_work_package_listed(wp1)
    wp_table_page.ensure_work_package_not_listed!(wp2)
  end
end
