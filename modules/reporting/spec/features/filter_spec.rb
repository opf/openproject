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

RSpec.describe "Cost report calculations", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    login_as user
    visit cost_reports_path(project)
  end

  def clear_project_filter
    within "#filter_project_id" do
      find(".filter_rem").click
    end
  end

  def reload_page
    page.refresh
    wait_for_reload
  end

  it "provides filtering" do
    # Then filter "spent_on" should be visible
    # And filter "user_id" should be visible
    expect(page).to have_css("#filter_project_id")
    expect(page).to have_css("#filter_spent_on")
    expect(page).to have_css("#filter_user_id")

    # Regression #48633
    # Remove filter:
    # And I click on the filter's "Clear" button
    clear_project_filter
    # Then filter "project_id" should not be visible
    expect(page).to have_no_css("#filter_project_id")

    # Remove filters:
    # And I click on "Clear"
    click_on "Clear"
    # Then filter "spent_on" should not be visible
    # And filter "user_id" should not be visible
    expect(page).to have_no_css("#filter_spent_on")
    expect(page).to have_no_css("#filter_user_id")

    # Reload restores the query
    # And the user with the login "developer" should be selected for "User Value"
    # And "!" should be selected for "User Operator Open this filter with 'ALT' and arrow keys."
    reload_page
    expect(page).to have_css("#filter_spent_on")
    expect(page).to have_css("#filter_user_id")

    user_autocompleter = find("opce-user-autocompleter#user_id_select_1")
    expect_current_autocompleter_value(user_autocompleter, "me")
  end

  it "allows selecting a locked user in the user filter" do
    locked_user = create(:locked_user)

    user_autocompleter = find("opce-user-autocompleter#user_id_select_1")
    dropdown = search_autocomplete(user_autocompleter, query: locked_user.name)

    expect(dropdown).to have_css(".ng-option", text: locked_user.name)
  end
end
