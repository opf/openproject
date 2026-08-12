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
require "support/finders/test_selector_finders"

module Components
  module Projects
    class TopMenu
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include ::TestSelectorFinders

      def toggle
        page.find_by_id("projects-menu").click
        wait_for_network_idle(timeout: 10)
      end

      # Ensures modal registers as #open? before proceeding
      def toggle!
        toggle
        expect_open
      end

      def open?
        page.has_selector?(search_selector)
      end

      def switch_mode(mode)
        within_test_selector("op-header-project-select") do
          find_button(mode).click
        end
      end

      def expect_current_mode(mode)
        within_test_selector("op-header-project-select") do
          expect(page).to have_css(".SegmentedControl-item--selected", text: mode)
        end
      end

      def expect_current_project(name)
        page.find_by_id("projects-menu", text: name)
      end

      def expect_open
        page.find(search_selector)
      end

      def expect_closed
        expect(page).to have_no_selector(search_selector)
      end

      def search(query)
        search_field.set query
      end

      def clear_search
        search_field.set ""
        search_field.send_keys :backspace
      end

      def search_and_select(query)
        search query
        wait_for_network_idle
        selector = "#{results_selector} #{item_selector}"
        item = page.first(selector, text: query, wait: 5) || page.find(selector, wait: 5)
        item.click
      end

      def search_results
        page.find results_selector, wait: 10
      end

      def search_field
        page.find search_selector, wait: 10
      end

      def expand_node_for(name)
        item = page.find("#{results_selector} #{item_selector}", text: name, wait: 10)
        item.find(:xpath, "preceding-sibling::*[contains(@class, 'TreeViewItemToggle')]").click
      end

      def expect_result(name, disabled: false, workspace_badge: nil)
        selector = disabled ? item_disabled_selector : item_selector
        item = page.find("#{results_selector} #{selector}", text: name, wait: 10)

        return if workspace_badge.nil?

        if workspace_badge
          expect(item).to have_octicon
          expect(item).to have_primer_text(workspace_badge, class: "description")
        else
          expect(item).to have_no_octicon
          expect(item).to have_no_primer_text(class: "description")
        end
      end

      def expect_no_result(name)
        expect(page).to have_no_selector("#{results_selector} #{item_selector}", text: name, wait: 5)
      end

      def expect_blankslate
        expect(page).not_to have_test_selector("op-header-project-select--no-results", wait: 0)
      end

      def expect_item_with_hierarchy_level(hierarchy_level:, item_name:)
        hierarchy_selector = ".TreeViewItemContainer[style*='--level: #{hierarchy_level};']"
        expect(page)
          .to have_css("#{results_selector} #{hierarchy_selector} #{item_selector}", text: item_name, wait: 10)
      end

      def expect_project_create_button
        expect(page).to have_test_selector("create-project-btn")
      end

      def expect_no_project_create_button
        expect(page).to have_no_test_selector("create-project-btn")
      end

      def expect_project_list_button
        expect(page).to have_test_selector("list-project-btn")
      end

      def expect_no_project_list_button
        expect(page).to have_no_test_selector("list-project-btn")
      end

      def item_selector
        '[data-test-selector="op-header-project-select--item"]'
      end

      def item_disabled_selector
        "#{item_selector}[aria-disabled='true']"
      end

      def results_selector
        '[data-test-selector="op-header-project-select--list"]'
      end

      def active_item_selector
        "#{item_selector}[aria-current='true']"
      end

      def remove_item_selector
        "[data-test-selector='op-header-project-select--remove-item']"
      end

      def search_selector
        "[data-test-selector='op-header-project-select--search']"
      end
    end
  end
end
