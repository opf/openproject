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

RSpec.describe "OS-synced theme without the JS bundle", :js do
  shared_let(:user) { create(:user, preferences: { theme: "sync_with_os" }) }

  def emulate_media(**features)
    page.driver.browser.page.command(
      "Emulation.setEmulatedMedia",
      features: features.map { |name, value| { name: name.to_s.tr("_", "-"), value: } }
    )
  end

  def without_external_scripts
    browser = page.driver.browser
    browser.network.intercept(resource_type: "Script")
    handler = browser.on(:request) { |request, *| request.abort }

    begin
      yield
    ensure
      browser.page.off(:request, handler)
      browser.page.command("Fetch.disable")
    end
  end

  it "resolves a dark OS to the dark theme on the login page without the JS bundle" do
    User.anonymous.pref.update!(settings: { "theme" => "sync_with_os" })
    emulate_media(prefers_color_scheme: "dark")

    without_external_scripts do
      visit signin_path

      expect(page).to have_css("body[data-color-mode='dark'][data-dark-theme='dark']")
      expect(page).to have_no_css("body[data-light-theme]")
    end
  end

  shared_examples "stamps the theme without the JS bundle" do |description, mode:, theme:, media: {}, pref: nil|
    it "resolves #{description} to #{theme} on the home page without the JS bundle" do
      other = mode == "light" ? "dark" : "light"
      user.pref.update!(settings: user.pref.settings.merge(pref => true)) if pref
      login_as user
      emulate_media(prefers_color_scheme: mode, **media)

      without_external_scripts do
        visit home_path

        expect(page).to have_css("body[data-color-mode='#{mode}'][data-#{mode}-theme='#{theme}']")
        expect(page).to have_no_css("body[data-#{other}-theme]")
      end
    end
  end

  include_examples "stamps the theme without the JS bundle", "a light OS",
                   mode: "light", theme: "light"
  include_examples "stamps the theme without the JS bundle", "a dark OS asking for more contrast",
                   mode: "dark", theme: "dark_high_contrast", media: { prefers_contrast: "more" }
  include_examples "stamps the theme without the JS bundle", "a light OS asking for more contrast",
                   mode: "light", theme: "light_high_contrast", media: { prefers_contrast: "more" }
  include_examples "stamps the theme without the JS bundle", "a dark OS with the forced dark contrast preference",
                   mode: "dark", theme: "dark_high_contrast", pref: "force_dark_theme_contrast"
  include_examples "stamps the theme without the JS bundle", "a light OS with the forced light contrast preference",
                   mode: "light", theme: "light_high_contrast", pref: "force_light_theme_contrast"
  include_examples "stamps the theme without the JS bundle", "a light OS ignoring the forced dark contrast preference",
                   mode: "light", theme: "light", pref: "force_dark_theme_contrast"
  include_examples "stamps the theme without the JS bundle", "a dark OS ignoring the forced light contrast preference",
                   mode: "dark", theme: "dark", pref: "force_light_theme_contrast"
end
