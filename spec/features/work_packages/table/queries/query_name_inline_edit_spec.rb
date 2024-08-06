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

RSpec.describe "Query name inline edit", :js do
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:project) { create(:project) }
  let(:type) { project.types.first }
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           save_queries])
  end

  let(:work_package) do
    create(:work_package,
           project:,
           assigned_to: user,
           type:)
  end

  let(:assignee_query) do
    query = create(:query,
                   name: "Assignee Query",
                   project:,
                   user:)

    query.add_filter("assigned_to_id", "=", [user.id])
    query.save!

    query
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:columns) { Components::WorkPackages::Columns.new }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:query_title) { Components::WorkPackages::QueryTitle.new }

  before do
    login_as(user)
    work_package
    wp_table.visit_query assignee_query
  end

  it "allows renaming the query and shows changed state" do
    wp_table.expect_work_package_listed work_package
    query_title.expect_not_changed

    # Alter some filter
    filters.open
    filters.remove_filter :assignee

    # Expect query changed state visible
    query_title.expect_changed

    # Save query through icon
    query_title.press_save_button

    # Expect unchanged
    query_title.expect_not_changed

    # TODO: The notification should actually not be shown at all since no update
    # has taken place
    wp_table.expect_and_dismiss_toaster message: "Successful update."

    assignee_query.reload
    expect(assignee_query.filters.count).to eq(1)
    expect(assignee_query.filters.first.name).to eq :status_id

    url = URI.parse(page.current_url).query
    expect(url).to include("query_id=#{assignee_query.id}")
    expect(url).not_to match(/query_props=.+/)

    # Rename query
    query_title.rename "Not my assignee query"
    wp_table.expect_and_dismiss_toaster message: "Successful update."

    assignee_query.reload
    expect(assignee_query.name).to eq "Not my assignee query"

    # Rename query through context menu
    wp_table.click_setting_item "Rename view"

    expect(page).to have_focus_on(".editable-toolbar-title--input")
    page.driver.browser.switch_to.active_element.send_keys("Some other name")
    page.driver.browser.switch_to.active_element.send_keys(:return)

    wp_table.expect_and_dismiss_toaster message: "Successful update."

    assignee_query.reload
    expect(assignee_query.name).to eq "Some other name"
  end

  it "shows the save icon when changing the columns (Regression #32835)" do
    wp_table.expect_work_package_listed work_package
    query_title.expect_not_changed

    modal.open!
    modal.switch_to "Columns"

    columns.assume_opened
    columns.uncheck_all save_changes: false
    columns.add "Subject", save_changes: true

    query_title.expect_changed
  end
end
