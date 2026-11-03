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

RSpec.describe "What's new menu", :js do
  let(:user) { create(:user) }
  let(:release) { WhatsNew::Release.new(major: 18, minor: 0) }
  let(:items) do
    [
      WhatsNew::Release::Item.new(key: "first", title: "First feature", description: "The first one", url: "/"),
      WhatsNew::Release::Item.new(key: "second", title: "Second feature", description: "The second one", url: "/")
    ]
  end

  before do
    allow(WhatsNew::Release).to receive(:current).and_return(release)
    allow(release).to receive(:items).and_return(items)
    login_as user
  end

  def open_item(title)
    window_opened_by { click_link(title) }.close
  end

  def left_of(test_selector)
    page.evaluate_script(
      "document.querySelector('[data-test-selector=\"#{test_selector}\"]').getBoundingClientRect().left"
    )
  end

  context "with items for the current release" do
    it "places the button left of the notification bell" do
      visit home_path

      expect(page).to have_test_selector("op-header-whats-new-button")
      expect(left_of("op-header-whats-new-button")).to be < left_of("op-ian-bell")
    end

    it "clears the badge on open and keeps the dots until the items are read" do
      visit home_path

      expect(page).to have_test_selector("op-header-whats-new-badge")
      expect(page).to have_no_test_selector("op-header-whats-new-content", visible: :all)
      expect(page).to have_test_selector("op-header-whats-new-skeleton", visible: :all)

      find_test_selector("op-header-whats-new-button").click

      within_test_selector("op-header-whats-new-content") do
        expect(page).to have_heading("What's new in 18.0")
        expect(page).to have_no_css("img")
        expect(page).to have_css("[data-whats-new-dot]", count: 2)
      end
      expect(page).to have_no_test_selector("op-header-whats-new-skeleton", visible: :all)
      expect(page).to have_no_test_selector("op-header-whats-new-badge")

      visit home_path

      expect(page).to have_test_selector("op-header-whats-new-button")
      expect(page).to have_no_test_selector("op-header-whats-new-badge")

      find_test_selector("op-header-whats-new-button").click

      within_test_selector("op-header-whats-new-content") do
        expect(page).to have_css("[data-whats-new-dot]", count: 2)

        open_item("First feature")

        expect(page).to have_no_css("[data-whats-new-dot='first']")
        expect(page).to have_css("[data-whats-new-dot='second']")
      end

      visit home_path
      find_test_selector("op-header-whats-new-button").click

      within_test_selector("op-header-whats-new-content") do
        expect(page).to have_css("[data-whats-new-dot]", count: 1)

        open_item("Second feature")

        expect(page).to have_no_css("[data-whats-new-dot]")
      end
    end

    it "does not show the mobile link in the user menu" do
      visit home_path

      find_test_selector("op-app-header--user-menu-button").click

      expect(page).to have_css("#op-app-header--user-menu-list")
      expect(page).to have_no_link("What's new in 18.0")
    end

    context "on mobile" do
      include_context "with mobile screen size"

      it "opens the items from the user menu and clears its badge" do
        visit home_path

        expect(page).to have_no_test_selector("op-header-whats-new-button")

        find_test_selector("op-app-header--user-menu-button").click
        within("#op-app-header--user-menu-list") do
          expect(page).to have_test_selector("op-menu--whats-new-badge")
          click_link "What's new in 18.0"
        end

        within_test_selector("op-header-whats-new-dialog") do
          expect(page).to have_css("[data-whats-new-dot]", count: 2)

          open_item("First feature")

          expect(page).to have_no_css("[data-whats-new-dot='first']")
          expect(page).to have_css("[data-whats-new-dot='second']")
        end

        visit home_path
        find_test_selector("op-app-header--user-menu-button").click

        within("#op-app-header--user-menu-list") do
          expect(page).to have_link("What's new in 18.0")
          expect(page).to have_no_test_selector("op-menu--whats-new-badge")
        end
      end
    end
  end

  context "when the user first opened the release six days ago" do
    before do
      travel_to(6.days.ago) { user.pref.mark_whats_new_seen(release.version_key) }
      user.pref.save!
    end

    it "still shows the button without the badge" do
      visit home_path

      expect(page).to have_test_selector("op-header-whats-new-button")
      expect(page).to have_no_test_selector("op-header-whats-new-badge", visible: :all)
    end
  end

  context "when the user first opened the release eight days ago" do
    before do
      travel_to(8.days.ago) { user.pref.mark_whats_new_seen(release.version_key) }
      user.pref.save!
    end

    it "shows neither the button nor the user menu link" do
      visit home_path

      expect(page).to have_test_selector("header-help-button")
      expect(page).to have_no_test_selector("op-header-whats-new-button", visible: :all)

      find_test_selector("op-app-header--user-menu-button").click

      expect(page).to have_css("#op-app-header--user-menu-list")
      expect(page).to have_no_test_selector("op-menu--whats-new", visible: :all)
    end
  end

  context "without items for the current release" do
    let(:items) { [] }

    it "shows neither the button nor the user menu link" do
      visit home_path

      expect(page).to have_test_selector("header-help-button")
      expect(page).to have_no_test_selector("op-header-whats-new-button", visible: :all)

      find_test_selector("op-app-header--user-menu-button").click

      expect(page).to have_css("#op-app-header--user-menu-list")
      expect(page).to have_no_test_selector("op-menu--whats-new", visible: :all)
    end
  end
end
