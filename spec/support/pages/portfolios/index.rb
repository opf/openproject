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

require "support/pages/page"

module Pages
  module Portfolios
    class Index < ::Pages::Page
      include ::Components::Common::Filters

      def path(*)
        "/portfolios"
      end

      def expect_portfolios_listed(*portfolios)
        within_portfolio_list do
          portfolios.each do |portfolio|
            expect(page).to have_text(portfolio.name)
          end
        end
      end

      def expect_portfolios_not_listed(*portfolios)
        within_portfolio_list do
          portfolios.each do |portfolio|
            case portfolio
            when Project
              expect(page).to have_no_text(portfolio.name)
            when String
              expect(page).to have_no_text(portfolio)
            else
              raise ArgumentError, "#{portfolio.inspect} is not a Portfolio or a String"
            end
          end
        end
      end

      def expect_portfolio_at_place(portfolio, place)
        within_portfolio_list do
          expect(page)
            .to have_css(".portfolio:nth-of-type(#{place}) .portfolio-name", text: portfolio.name)
        end
      end

      def expect_portfolios_in_order(*portfolios)
        portfolios.each_with_index do |portfolio, index|
          expect_portfolio_at_place(portfolio, index + 1)
        end
      end

      def expect_title(name)
        expect(page).to have_css('[data-test-selector="portfolio-query-name"]', text: name)
      end

      def expect_status_bar_percentage(portfolio, status_text, percentage, find_row: true)
        blk = Proc.new do
          status = page.find_test_selector("op-portfolios--status-#{status_text}")
          status_percentage = status["data-percentage"]
          expect(status_percentage).to eq(percentage.to_s)
        end

        if find_row
          within_row(portfolio, &blk)
        else
          blk.call
        end
      end

      def expect_status_of(portfolio, status_text)
        expect(page).to have_css("#projects-status-button-component-#{portfolio.id} .Button-label", text: status_text)
      end

      def click_status_button(portfolio)
        page.find("#projects-status-button-component-#{portfolio.id} .op-status-button").click
      end

      def select_status_from_dropdown(portfolio, status_text)
        click_status_button portfolio
        page.find("#projects-status-button-component-#{portfolio.id} .op-status-button .ActionListItem",
                  text: status_text,
                  exact_text: true).click

        wait_for_reload
      end

      def expect_filter_available(filter_name)
        expect(page).to have_select("add_filter_select", with_options: [filter_name])
      end

      def expect_filter_not_available(filter_name)
        expect(page).to have_no_select("add_filter_select", with_options: [filter_name])
      end

      def filter_by_active(value)
        set_filter("active", "Active", "is", [value])
        wait_for_reload
      end

      def filter_by_name_and_identifier(value, send_keys: false)
        set_name_and_identifier_filter([value], send_keys:)
        wait_for_reload
      end

      def open_more_menu
        wait_for_network_idle
        page.find('[data-test-selector="portfolio-more-dropdown-menu"]').click
      end

      def expect_more_menu_item(item)
        open_more_menu
        expect(page).to have_css(".ActionListItem", text: item, exact_text: true)
      end

      def click_more_menu_item(item)
        open_more_menu
        page.find(".ActionListItem", text: item, exact_text: true).click
        wait_for_network_idle
      end

      def expect_new_portfolio_button
        expect(page).to have_css('[data-test-selector="portfolio-new-button"]')
      end

      def expect_no_new_portfolio_button
        expect(page).to have_no_css('[data-test-selector="portfolio-new-button"]')
      end

      def create_new_portfolio
        page.find('[data-test-selector="portfolio-new-button"]').click
      end

      def expect_hover_card(portfolio, options = {})
        expect(page).to have_test_selector("op-portfolios--hover-card-#{portfolio.id}", **options)
      end

      def sidebar_menu_items
        page.find_by_id("menu-sidebar").all(".op-submenu--item-title").map(&:text)
      end

      def within_portfolio_list(&)
        within_test_selector "op-portfolios--portfolios", &
      end

      def within_row(portfolio)
        row = page.find(".portfolio[data-test-selector='op-portfolios--portfolio-#{portfolio.id}']")
        row.hover
        within row do
          yield row
        end
      end

      private

      def boolean_filter?(filter)
        %w[active member_of favorited public templated].include?(filter.to_s)
      end
    end
  end
end
