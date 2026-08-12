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
    visit admin_cost_types_path

    accept_confirm do
      scroll_to_and_click(find("[data-test-selector='op-admin-cost-type-#{cost_type.id}-lock']"))
    end

    # Active list becomes empty
    expect_angular_frontend_initialized
    expect(page).to have_css ".generic-table--empty-row", wait: 10

    # Switch to the locked tab via the segmented control
    click_on I18n.t("members.menu.locked")

    wait_for_network_idle

    # The locked cost type appears with a restore action
    expect(page).to have_css("[data-test-selector='op-admin-cost-type-#{cost_type.id}-restore']")
    expect(page).to have_css("td", text: "Translations")
  end
end
