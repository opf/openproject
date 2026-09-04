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

require_relative "../toasts/expectations"
require_relative "../flash/expectations"
require_relative "../capybara/wait_helpers"

module Pages
  class Page
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include TestSelectorFinders
    include RSpec::Matchers
    include OpenProject::StaticRouting::UrlHelpers
    include Toasts::Expectations
    include Flash::Expectations
    include RSpec::Wait
    include WaitHelpers

    def current_page?
      URI.parse(current_url).path == path
    end

    def visit!
      raise "No path defined" unless path

      visit(path)

      wait_for_reload
    end

    def reload!
      if using_cuprite?
        page.driver.browser.refresh
        wait_for_reload
      else
        page.driver.browser.navigate.refresh
      end
    end

    def accept_alert_dialog!
      alert_dialog.accept if selenium_driver?
    end

    def dismiss_alert_dialog!
      alert_dialog.dismiss if selenium_driver?
    end

    def alert_dialog
      page.driver.browser.switch_to.alert
    end

    def has_alert_dialog?
      if selenium_driver?
        begin
          page.driver.browser.switch_to.alert
        rescue ::Selenium::WebDriver::Error::NoSuchAlertError
          false
        end
      end
    end

    def selenium_driver?
      Capybara.current_session.driver.is_a?(Capybara::Selenium::Driver)
    end

    def set_items_per_page!(number)
      Setting.per_page_options = "#{number}, 50, 100"
    end

    def expect_current_path(query_params = nil)
      expected_path = path
      expected_path += "?#{query_params}" if query_params

      expect(page).to have_current_path expected_path, wait: 10
    end

    def click_to_sort_by(header_name)
      within ".generic-table thead" do
        click_link header_name
      end
    end

    def drag_and_drop_list(from:, to:, elements:, handler:)
      if using_cuprite?
        drag_and_drop_list_cuprite(from:, to:, elements:, handler:)
      else
        drag_and_drop_list_selenium(from:, to:, elements:, handler:)
      end
    end

    def drag_and_drop_list_cuprite(from:, to:, elements:, handler:)
      return if from == to

      list = page.all(elements, minimum: [from, to].max + 1)

      return if drag_and_drop_list_with_generic_controller_cuprite(
        source: list[from],
        target: list[to],
        insert_after: from < to
      )

      list[from].find(handler).native.drag_to(list[to].find(handler).native, delay: 0.1)
    end

    def drag_and_drop_list_with_generic_controller_cuprite(source:, target:, insert_after:)
      # Cuprite does not reliably trigger Dragula's mouse lifecycle for Primer lists,
      # so exercise the generic controller's drop callback once it is connected.
      # This is a synthetic, controller-level drop: it bypasses the drag handle,
      # canStartDrag, and Dragula's pointer lifecycle, proving persistence but not
      # the user interaction. Real drag coverage arrives with the Selenium
      # sortable-lists specs when these surfaces migrate under DREAM-789.
      result = page.evaluate_async_script(<<~JS, source.native, target.native, insert_after)
        const source = arguments[0];
        const target = arguments[1];
        const insertAfter = arguments[2];
        const done = arguments[arguments.length - 1];
        const controllerRoot = source.closest('[data-controller~="generic-drag-and-drop"]');

        if (!controllerRoot) {
          done({ success: false, fallback: true });
          return;
        }

        const getController = () => window.Stimulus?.getControllerForElementAndIdentifier(
          controllerRoot,
          'generic-drag-and-drop'
        );

        const drop = (controller) => {
          try {
            if (!source.getAttribute('data-drop-url')) {
              done({ success: false, error: 'Draggable element has no drop URL' });
              return;
            }

            const sourceContainer = source.parentElement;
            const targetContainer = target.parentElement;

            if (controller.accepts && !controller.accepts(source, targetContainer, sourceContainer, null)) {
              done({ success: false, error: 'Target does not accept draggable element' });
              return;
            }

            controller.dragOriginSource = sourceContainer;
            controller.dragOriginNextSibling = source.nextElementSibling;

            if (insertAfter) {
              target.after(source);
            } else {
              target.before(source);
            }

            Promise.resolve(controller.drop(source, source.parentElement, sourceContainer, null))
              .then(() => done({ success: true }))
              .catch((error) => done({ success: false, error: String(error?.message || error) }));
          } catch (error) {
            done({ success: false, error: String(error?.message || error) });
          }
        };

        const waitForController = (startedAt) => {
          const controller = getController();

          if (controller) {
            drop(controller);
            return;
          }

          if (performance.now() - startedAt > 5000) {
            done({ success: false, error: 'Generic drag-and-drop controller did not connect' });
            return;
          }

          setTimeout(() => waitForController(startedAt), 25);
        };

        waitForController(performance.now());
      JS

      raise result["error"] if result.is_a?(Hash) && result["error"]

      result.is_a?(Hash) && result["success"]
    end

    def drag_and_drop_list_selenium(from:, to:, elements:, handler:)
      # Wait a bit because drag & drop in selenium is easily offended
      sleep 1

      list = page.all(elements, minimum: [from, to].max + 1)
      source = list[from]
      target = list[to]

      scroll_to_element(source)
      source.hover

      # These helpers have always meant "insert before the element currently at
      # index `to`" (Dragula's insertBefore semantics), so aim at the target's
      # top quarter — closest-edge resolution then inserts above it either way.
      perform_native_drag(
        source: source.find(handler),
        target:,
        offset_y: -(target.native.rect.height / 4)
      )

      sleep 1
    end

    def path
      nil
    end

    def navigate_to_modules_menu_item(link_title)
      visit root_path

      within ".op-app-header" do
        page.find_test_selector("op-app-header--modules-menu-button").click
      end

      within "#op-app-header--modules-menu-list", visible: :all do
        click_on link_title, visible: :all
      end
    end
  end
end
