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

RSpec.describe "My account disable keyboard shortcuts setting", :js do
  let(:user) { create(:user) }
  let(:global_search) { Components::GlobalSearch.new }

  before do
    login_as(user)
    visit my_account_path
  end

  it "can disable the keyboard short cuts" do
    click_on "Interface"

    # Per default, the keyboard short cuts are enabled
    expect(page).to have_unchecked_field("Disable keyboard shortcuts", visible: :visible)
    page.driver.send_keys("s")
    global_search.expect_open

    # Check the checkbox
    page.check("Disable keyboard shortcuts")
    expect(page).to have_checked_field("Disable keyboard shortcuts", visible: :visible)

    # Save
    click_button accessible_name: "Update look and feel"
    wait_for_network_idle
    expect(page).to have_checked_field("Disable keyboard shortcuts", visible: :visible)

    # Directly try to trigger the keyboard short cut again (which should not work any more)
    page.driver.send_keys("s")
    global_search.expect_closed

    # After a hard reload, the setting is still remembered and turned off
    page.refresh
    wait_for_network_idle
    expect(page).to have_checked_field("Disable keyboard shortcuts", visible: :visible)
    page.driver.send_keys("s")
    global_search.expect_closed
  end
end
