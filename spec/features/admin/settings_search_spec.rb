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

RSpec.describe "Searching settings in the administration", :js do
  current_user { create(:admin) }

  before do
    visit admin_settings_working_days_and_hours_path

    within("#main-menu") { click_on "Search settings" }
  end

  def search_for(query)
    find_test_selector("op-admin-settings-search--filter").fill_in(with: query)
  end

  it "filters the settings tree and highlights the selected setting" do
    search_for "host name"

    within_test_selector("op-admin-settings-search") do
      expect(page).to have_link "Host name"
      expect(page).to have_no_link "Application title"

      click_on "Host name"
    end

    expect(page).to have_current_path admin_settings_general_path
    expect(page).to have_css(".op-setting--highlighted", text: "Host name")
  end

  it "ignores punctuation and word order" do
    search_for "registration self"

    within_test_selector("op-admin-settings-search") do
      expect(page).to have_link "Self-registration"
      expect(page).to have_no_link "Application title"
    end
  end

  it "lists all settings below a matching menu item or tab" do
    search_for "passwords"

    within_test_selector("op-admin-settings-search") do
      expect(page).to have_link "Minimum length"
      expect(page).to have_no_link "Application title"
    end
  end

  it "combines words matching a tab and a setting" do
    search_for "passwords minimum"

    within_test_selector("op-admin-settings-search") do
      expect(page).to have_link "Minimum length"
      expect(page).to have_no_link "Enable password reset"
    end
  end

  it "finds settings by their description" do
    search_for "comma separated"

    within_test_selector("op-admin-settings-search") do
      expect(page).to have_link "Objects per page options"
      expect(page).to have_no_link "Application title"
    end
  end
end
