# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Portfolios", "index", :js, with_ee: :portfolio_management do # TODO: test without enterprise feature
  let!(:portfolio_a) { create(:portfolio, name: "Portfolio A") }
  let!(:portfolio_b) { create(:portfolio, name: "Portfolio B") }
  let!(:portfolio_favorited) { create(:portfolio, name: "Favorited") }
  let!(:inactive_portfolio) { create(:portfolio, name: "Inactive", active: false) }

  let(:portfolios_page) { Pages::Portfolios::Index.new }

  let(:user) do
    create(:admin,
           global_permissions: %i[add_portfolios],
           member_with_permissions: {
             portfolio_a => [:view_project]
           })
  end

  current_user { user }

  before do
    create(:favorite, user: current_user, favorited: portfolio_favorited)
    create(:project, parent: portfolio_a, status_code: "on_track")
    create(:program, parent: portfolio_a, status_code: "at_risk").tap do |program_a|
      create(:project, parent: program_a, status_code: "on_track")
    end

    portfolios_page.visit!
  end

  it "lists available active portfolios" do
    expect(page).to have_title("Portfolios")
    portfolios_page.expect_title("Active portfolios")

    portfolios_page.expect_portfolios_listed(portfolio_a, portfolio_b, portfolio_favorited)
    portfolios_page.expect_portfolios_not_listed(inactive_portfolio)

    portfolios_page.within_row(portfolio_a) do
      # Portfolios link to their overview page
      expect(page).to have_link(portfolio_a.name, href: project_overview_path(portfolio_a))

      expect(page).to have_text("2 projects")
      expect(page).to have_text("1 program")
    end
  end

  it "shows the create new portfolio button" do
    portfolios_page.expect_new_portfolio_button
    portfolios_page.create_new_portfolio

    expect(page).to have_current_path(new_portfolio_path)
  end

  context "with a restricted user" do
    let(:user) do
      create(:user,
             global_permissions: [],
             member_with_permissions: { portfolio_a => [:view_project] })
    end

    it "does not show the create new portfolio button" do
      portfolios_page.expect_title("Active portfolios")
      portfolios_page.expect_portfolios_listed(portfolio_a)

      portfolios_page.expect_no_new_portfolio_button
    end

    it "only lists visible portfolios" do
      portfolios_page.expect_portfolios_not_listed(inactive_portfolio, portfolio_b, portfolio_favorited)
    end
  end

  it "offers queries in the menu items" do
    menu_items = portfolios_page.sidebar_menu_items

    expected_menu_items = [
      "Active portfolios",
      "My portfolios",
      "Favorite portfolios",
      "Archived portfolios"
    ]

    expect(menu_items).to eq(expected_menu_items)
  end

  it "lets you select a query by clicking on its menu item" do
    click_on "Favorite portfolios"
    portfolios_page.expect_title("Favorite portfolios")
    portfolios_page.expect_portfolios_listed(portfolio_favorited)
    portfolios_page.expect_portfolios_not_listed(portfolio_a, portfolio_b, inactive_portfolio)

    click_on "My portfolios"
    portfolios_page.expect_title("My portfolios")
    portfolios_page.expect_portfolios_listed(portfolio_a)
    portfolios_page.expect_portfolios_not_listed(portfolio_favorited, portfolio_b, inactive_portfolio)

    click_on "Archived portfolios"
    portfolios_page.expect_title("Archived portfolios")
    portfolios_page.expect_portfolios_listed(inactive_portfolio)
    portfolios_page.expect_portfolios_not_listed(portfolio_a, portfolio_b, portfolio_favorited)

    # For archived portfolios, no status bar, favorite button or project count is shown:
    portfolios_page.within_row(inactive_portfolio) do
      expect(page).to have_no_test_selector("op-portfolios--favorite-button")
      expect(page).to have_no_test_selector("op-portfolios--sub-status-bar")
      expect(page).to have_no_test_selector("op-portfolios--status")
      expect(page).to have_no_text("0 projects")
      expect(page).to have_no_text("0 programs")
    end
  end

  it "allows you to favorite and unfavorite portfolios" do
    expect(portfolio_a).not_to be_favorited_by(current_user)

    portfolios_page.within_row(portfolio_a) do
      page.find_test_selector("op-portfolios--favorite-button").click
    end

    expect(portfolio_a).to be_favorited_by(current_user)
  end

  it "lets you link to the desired query via param" do
    visit "#{portfolios_page.path}?query_id=favorited_portfolios"

    portfolios_page.expect_title("Favorite portfolios")
  end

  it "lets you apply filters" do
    click_button accessible_name: "Portfolio name filter"
    portfolios_page.filter_by_name_and_identifier("Favorited")
    portfolios_page.expect_portfolios_listed(portfolio_favorited)
    portfolios_page.expect_portfolios_not_listed(portfolio_a, portfolio_b, inactive_portfolio)
    page.find_by_id("portfolio-filters-form-clear-button").click

    portfolios_page.toggle_filters_section
    portfolios_page.filter_by_active("no")
    portfolios_page.expect_portfolios_listed(inactive_portfolio)
    portfolios_page.expect_portfolios_not_listed(portfolio_a, portfolio_b, portfolio_favorited)
  end

  it "allows seeing and changing the portfolio status" do
    portfolios_page.expect_status_of(portfolio_a, "Not set")
    portfolios_page.expect_status_of(portfolio_favorited, "Not set")

    portfolios_page.select_status_from_dropdown(portfolio_favorited, "At risk")

    portfolios_page.expect_status_of(portfolio_favorited, "At risk")
    portfolios_page.expect_status_of(portfolio_a, "Not set")
  end

  describe "status of sub-items" do
    it "shows the status summary of sub-items" do
      portfolios_page.within_row(portfolio_a) do
        expect(page).to have_test_selector("op-portfolios--sub-status-bar")

        portfolios_page.expect_status_bar_percentage(portfolio_a, "on_track", "66.7", find_row: false)
        portfolios_page.expect_status_bar_percentage(portfolio_a, "at_risk", "33.3", find_row: false)

        # The status bar shows a hover card on hover:
        page.find_test_selector("op-portfolios--sub-status-bar").hover
      end
      portfolios_page.expect_hover_card(portfolio_a, text: /3\ssub-items\s2\sOn track\s1\sAt risk/)
    end

    it "does show an empty status bar if no sub-item has a status" do
      # Statusless sub-item:
      create(:project, parent: portfolio_favorited)
      portfolios_page.visit!

      portfolios_page.within_row(portfolio_favorited) do
        expect(page).to have_text("1 project")
        expect(page).to have_test_selector("op-portfolios--sub-status-bar")

        portfolios_page.expect_status_bar_percentage(portfolio_favorited, "not_set", "100.0", find_row: false)

        page.find_test_selector("op-portfolios--sub-status-bar").hover
      end

      portfolios_page.expect_hover_card(portfolio_favorited, text: /1\ssub-item\s1\sNot set/)
    end
  end

  context "when using the more menu" do
    it "offers the zen mode" do
      portfolios_page.expect_more_menu_item("Zen mode")
    end
  end

  context "without the necessary permissions to see portfolios" do
    current_user { create(:user) }

    it "cannot see portfolios" do
      expect(page).to have_content "[Error 403] You are not authorized to access this page."
    end
  end
end
