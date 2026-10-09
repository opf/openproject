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

require "spec_helper"

RSpec.describe "Main menu initial state" do
  shared_let(:user) { create(:user) }

  context "when rendered on the server" do
    before { login_as user }

    it "keeps the menu expanded without a cookie" do
      visit root_path

      expect(page).to have_css("#main-menu")
      expect(page).to have_no_css("#wrapper.hidden-navigation")
      expect(page).to have_no_css("html[style*='--main-menu-width']")
    end

    it "renders the menu collapsed from the cookie" do
      page.driver.browser.set_cookie("op_main_menu_width=0")
      visit root_path

      expect(page).to have_css("#wrapper.hidden-navigation")
      expect(page).to have_css("html[style*='--main-menu-width: 0px']")
    end

    it "renders a remembered width from the cookie" do
      page.driver.browser.set_cookie("op_main_menu_width=320")
      visit root_path

      expect(page).to have_css("html[style*='--main-menu-width: 320px']")
      expect(page).to have_no_css("#wrapper.hidden-navigation")
    end

    it "ignores a malformed cookie" do
      page.driver.browser.set_cookie("op_main_menu_width=wide")
      visit root_path

      expect(page).to have_css("#main-menu")
      expect(page).to have_no_css("#wrapper.hidden-navigation")
      expect(page).to have_no_css("html[style*='--main-menu-width']")
    end
  end

  context "when rendered on a page without a main menu" do
    it "does not collapse the layout" do
      page.driver.browser.set_cookie("op_main_menu_width=0")
      visit signin_path

      expect(page).to have_css("#wrapper.nosidebar")
      expect(page).to have_no_css(".hidden-navigation")
      expect(page).to have_no_css("html[style*='--main-menu-width']")
    end
  end

  context "when toggled in the browser", :js do
    before { login_as user }

    def menu_width_cookie
      page.driver.cookies["op_main_menu_width"]&.value
    end

    it "persists the state as a cookie and keeps it across a Turbo visit" do
      visit root_path
      expect_angular_frontend_initialized
      click_on accessible_name: "Collapse project menu", match: :first

      expect(page).to have_css("#wrapper.hidden-navigation")
      expect(menu_width_cookie).to eq("0")

      page.execute_script("window.opMenuSpecMarker = true")
      within "#content" do
        click_on "My page"
      end

      expect(page).to have_current_path(my_page_path)
      expect(page).to have_css("#wrapper.hidden-navigation")
      expect(page.evaluate_script("window.opMenuSpecMarker")).to be(true)

      expect_angular_frontend_initialized
      click_on accessible_name: "Expand project menu", match: :first

      expect(page).to have_no_css("#wrapper.hidden-navigation")
      expect(menu_width_cookie.to_i).to be > 0
    end

    context "on a narrow window" do
      include_context "with mobile screen size", 1000, 900

      it "collapses the menu and can still expand it" do
        visit root_path

        expect(page).to have_css("#wrapper.hidden-navigation")

        expect_angular_frontend_initialized
        click_on accessible_name: "Expand project menu", match: :first

        expect(page).to have_no_css("#wrapper.hidden-navigation")
        expect(page).to have_css("#main-menu", visible: :visible)
      end
    end
  end
end
