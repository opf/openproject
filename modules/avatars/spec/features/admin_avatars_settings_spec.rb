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

RSpec.describe "Admin avatars plugin settings" do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  before do
    Setting.plugin_openproject_avatars = { "enable_gravatars" => "1", "enable_local_avatars" => "1" }
  end

  it "shows the current settings and allows updating them" do
    visit "/admin/settings/plugin/openproject_avatars"

    expect(page).to have_checked_field("Enable user gravatars")
    expect(page).to have_checked_field("Enable user custom avatars")

    uncheck "Enable user gravatars"
    click_button "Apply"

    expect(page).to have_current_path("/admin/settings/plugin/openproject_avatars")
    expect_flash(message: I18n.t(:notice_successful_update))

    expect(page).to have_unchecked_field("Enable user gravatars")
    expect(page).to have_checked_field("Enable user custom avatars")

    expect(Setting.plugin_openproject_avatars["enable_gravatars"]).to eq("0")
  end
end
