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

RSpec.describe "deleting a cost type", :js do
  let!(:user) { create(:admin) }
  let!(:cost_type) do
    type = create(:cost_type, name: "Translations")
    create(:cost_rate, cost_type: type, rate: 1.00)
    type
  end

  before do
    login_as user
  end

  it "can delete the cost type" do
    visit cost_types_path

    within("#delete_cost_type_#{cost_type.id}") do
      scroll_to_and_click(find("button.submit_cost_type"))
    end

    # Expect no results if not locked
    expect_angular_frontend_initialized
    expect(page).to have_css ".generic-table--no-results-container", wait: 10

    SeleniumHubWaiter.wait
    # Show locked
    find_by_id("include_deleted").set true
    click_on "Apply"

    # Expect no results if not locked
    expect(page).to have_text I18n.t(:label_locked_cost_types)

    expect(page).to have_css(".restore_cost_type")
    expect(page).to have_css(".cost-types--list-deleted td", text: "Translations")
  end
end
