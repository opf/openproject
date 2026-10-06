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

require "spec_helper"

RSpec.describe "Auto-rendered settings pages", :js do
  current_user { create(:admin) }

  it "shows settings depending on a check box once it is checked and saves them" do
    visit admin_settings_api_path

    expect(page).to have_field "Enable CORS", checked: false
    expect(page).to have_no_field "API V3 Cross-Origin Resource Sharing (CORS) allowed origins"

    check "Enable CORS"
    fill_in "API V3 Cross-Origin Resource Sharing (CORS) allowed origins", with: "https://a.example.com\nhttps://b.example.com"
    click_on "Save"

    expect_and_dismiss_flash(message: I18n.t(:notice_successful_update))

    RequestStore.clear!
    expect(Setting.apiv3_cors_enabled?).to be true
    expect(Setting.apiv3_cors_origins).to eq %w[https://a.example.com https://b.example.com]
  end
end
