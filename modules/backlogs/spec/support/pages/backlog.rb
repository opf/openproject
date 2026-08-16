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
require "support/browsers/browser_platform"

module Pages
  class Backlog < Page
    include ::Components::Common::Filters

    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def visit!
      super

      expect(page).to have_css("turbo-frame#backlogs_container", wait: 10)
      expect(page).to have_css("#owner_backlogs_container", wait: 10)
      expect(page).to have_css("#sprint_backlogs_container", wait: 10)
      wait_for_backlogs_network_idle
    end

    def path
      project_backlogs_backlog_path(project)
    end

    def expect_inbox_blankslate
      within_backlog_inbox do
        expect(page).to have_css("h4", text: "Backlog inbox is empty")
      end
    end

    def expect_no_inbox_blankslate
      within_backlog_inbox do
        expect(page).to have_no_css("h4", text: "Backlog inbox is empty")
      end
    end

    def expect_backlog_bucket_blankslate(bucket, filtered: false)
      text = filtered ? I18n.t("backlogs.blankslate_filtered_title") : "Backlog bucket is empty"

      within_backlog_bucket(bucket) do
        expect(page).to have_selector(:heading, level: 4, text:)
      end
    end

    def expect_no_backlog_bucket_blankslate(bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_no_selector(:heading, level: 4, text: "Backlog bucket is empty")
      end
    end

    def expect_sprints_blankslate
      within_sprint_backlogs do
        expect(page).to have_css("h4", text: "No sprints present yet")
      end
    end

    def expect_sprints_blankslate_description(text)
      within_sprint_backlogs do
        expect(page).to have_text(text)
      end
    end

    def expect_no_sprints_blankslate
      within_sprint_backlogs do
        expect(page).to have_no_css("h4", text: "No sprints present yet")
      end
    end

    def expect_backlog_settings_link
      within_sprint_backlogs do
        expect(page).to have_link(
          "project settings",
          href: project_settings_backlog_sharing_path(project)
        )
      end
    end

    def expect_no_backlog_settings_link
      within_sprint_backlogs do
        expect(page).to have_no_link(
          "project settings",
          href: project_settings_backlog_sharing_path(project)
        )
      end
    end

    def expect_new_sprint_button
      within_sprint_backlogs do
        expect(page).to have_css(
          test_selector("op-sprints--new-sprint-button"),
          text: Sprint.human_model_name
        )
      end
    end

    def expect_no_new_sprint_button
      within_sprint_backlogs do
        expect(page).to have_no_css(
          test_selector("op-sprints--new-sprint-button"),
          text: Sprint.human_model_name
        )
      end
    end

    def expect_inbox_items(items:)
      within_backlog_inbox { expect_work_package_items(items:) }
    end

    def expect_no_inbox_items(items:)
      within_backlog_inbox { expect_work_package_items(items:, present: false) }
    end

    def expect_inbox_work_package_count(count)
      within_backlog_inbox do
        expect(page).to have_css(
          ".Counter",
          accessible_name: I18n.t(:label_x_items, count:)
        )
      end
    end

    def expect_inbox_show_more
      within_backlog_inbox do
        expect(page).to have_css("#inbox_project_#{project.id}_show_more")
      end
    end

    def expect_no_inbox_show_more
      wait_for_backlogs_network_idle
      within_backlog_inbox do
        expect(page).to have_no_css("#inbox_project_#{project.id}_show_more")
      end
    end

    def click_inbox_show_more
      within_backlog_inbox do
        find("#inbox_project_#{project.id}_show_more").click
      end
      wait_for_backlogs_network_idle
    end

    def expect_inbox_items_in_order(items: [])
      within_backlog_inbox do
        expect_work_packages_in_order work_packages: items
      end
    end

    def expect_bucket_items_in_order(bucket, items: [])
      within_backlog_bucket(bucket) do
        expect_work_packages_in_order work_packages: items
      end
    end

    def expect_sprint_items_in_order(sprint, items: [])
      within_sprint(sprint) do
        expect_work_packages_in_order work_packages: items
      end
    end

    def expect_work_packages_in_order(work_packages: [])
      raise ArgumentError, "work_packages should not be empty" if work_packages.empty?

      selectors = work_packages.map { |wp| work_package_selector(wp) }
      expect(page)
        .to have_css(selectors.join(" + "))
      wait_for_backlogs_network_idle
    end

    def sprint_items_in_visual_order(sprint, *work_packages)
      tops = within_sprint(sprint) do
        work_packages.index_with do |wp|
          page.evaluate_script(
            "document.querySelector('#{work_package_selector(wp)}').getBoundingClientRect().top"
          )
        end
      end

      work_packages.sort_by { |wp| tops.fetch(wp) }
    end

    def expect_sprint_names_in_order(*sprint_names)
      expect(sprint_names_in_order).to eq(sprint_names)
    end

    def expect_sprint_heading_with_goal(sprint_name, goal_text)
      within(:section, sprint_name) do
        expect(page)
          .to have_heading(sprint_name, level: 4, accessible_description: goal_text, exact: true)
      end
    end

    def expect_sprint_heading_without_goal(sprint_name)
      within(:section, sprint_name) do
        expect(page)
          .to have_heading(sprint_name, level: 4, accessible_description: "", exact: true)
      end
    end

    def expect_sprint_story_points(sprint, points)
      within(sprint_selector(sprint)) do
        expect(page).to have_css(".velocity", text: points.to_s)
      end
    end

    def expect_sprints_total_count(count)
      expect(page).to have_test_selector("op-sprints--total-counter", text: count.to_s)
    end

    def expect_no_sprints_total_counter
      expect(page).to have_no_test_selector("op-sprints--total-counter")
    end

    def expect_sprint_work_package_count(sprint, count)
      within(sprint_selector(sprint)) do
        expect(page).to have_css(
          ".Counter",
          accessible_name: I18n.t(:label_x_work_packages, count:)
        )
      end
    end

    def expect_sprint_items(sprint, items:)
      within_sprint(sprint) { expect_work_package_items(items:) }
    end

    def expect_work_package_text_in_sprint(work_package, sprint, text)
      within_sprint(sprint) do
        expect(page)
          .to have_selector(work_package_selector(work_package).to_s, text:)
      end
    end

    def expect_no_sprint_items(sprint, items:)
      within_sprint(sprint) { expect_work_package_items(items:, present: false) }
    end

    def expect_bucket_names_in_order(*bucket_names)
      expect(bucket_names_in_order).to eq(bucket_names)
    end

    def expect_bucket_items(bucket, items:)
      within_backlog_bucket(bucket) { expect_work_package_items(items:) }
    end

    def expect_backlog_bucket_work_package_count(bucket, count)
      within_backlog_bucket(bucket) do
        expect(page).to have_css(
          ".Counter",
          accessible_name: I18n.t(:label_x_work_packages, count:)
        )
      end
    end

    def expect_no_bucket_items(bucket, items:)
      within_backlog_bucket(bucket) { expect_work_package_items(items:, present: false) }
    end

    def within_sprint_menu(sprint, &)
      within_sprint(sprint) do
        button = find(:button, accessible_name: "Sprint actions")
        within(open_controlled_menu(button), &)
      end

      dismiss_menu(sprint)
    end

    def click_in_sprint_menu(sprint, item_name)
      within_sprint_menu(sprint) do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def within_backlog_bucket_menu(bucket, &)
      within_backlog_bucket(bucket) do
        button = find(:button, accessible_name: "Backlog bucket actions")
        within(open_controlled_menu(button), &)
      end
      dismiss_menu(bucket)
    end

    def click_in_bucket_menu(bucket, item_name)
      within_backlog_bucket_menu(bucket) do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def within_inbox_menu(&)
      within_backlog_inbox do
        button = find(:button, accessible_name: "Inbox actions")
        within(open_controlled_menu(button), &)
      end
    end

    def click_in_inbox_menu(item_name)
      within_inbox_menu do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def within_work_package_menu(work_package, &)
      within_work_package(work_package) do
        button = find(:button, accessible_name: "Work package actions")
        within(open_controlled_menu(button), &)
      end

      dismiss_menu(work_package)
    end

    # Opens one card's menu through the same four user entry points supported
    # by Backlogs. Keeping the native key/pointer synthesis and deferred-menu
    # wait here lets feature specs talk in product language and prevents each
    # caller from encoding Primer's overlay structure.
    def open_card_menu(work_package, via:)
      case via
      when :more
        within_work_package(work_package) do
          find(:button, accessible_name: "Work package actions").click
        end
      when :right_click
        right_click_work_package_card(work_package)
      when :context_menu_key
        # Selenium's W3C key table does not expose the dedicated Context Menu
        # key. Dispatch its browser-level KeyboardEvent against a focused card
        # so this path still differs from Shift+F10 at the controller boundary.
        work_package_card(work_package).execute_script(<<~JS)
          this.focus({ focusVisible: true, preventScroll: true });
          this.dispatchEvent(new KeyboardEvent('keydown', {
            key: 'ContextMenu',
            bubbles: true,
            cancelable: true
          }));
        JS
      when :shift_f10
        send_work_package_card_keys(work_package, %i[shift f10])
      else
        raise ArgumentError, "Unknown card-menu entry point: #{via.inspect}"
      end

      work_package_action_menu(work_package)
    end

    def activate_singular_menu_action(invoker:, action:, via: :more)
      open_card_menu(invoker, via:).find(:menuitem, text: action, exact_text: true).click
    end

    def activate_batch_menu_action(invoker:, action:, via: :more, wait: true)
      menu = open_card_menu(invoker, via:)

      if %w[Move\ to\ top Move\ up Move\ down Move\ to\ bottom].include?(action)
        wait_for_backlogs_turbo_stream(wait:) do
          open_move_submenu(menu).find(:menuitem, text: action, exact_text: true, visible: :all).click
        end
      else
        menu.find(:menuitem, text: action, exact_text: true).click
      end
    end

    def expect_card_menu_anchor(work_package, via:)
      if via == :right_click
        expect_menu_anchored_contextually(work_package)
      else
        expect_menu_anchored_at_button(work_package)
      end
    end

    def expect_card_menu_loaded(work_package)
      expect(page.find(menu_owner_overlay_selector(work_package)))
        .to have_no_css("include-fragment[src]", visible: :all)
    end

    def dismiss_card_menu(work_package, via:)
      send_keys_to_focused_element(:escape)
      expect_no_work_package_context_menu(work_package)

      if via == :more
        within_work_package(work_package) do
          expect(page).to have_button(accessible_name: "Work package actions", focused: true)
        end
      else
        expect_work_package_card_focused(work_package)
      end
    end

    def light_dismiss_card_menu(work_package)
      find(:heading, I18n.t(:label_backlog_and_sprints), level: 2).click
      expect_no_work_package_context_menu(work_package)
    end

    def expect_open_menu_actions(invoker:, present:, absent:)
      menu = work_package_action_menu(invoker)
      present.each do |label|
        expect(menu).to have_selector(:menuitem, text: label, exact_text: true)
      end
      absent.each do |label|
        expect(menu).to have_no_selector(:menuitem, text: label, exact_text: true)
      end
    end

    def expect_fixed_action_menu(invoker:)
      menu = work_package_action_menu(invoker)

      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"))
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_fullscreen"))
      expect(menu).to have_no_selector(:menuitem, text: "Move to position")
    end

    def work_package_card(work_package)
      find(work_package_card_selector(work_package))
    end

    # The row wrapper, not the card: it carries the item id and, once
    # selected, `data-batch-selected`. The description lives on the card,
    # which is the focus host, so it is checked through {#work_package_card}.
    def work_package_row(work_package)
      find(work_package_selector(work_package))
    end

    # The row's resolved background colour. Read it twice around one isolated
    # change, never across two rows and never around a gesture that also
    # focuses or navigates: the background depends on focus and `aria-current`
    # too, so anything else makes the difference unattributable.
    def row_background_color(work_package)
      work_package_row(work_package).style("background-color").fetch("background-color")
    end

    # Moves focus onto the card without a pointer and without any event a
    # Backlogs controller listens for. Establishes focus before a
    # background-colour control read, so a later keyboard gesture on the same
    # card does not change it a second time.
    def focus_work_package_card(work_package)
      work_package_card(work_package).execute_script(
        "this.focus({ focusVisible: true, preventScroll: true })"
      )
    end

    # Right-clicks near the card's top-left corner: the offset keeps the
    # pointer off the subject link and the actions menu button, both of which
    # keep their native context menu on purpose.
    def right_click_work_package_card(work_package)
      work_package_card(work_package).right_click(x: 6, y: 6, offset: :position)
    end

    # The card's own actions button, right-clicked. It is the one interactive
    # descendant that does not keep the browser's context menu: the control
    # whose whole job is to open this menu opens it here too.
    def right_click_work_package_menu_button(work_package)
      within_work_package(work_package) do
        find(:button, accessible_name: "Work package actions").right_click
      end
    end

    # Sends keys to whatever currently holds focus. Capybara's
    # `element.send_keys` focuses its receiver first, which would destroy the
    # very focus state a menu-dismissal assertion is trying to observe.
    def send_keys_to_focused_element(*keys)
      page.driver.browser.action.send_keys(*keys).perform
    end

    def send_work_package_card_keys(work_package, keys)
      work_package_card(work_package).send_keys(*keys)
    end

    def within_work_package_context_menu(work_package, &)
      within(menu_owner_overlay_selector(work_package)) do
        yield page.find(:menu)
      end
    end

    def expect_no_work_package_context_menu(work_package)
      expect(page)
        .to have_no_css(menu_owner_overlay_selector(work_package), visible: :visible)
    end

    def expect_work_package_card_focused(work_package)
      expect(page)
        .to have_css(work_package_card_selector(work_package), focused: true)
    end

    # The *computed* accessible description, not the raw `aria-describedby`
    # token: an id that resolves to nothing, or an element the browser
    # declines to traverse into, leaves this empty while the attribute reads
    # exactly as intended.
    def expect_work_package_card_described_as(work_package, description)
      expect(page)
        .to have_css(work_package_card_selector(work_package), accessible_description: description)
    end

    def expect_work_package_card_not_described(work_package)
      expect(page)
        .to have_css(work_package_card_selector(work_package), accessible_description: "")
    end

    # The presenter takes the overlay's `anchor` idref away for the duration of
    # a contextual invocation, so its absence is what distinguishes a menu
    # opened at the pointer (or on the card) from one opened at the More
    # button, without measuring pixels.
    # `page.document` rather than `page`: both are called while the menu is
    # open, and the More button case runs inside a `within` scoped to the menu
    # itself, where a plain `page` query would search the menu's descendants.
    def expect_menu_anchored_contextually(work_package)
      expect(page.document)
        .to have_css("#{menu_owner_overlay_selector(work_package)}:not([anchor])")
    end

    def expect_menu_anchored_at_button(work_package)
      expect(page.document)
        .to have_css("#{menu_owner_overlay_selector(work_package)}[anchor]")
    end

    # Where the open menu sits relative to its card, rounded to whole pixels.
    # A menu anchored on the card keeps this constant however the page scrolls;
    # one pinned to a point in the viewport drifts by the scroll distance.
    def work_package_menu_offset_from_card(work_package)
      offset = page.evaluate_script(<<~JS)
        (() => {
          const overlay = document.querySelector('#{menu_owner_overlay_selector(work_package)}');
          const card = document.querySelector('#{work_package_card_selector(work_package)}');

          if (!overlay || !card) { return null; }

          const overlayRect = overlay.getBoundingClientRect();
          const cardRect = card.getBoundingClientRect();

          return {
            top: Math.round(overlayRect.top - cardRect.top),
            left: Math.round(overlayRect.left - cardRect.left)
          };
        })()
      JS

      raise "No open menu for work package #{work_package.id}" if offset.nil?

      offset.symbolize_keys
    end

    # Scrolls whatever actually scrolls this card — the window on a short page,
    # an overflowing ancestor otherwise — and answers how far the card moved in
    # viewport space, direction ignored, so a caller can tell a real scroll from
    # a silent no-op on a page that never overflowed.
    def scroll_past_work_package_card(work_package, distance:)
      page.evaluate_script(<<~JS)
        (() => {
          const card = document.querySelector('#{work_package_card_selector(work_package)}');
          const before = card.getBoundingClientRect().top;

          let scroller = document.scrollingElement;

          for (let node = card.parentElement; node; node = node.parentElement) {
            const overflowY = getComputedStyle(node).overflowY;

            if (/(auto|scroll)/.test(overflowY) && node.scrollHeight > node.clientHeight) {
              scroller = node;
              break;
            }
          }

          // Whichever direction has room: opening the menu scrolls the card
          // into view, which may already have the scroller at one end, and
          // scrolling further that way is a silent no-op.
          const room = scroller.scrollHeight - scroller.clientHeight;
          const target = scroller.scrollTop + #{distance} <= room
            ? scroller.scrollTop + #{distance}
            : scroller.scrollTop - #{distance};

          // Explicitly instant: a scroll container inheriting
          // `scroll-behavior: smooth` would animate the change, and the rect
          // read below would still see the old position.
          scroller.scrollTo({ top: Math.max(0, target), behavior: 'instant' });

          return Math.abs(Math.round(before - card.getBoundingClientRect().top));
        })()
      JS
    end

    def click_in_work_package_menu(work_package, item_name, wait: true)
      within_work_package_menu(work_package) do |submenu|
        wait_for_turbo_stream(wait:) do
          submenu.find(:menuitem, text: item_name).click
        end
      end
    end

    def within_work_package_move_submenu(work_package, &)
      within_work_package_menu(work_package) do |menu|
        yield open_move_submenu(menu)
      end
    end

    # The move submenu items (Move up/down/to top/to bottom) reorder the row
    # client-side and persist via a background fetch; a same-list move no
    # longer reloads the `backlogs_container` frame (see
    # Backlogs::WorkPackagesController#optimistic_same_list_move?). Wait for
    # the turbo-stream response instead, which still fires either way.
    def click_in_work_package_move_submenu(work_package, item_name, wait: true, frame_reload: false)
      within_work_package_move_submenu(work_package) do |submenu|
        wait_for_backlogs_turbo_stream(wait:, frame_reload:) do
          submenu.find(:menuitem, text: item_name, visible: :all).click
        end
      end
    end

    alias_method :click_in_inbox_move_menu, :click_in_work_package_move_submenu
    alias_method :click_in_sprint_story_move_menu, :click_in_work_package_move_submenu

    def expect_no_inbox_menu
      within_backlog_inbox do
        expect(page).to have_no_button(accessible_name: "Inbox actions")
      end
    end

    # Arms a reload probe for the Backlogs container before a move action.
    #
    # @see WaitHelpers#install_turbo_frame_reload_probe
    def install_backlogs_container_reload_probe
      install_turbo_frame_reload_probe("backlogs_container")
    end

    # Confirms that the Backlogs container did not reload after the move.
    #
    # @see WaitHelpers#expect_turbo_frame_not_reloaded
    def expect_backlogs_container_not_reloaded(wait: Capybara.default_max_wait_time)
      expect_turbo_frame_not_reloaded("backlogs_container", wait:)
    end

    def expect_no_backlog_bucket_menu(bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_no_button(accessible_name: "Backlog bucket actions")
      end
    end

    def expect_no_sprint_menu(sprint)
      within_sprint(sprint) do
        expect(page).to have_no_button(accessible_name: "Sprint actions")
      end
    end

    def expect_no_sprint_menu_item(sprint, item_name)
      within_sprint_menu(sprint) do |_menu|
        expect(page)
          .to have_no_selector(:menuitem, text: item_name)
      end
    end

    # Opening details morphs the row into its "current work package" state, so
    # a reference captured beforehand can go stale mid-morph. `retry_block`
    # spaces the attempts out and finds the button, menu and view fresh on
    # each one.
    def open_work_package_details(work_package)
      retry_block(
        args: {
          tries: 3,
          on: [
            Capybara::Cuprite::ObsoleteNode,
            Selenium::WebDriver::Error::StaleElementReferenceError
          ]
        }
      ) do
        within_work_package(work_package) do
          button = find(:button, accessible_name: "Work package actions")
          open_controlled_menu(button).find(:menuitem, text: I18n.t(:"js.button_open_details")).click
        end
        expect_details_view(work_package)
      end
    end

    def expect_details_view(work_package)
      details_view = Pages::PrimerizedSplitWorkPackage.new(work_package)
      details_view.expect_tab :overview
      details_view.expect_subject

      expect(page).to have_current_path project_backlogs_backlog_details_path(work_package.project, work_package),
                                        ignore_query: true
      wait_for_backlogs_network_idle

      details_view
    end

    def expect_create_work_package_dialog
      expect(page).to have_css("#create-work-package-dialog")
    end

    def expect_sprint(sprint)
      expect(page).to have_css(sprint_selector(sprint))
    end

    def expect_no_sprint(sprint)
      expect(page).to have_no_css(sprint_selector(sprint))
    end

    def open_create_bucket_dialog
      within_owner_backlogs do
        click_on accessible_name: "New backlog bucket"
      end
    end

    def expect_new_backlog_bucket_button
      within_owner_backlogs do
        expect(page).to have_link(BacklogBucket.human_model_name, exact: true)
      end
    end

    def expect_no_new_backlog_bucket_button
      within_owner_backlogs do
        expect(page).to have_no_link(BacklogBucket.human_model_name, exact: true)
      end
    end

    def expect_backlog_bucket(bucket)
      expect(page).to have_css(bucket_selector(bucket))
    end

    def expect_no_backlog_bucket(bucket)
      expect(page).to have_no_css(bucket_selector(bucket))
    end

    def expect_bucket_dialog
      expect(page).to have_dialog(I18n.t(:label_backlog_bucket_new))
    end

    def expect_and_confirm_backlog_bucket_delete_modal
      expect(page).to have_selector backlog_bucket_destroy_modal_selector

      within backlog_bucket_destroy_modal_selector do
        click_button "Delete"
      end
    end

    # Every row carries the item id whether or not the user may move it, so
    # the id no longer distinguishes an orderable row. `draggable` and
    # `mobility` are set independently and read by separate consumers, so
    # both are checked.
    def expect_work_package_draggable(work_package)
      selector = work_package_selector(work_package)
      expect(page).to have_css("#{selector}[draggable='true']")
      expect(page).to have_no_css("#{selector}[data-sortable-lists--item-mobility-value='fixed']")
    end

    # Both assertions are negative, so they also pass against a page that
    # never rendered the card — including the rack-session page a racing
    # Selenium login can strand the browser on. Asserting the row exists first
    # is blocked on fix/selenium-rack-session-login-flake.
    def expect_work_package_not_draggable(work_package)
      selector = work_package_selector(work_package)
      expect(page).to have_no_css("#{selector}[draggable='true']")
      expect(page).to have_no_css("#{selector}[data-sortable-lists--item-mobility-value='free']")
    end

    # A read-only card keeps its drag but is confined to its own list: it can
    # be reordered in place, while every other container refuses it. The
    # confined value is what the foreign drop targets read.
    def expect_work_package_confined(work_package)
      expect(page)
        .to have_css("#{work_package_selector(work_package)}" \
                     "[data-sortable-lists--item-mobility-value='confined']")
      expect(page)
        .to have_css("#{work_package_selector(work_package)}[draggable]")
    end

    # The lock on the status badge is what tells the user why the cross-container
    # moves are gone. Without it a read-only card is indistinguishable from a
    # movable one until they try to move it and nothing happens.
    def expect_work_package_locked(work_package)
      within_work_package(work_package) do
        expect(page).to have_css(readonly_lock_selector)
      end
    end

    def expect_work_package_not_locked(work_package)
      within_work_package(work_package) do
        expect(page).to have_no_css(readonly_lock_selector)
      end
    end

    # An unmodified click: narrows the batch to this card and opens its
    # details pane. Offset near the top-left corner because the card's centre
    # sits on the subject link or the actions menu button, both of which the
    # selection root ignores as interactive descendants.
    def select_card(work_package)
      work_package_card(work_package).click(x: 6, y: 6, offset: :position)
    end

    # Toggles membership without navigating, and re-bases the anchor to this
    # card even when the toggle deselects it.
    def toggle_card(work_package)
      modified_click(work_package, multi_select_modifier)
    end

    def multi_select_modifier
      BrowserPlatform.multi_select_modifier(page)
    end

    # Selects the contiguous range from the anchor to this card. Repeated
    # calls resize one range rather than walking it.
    def extend_selection_to(work_package)
      modified_click(work_package, :shift)
    end

    # Asserted directly because an empty batch proves nothing: a root that
    # opted in and refused every gesture looks identical from outside, yet
    # differs in whether the browser still gets the keystroke.
    def expect_batch_selection_disabled
      expect(page).to have_css("[data-controller~='sortable-lists'][data-sortable-lists-selection-enabled-value='false']",
                               visible: :all)
    end

    # Live batch membership, in document order.
    def selected_card_ids
      all("[data-batch-selected]").pluck("data-sortable-lists--item-id-value")
    end

    def select_cards(*work_packages)
      work_packages.each { |work_package| toggle_card(work_package) }
      expect(page).to have_css("[data-batch-selected]", count: work_packages.size)
    end

    # Settles on the range's own endpoints rather than a card count, which
    # only the caller knows for a span wider than a pair.
    def select_contiguous_cards(first, last)
      toggle_card(first)
      extend_selection_to(last)
      expect(page).to have_css("#{work_package_selector(first)}[data-batch-selected]")
      expect(page).to have_css("#{work_package_selector(last)}[data-batch-selected]")
    end

    def expect_selected_cards_in_order(*work_packages)
      expect(page).to have_css("[data-batch-selected]", count: work_packages.size)
      expect(selected_card_ids).to eq(work_packages.map { |work_package| work_package.id.to_s })
    end

    def expect_no_selected_cards
      expect(page).to have_no_css("[data-batch-selected]")
      expect(selected_card_ids).to be_empty
    end

    def move_selected_cards(invoker:, action:, wait: false)
      click_in_work_package_move_submenu(invoker, action, wait:)
    end

    def expect_move_to_position_available(work_package, action: nil)
      within_work_package_move_submenu(work_package) do |submenu|
        next unless action

        expect(submenu).to have_selector(:menuitem, text: action, exact_text: true)
      end
    end

    def expect_move_to_position_unavailable(work_package, action: nil)
      if action
        within_work_package_move_submenu(work_package) do |submenu|
          expect(submenu).to have_no_selector(:menuitem, text: action, exact_text: true)
        end
      else
        expect_no_work_package_action(work_package, "Move to position")
      end
    end

    def clear_card_selection(work_package)
      work_package_card(work_package).send_keys(:escape)
      expect_no_selected_cards
    end

    def expect_work_package_action(work_package, action_label)
      within_work_package_menu(work_package) do |menu|
        expect(menu).to have_selector(:menuitem, text: action_label, exact_text: true)
      end
    end

    def expect_no_work_package_action(work_package, action_label)
      within_work_package_menu(work_package) do |menu|
        expect(menu).to have_no_selector(:menuitem, text: action_label, exact_text: true)
      end
    end

    def expect_destination_actions(work_package, present:, absent:)
      within_work_package_menu(work_package) do |menu|
        present.each do |label|
          expect(menu).to have_selector(:menuitem, text: label, exact_text: true)
        end
        absent.each do |label|
          expect(menu).to have_no_selector(:menuitem, text: label, exact_text: true)
        end
      end
    end

    def open_destination_dialog(work_package, action_label, dialog_title: action_label)
      click_in_work_package_menu(work_package, action_label, wait: false)
      expect(page).to have_selector(:modal, text: dialog_title)
    end

    def invoke_destination_action_after_menu_load(work_package, action_label, &before_click)
      within_work_package_menu(work_package) do |menu|
        item = menu.find(:menuitem, text: action_label, exact_text: true)
        before_click&.call
        wait_for_backlogs_turbo_stream do
          item.click
        end
      end
    end

    def move_to_backlog_inbox(work_package)
      within_work_package_menu(work_package) do |menu|
        wait_for_backlogs_turbo_stream(frame_reload: true) do
          menu.find(:menuitem, text: "Move to backlog inbox", exact_text: true).click
        end
      end
    end

    def expect_destination_dialog(dialog_title, work_packages:)
      within_modal dialog_title do
        work_packages.each { |work_package| expect(page).to have_text(work_package.subject) }
        expect(all("input[name='ids[]']", visible: :all).map(&:value))
          .to eq(work_packages.map { |work_package| work_package.id.to_s })
      end
    end

    def expect_destination_dialog_options(dialog_title, field_label:, options:)
      within_modal dialog_title do
        select = find(:select, field_label)
        expect(select.all(:option).map(&:text)).to eq(options)
      end
    end

    def submit_destination_dialog(dialog_title, field_label:, option:, frame_reload: true)
      within_modal dialog_title do
        select option, from: field_label
        wait_for_backlogs_turbo_stream(frame_reload:) { click_button I18n.t(:button_move) }
      end
    end

    def cancel_destination_dialog(dialog_title)
      within_modal dialog_title do
        click_button I18n.t(:button_cancel)
      end
      expect(page).to have_no_selector(:modal, text: dialog_title)
    end

    def expect_no_destination_dialog
      expect(page).to have_no_selector(:modal)
    end

    def expect_move_error(reason)
      expect_flash(
        type: :error,
        message: I18n.t(:notice_unsuccessful_update_with_reason, reason:)
      )
    end

    def expect_polite_announcement(message)
      wait_for do
        page.evaluate_script("document.querySelector('live-region')?.getMessage('polite')")
      end.to eq(message)
    end

    def expect_persisted_sprint_order(sprint, *work_packages)
      wait_for { sprint.work_packages_for(project).pluck(:id) }
        .to eq(work_packages.map(&:id))
    end

    def expect_persisted_bucket_order(bucket, *work_packages)
      wait_for { WorkPackage.where(backlog_bucket: bucket).order_by_position.pluck(:id) }
        .to eq(work_packages.map(&:id))
    end

    def expect_persisted_inbox_order(*work_packages)
      wait_for do
        WorkPackage.where(project:, sprint_id: nil, backlog_bucket_id: nil).order_by_position.pluck(:id)
      end.to eq(work_packages.map(&:id))
    end

    # The shared description every selected card's `aria-describedby` points
    # at. Rendered once, permanently `hidden` — screen readers still reach it
    # through the reference despite that — so `visible: :all` is required.
    def expect_selection_description_present
      expect(page).to have_css("##{Backlogs::SelectionDescriptionComponent::DESCRIPTION_ID}",
                               visible: :all, count: 1)
    end

    def pick_up_and_release_work_package(work_package)
      # A mid-drag list refresh can detach the grabbed row, so retry a bounded
      # number of times on a stale node. retry_block no-ops under
      # RSPEC_RETRY_RETRY_COUNT=0, so single/local runs fail fast and surface the
      # underlying fault instead of spinning on it. See the follow-up to make this
      # helper robust without any retry.
      retry_block(
        args: {
          tries: 3,
          on: [
            Capybara::Cuprite::ObsoleteNode,
            Selenium::WebDriver::Error::StaleElementReferenceError
          ]
        }
      ) do
        moved_element = find(work_package_selector(work_package))
        install_backlogs_move_request_probe
        begin
          pick_up_and_release_backlogs_item(moved_element)
        ensure
          stop_backlogs_move_request_probe
        end
      end

      # The observable outcomes of releasing in place (no move request,
      # unchanged order) also hold when the drag never engages, so assert the
      # drop actually reached the controller — over the list, without an item
      # target — to keep callers from passing vacuously.
      expect_backlogs_drop_handled_without_item_target
    end

    def apply_sprint_filter(*sprints)
      within_sprint_backlogs do
        find_test_selector("sprint_filter_button").click
      end
      within_dialog "Select items" do
        sprints.each { |sprint| click_on sprint.name, role: "option" }
        click_on "Apply"
      end
      wait_for_network_idle
    end

    def apply_bucket_filter(*buckets, include_inbox: false)
      within_owner_backlogs do
        find_test_selector("backlog_bucket_filter_button").click
      end
      within_dialog "Select items" do
        buckets.each { |bucket| click_on bucket.name, role: "option" }
        click_on(I18n.t(:label_inbox), role: "option") if include_inbox
        click_on "Apply"
      end
      wait_for_network_idle
    end

    def apply_subject_filter(text)
      fill_in "Search work packages by subject", with: text
      wait_for_network_idle
    end

    def clear_subject_filter
      find_by_id("backlog-filters-form-clear-button").click
      wait_for_network_idle
    end

    def apply_status_filter(status, operator: "is (OR)")
      open_filters
      set_filter("status_id", "Status", operator, [status.name])
      wait_for_network_idle
    end

    def expect_inbox
      expect(page).to have_test_selector("backlog-inbox")
    end

    def expect_no_inbox
      expect(page).to have_no_test_selector("backlog-inbox")
    end

    def within_filter_panel(type, &)
      within_filter_container(type) do
        find_test_selector(filter_button_label(type)).click
      end
      within_dialog("Select items", &)
    end

    def clear_filter(type)
      within_filter_panel(type) { click_on I18n.t(:button_clear) }
      wait_for_network_idle
    end

    def expect_filter_count(type, count)
      within_filter_container(type) do
        within_test_selector(filter_button_label(type)) do
          expect(page).to have_css(".Counter", text: count)
        end
      end
    end

    def expect_no_backlogs_move_request
      move_requests = page.evaluate_script("window.__opBacklogsMoveRequestProbe?.requests ?? []")

      expect(move_requests).to be_empty
    ensure
      stop_backlogs_move_request_probe
    end

    def expect_no_filter_count(type)
      within_filter_container(type) do
        within_test_selector(filter_button_label(type)) do
          expect(page).to have_no_css(".Counter")
        end
      end
    end

    def drag_work_package(moved, before: nil, after: nil, into: nil)
      unless [before, after, into].compact.one?
        raise ArgumentError, "You must specify exactly one of before, after or into"
      end

      moved_element = find(work_package_selector(moved))
      target_element, edge =
        if before
          [find(work_package_selector(before)), :top]
        elsif after
          [find(work_package_selector(after)), :bottom]
        else
          [find(sprint_selector(into)), nil]
        end

      wait_for_backlogs_turbo_stream(frame_reload: cross_list_drag?(moved, before:, after:, into:)) do
        drag_backlogs_item(source: moved_element, target: target_element, edge:)
      end
    rescue Capybara::Cuprite::ObsoleteNode, Selenium::WebDriver::Error::StaleElementReferenceError
      retry
    end

    # Drags expecting a rejection: drag_work_package waits on the frame
    # reload a successful cross-list move causes, while a rejected move only
    # streams an error flash, so this settles on the stream render instead.
    def drag_work_package_expecting_failure(moved, after:)
      # See pick_up_and_release_work_package for the retry rationale.
      retry_block(
        args: {
          tries: 3,
          on: [
            Capybara::Cuprite::ObsoleteNode,
            Selenium::WebDriver::Error::StaleElementReferenceError
          ]
        }
      ) do
        moved_element = find(work_package_selector(moved))
        target_element = find(work_package_selector(after))

        wait_for_backlogs_turbo_stream(frame_reload: false) do
          drag_backlogs_item(source: moved_element, target: target_element, edge: :bottom)
        end
      end
    end

    # Drags a confined card over another sprint's list body and releases it
    # there. The release must resolve to nothing: no drop indicator over the
    # target, no row of it accepting, no move request. The card's unchanged
    # position is the caller's assertion.
    def drag_work_package_without_move(moved, into:)
      # See pick_up_and_release_work_package for the retry rationale.
      retry_block(
        args: {
          tries: 3,
          on: [
            Capybara::Cuprite::ObsoleteNode,
            Selenium::WebDriver::Error::StaleElementReferenceError
          ]
        }
      ) do
        moved_element = find(work_package_selector(moved))
        target_element = find(list_body_selector(sprint_selector(into)))
        install_backlogs_move_request_probe
        begin
          drag_backlogs_item(source: moved_element, target: target_element, dwell: true)
        ensure
          stop_backlogs_move_request_probe
        end
      end

      expect_backlogs_drag_refused
      expect_no_backlogs_move_request
    end

    # The refusal must be observable, or the assertions above would also pass
    # for a drag that never engaged. The drop has to reach the controller —
    # the refused container stays an accepted drop target so the drag keeps
    # the standard cursor, so it may appear in the drop's target list, but no
    # row of it may — and the last container feedback the drag painted must be
    # a refusal (the muted danger outline) rather than an active outline.
    # Container state is read across the whole event stream, not from the
    # final dragover: the drop engine paints on an animation frame, so a
    # refusal can land on a later dragenter than the last dragover. Earlier
    # feedback may legitimately be active while the pointer is still crossing
    # a list that accepts the drag for real.
    def expect_backlogs_drag_refused
      refusal = page.evaluate_script(<<~JS)
        (() => {
          const state = window.__opBacklogsDndProbeState;
          const call = state?.handleDropCalls?.at(-1);
          const events = state?.events ?? [];
          const lastDragover = events.filter((event) => event.type === 'dragover').at(-1);
          const lastContainers = events
            .map((event) => event.dropContainers)
            .filter((containers) => containers.length > 0)
            .at(-1);

          return {
            handled: Boolean(call),
            dropTargetTypes: call?.dropTargets?.map((target) => target.data?.entries?.type) ?? [],
            observedDragover: Boolean(lastDragover),
            dropPositions: lastDragover?.dropPositions ?? null,
            dropContainers: lastContainers ?? null
          };
        })()
      JS

      expect(refusal.fetch("handled")).to be(true)
      expect(refusal.fetch("dropTargetTypes")).not_to include("work_package")
      expect(refusal.fetch("observedDragover")).to be(true)
      expect(refusal.fetch("dropPositions")).to be_empty
      expect(refusal.fetch("dropContainers")).to eq(["refused"])
    end

    def drag_work_package_to_backlog_inbox(work_package)
      moved_element = find(work_package_selector(work_package))
      inbox = find(backlog_inbox_selector)
      target_item = inbox.all("[data-sortable-lists--item-id-value]", minimum: 0).last
      target_element = target_item || inbox.find("[data-empty-list-item]")

      wait_for_backlogs_turbo_stream(frame_reload: true) do
        drag_backlogs_item(source: moved_element, target: target_element, edge: target_item ? :bottom : nil)
      end
      wait_for { work_package.reload.backlog_bucket_id }.to be_nil
      wait_for { work_package.reload.sprint_id }.to be_nil
    rescue Capybara::Cuprite::ObsoleteNode, Selenium::WebDriver::Error::StaleElementReferenceError
      retry
    end

    def drag_work_package_to_backlog_bucket(work_package, bucket)
      moved_element = find(work_package_selector(work_package))
      target_element = find(list_body_selector(bucket_selector(bucket)))

      wait_for_backlogs_turbo_stream(frame_reload: true) do
        drag_backlogs_item(source: moved_element, target: target_element)
      end
      wait_for { work_package.reload.backlog_bucket_id }.to eq(bucket.id)
    rescue Capybara::Cuprite::ObsoleteNode, Selenium::WebDriver::Error::StaleElementReferenceError
      retry
    end

    def drag_work_package_to_sprint(work_package, sprint)
      moved_element = find(work_package_selector(work_package))
      target_element = find(list_body_selector(sprint_selector(sprint)))
      wait_for_backlogs_turbo_stream(frame_reload: true) do
        drag_backlogs_item(source: moved_element, target: target_element)
      end
      wait_for { work_package.reload.sprint_id }.to eq(sprint.id)
    rescue Capybara::Cuprite::ObsoleteNode, Selenium::WebDriver::Error::StaleElementReferenceError
      retry
    end

    def open_create_sprint_dialog
      find_test_selector("op-sprints--new-sprint-button", text: "Sprint").click
    end

    def expect_sprint_dialog
      expect(page).to have_css("#sprint-dialog")
    end

    def click_start_sprint_button(sprint)
      within_sprint(sprint) do
        click_on("Start")
      end
    end

    def click_complete_sprint_button(sprint)
      within_sprint(sprint) do
        click_on("Complete")
      end
    end

    def click_to_complete_sprint(sprint)
      click_complete_sprint_button(sprint)
    end

    def expect_sprint_completing_modal
      expect(page).to have_css sprint_complete_modal_selector
    end

    def expect_sprints_to_choose_for_moving_unfinished_work_packages_to(*sprints)
      within sprint_complete_modal_selector do
        expect(page).to have_select("Select sprint", options: sprints.map(&:name))
      end
    end

    def choose_to_move_unfinished_work_packages_to_sprint(sprint_name)
      within sprint_complete_modal_selector do
        choose I18n.t("backlogs.finish_sprint_dialog_component.actions.move_to_sprint")
        select sprint_name, from: "Select sprint"

        click_button "Complete sprint"
      end
    end

    def choose_to_move_unfinished_work_packages_to_top_of_backlog
      within sprint_complete_modal_selector do
        choose I18n.t("backlogs.finish_sprint_dialog_component.actions.move_to_top_of_backlog")

        click_button "Complete sprint"
      end
    end

    def choose_to_move_unfinished_work_packages_to_bottom_of_backlog
      within sprint_complete_modal_selector do
        choose I18n.t("backlogs.finish_sprint_dialog_component.actions.move_to_bottom_of_backlog")

        click_button "Complete sprint"
      end
    end

    def expect_and_dismiss_error(message)
      expect(page).to have_text message

      click_on "Cancel"
    end

    def within_work_package(work_package, &)
      within(work_package_selector(work_package), &)
    end

    private

    # Node::Element#click takes the held key and positional options, so no
    # action chain is needed. The offset avoids the card's centre, where the
    # subject link or actions menu button sits: the selection root ignores a
    # gesture starting on either, and which one lands dead centre varies with
    # the card's content.
    def modified_click(work_package, key)
      work_package_card(work_package).click(key, x: 6, y: 6, offset: :position)
    end

    def within_sprint(sprint, &)
      within(sprint_selector(sprint), &)
    end

    def within_backlog_bucket(bucket, &)
      within(bucket_selector(bucket), &)
    end

    def within_backlog_inbox(&)
      within(backlog_inbox_selector, &)
    end

    def within_owner_backlogs(&)
      within("#owner_backlogs_container", &)
    end

    def within_sprint_backlogs(&)
      within("#sprint_backlogs_container", &)
    end

    def within_filter_container(type, &)
      type == :sprint ? within_sprint_backlogs(&) : within_owner_backlogs(&)
    end

    def filter_button_label(type)
      type == :sprint ? "sprint_filter_button" : "backlog_bucket_filter_button"
    end

    def sprint_selector(sprint)
      test_selector("sprint-#{sprint.id}")
    end

    def bucket_selector(bucket)
      raise ArgumentError, "bucket must be persisted" unless bucket.persisted?

      test_selector("backlog-bucket-#{bucket.id}")
    end

    def backlog_inbox_selector
      test_selector("backlog-inbox")
    end

    def list_body_selector(container_selector)
      "#{container_selector} > ul"
    end

    def work_package_selector(work_package)
      test_selector("work-package-#{work_package.id}")
    end

    def expect_work_package_items(items:, present: true)
      Array(items).each do |wp|
        if present
          expect(page).to have_css(work_package_selector(wp))
        else
          expect(page).to have_no_css(work_package_selector(wp))
        end
      end
    end

    # `.op-work-package-card` is the class the card component itself owns;
    # `.Box-card` is a Primer modifier it happens to compose today, so it is
    # not something a Backlogs page object should be matching on.
    def work_package_card_selector(work_package)
      "#{work_package_selector(work_package)} .op-work-package-card"
    end

    # Generic over every menu owner `dismiss_menu` handles (sprint, bucket,
    # work package): `dom_target` needs nothing work-package-specific, so this
    # is the one place that convention lives.
    def menu_owner_overlay_selector(menu_owner)
      "##{ActionView::RecordIdentifier.dom_target(menu_owner, :menu)}-overlay"
    end

    def work_package_action_menu(work_package)
      page.find(menu_owner_overlay_selector(work_package)).find(:menu)
    end

    # Located by the lock's accessible name so the expectation fails if the
    # icon ever loses the text that explains it.
    def readonly_lock_selector
      "[aria-label='#{Status.human_attribute_name(:is_readonly)}']"
    end

    def drag_backlogs_item(source:, target:, edge: nil, dwell: false)
      selenium_drag_backlogs_item(source:, target:, edge:, dwell:)
    end

    def pick_up_and_release_backlogs_item(source)
      install_backlogs_dnd_probe(source:, target: source, edge: nil)

      scroll_backlogs_source_into_view(source)

      page
        .driver
        .browser
        .action
        .move_to(source.native)
        .click_and_hold
        .pause(duration: 0.1)
        .move_by(0, 8)
        .pause(duration: 0.1)
        .release
        .perform

      # Assert Pragmatic DnD tore down its own honey-pot overlay before we force
      # a cleanup, so a regression that leaves the overlay stuck is caught here
      # instead of being masked by the JS removal below.
      expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
      clear_pragmatic_dnd_honey_pot
    end

    def expect_backlogs_drop_handled_without_item_target
      drop_summary = page.evaluate_script(<<~JS)
        (() => {
          const call = window.__opBacklogsDndProbeState?.handleDropCalls?.at(-1);

          return {
            handled: Boolean(call),
            dropTargetTypes: call?.dropTargets?.map((target) => target.data?.entries?.type) ?? []
          };
        })()
      JS

      expect(drop_summary.fetch("handled")).to be(true)
      expect(drop_summary.fetch("dropTargetTypes")).to include("backlog_bucket")
      expect(drop_summary.fetch("dropTargetTypes")).not_to include("work_package")
    end

    # `block: :nearest` (rather than scroll_to_element's default `:start`)
    # scrolls the minimum distance needed to bring the row into view, and
    # does nothing at all if it is already visible, unlike `:start`,
    # which unconditionally forces the row to the viewport's top edge.
    # That edge happens to sit inside Pragmatic's auto-scroll trigger zone
    # (autoScrollForElements): starting the drag right there makes the
    # (correctly working) auto-scroll feature scroll the list's header
    # back into view under a stationary pointer, independently of the
    # drag's own movement, so the drop lands wherever the header
    # auto-scrolled to, not where the drag aimed.
    def scroll_backlogs_source_into_view(source)
      scroll_to_element(source, block: :nearest)
    end

    def selenium_drag_backlogs_item(source:, target:, edge: nil, dwell: false)
      install_backlogs_dnd_probe(source:, target:, edge:)

      offset_x, offset_y = selenium_target_offset(target.native.rect, edge:)
      perform_native_drag(source:, target:, offset_x:, offset_y:, dwell:)

      # Assert Pragmatic DnD tore down its own honey-pot overlay before we force
      # a cleanup, so a regression that leaves the overlay stuck is caught here
      # instead of being masked by the JS removal below.
      expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
      clear_pragmatic_dnd_honey_pot
    end

    def selenium_target_offset(rect, edge:)
      offset = [6, rect.height / 4].min

      [
        0,
        case edge
        when :top
          offset - (rect.height / 2)
        when :bottom
          (rect.height / 2) - offset
        else
          0
        end
      ].map(&:round)
    end

    def wait_for_backlogs_network_idle
      wait_for_network_idle if using_cuprite?
    end

    # Waits for a backlogs move to settle.
    #
    # A successful move responds with a turbo stream whose `turbo_frame_reload`
    # action reloads the `backlogs_container` frame — two round-trips: the stream
    # render and the frame reload. Callers that go on to touch the refreshed frame
    # pass `frame_reload: true` to await the frame load rather than racing it.
    #
    # A failed move (e.g. dropping onto a completed sprint) only renders an error
    # flash and never reloads the frame, so the default settles on the stream render.
    def wait_for_backlogs_turbo_stream(wait: Capybara.default_max_wait_time, frame_reload: false, &)
      return yield unless wait

      if frame_reload
        wait_for_turbo_frame(frame: "backlogs_container", wait:, &)
      else
        wait_for_turbo_stream(wait:, &)
      end
    end

    # A same-list reorder (drag within the same sprint/bucket/inbox) is applied
    # optimistically and never reloads the `backlogs_container` frame (see
    # Backlogs::WorkPackagesController#optimistic_same_list_move?), so
    # {#drag_work_package} must not wait for one. An `into:` drop always targets
    # a different sprint, and a `before:`/`after:` drop may or may not cross
    # lists (e.g. dragging a bucket item to just before a sprint item), so list
    # membership is compared directly.
    def cross_list_drag?(moved, before:, after:, into:)
      return true if into

      list_identity(moved) != list_identity(before || after)
    end

    # Reads the record's current list from the database rather than trusting
    # the passed object: specs reuse the same records across consecutive
    # drags, and a stale in-memory identity would misclassify a cross-list
    # drag as a same-list reorder, making the drag helper skip the frame
    # reload wait and race the re-render.
    def list_identity(work_package)
      Backlogs::Target.for_work_package(work_package.class.find(work_package.id))
    end

    def install_backlogs_dnd_probe(source:, target:, edge:)
      page.execute_script(<<~JS, source, target, edge&.to_s)
        window.__opBacklogsDndProbeAbort?.abort();

        const controller = new AbortController();
        const sourceElement = arguments[0];
        const targetElement = arguments[1];
        const state = {
          source: describeElement(sourceElement),
          target: describeElement(targetElement),
          requestedEdge: arguments[2],
          events: [],
          handleDropCalls: [],
          snapshots: []
        };

        function itemIdFor(element) {
          const closestItem = element?.closest?.('[data-sortable-lists--item-id-value]');
          const descendantItem = element?.querySelector?.('[data-sortable-lists--item-id-value]');

          return (closestItem ?? descendantItem)
            ?.getAttribute('data-sortable-lists--item-id-value') ?? null;
        }

        function backlogsItemFor(element) {
          return element?.closest?.('[data-sortable-lists--item-id-value]') ??
            element?.querySelector?.('[data-sortable-lists--item-id-value]') ??
            null;
        }

        function controllerInfo(element) {
          const item = backlogsItemFor(element);
          const application = window.Stimulus;

          if (!item || !application?.getControllerForElementAndIdentifier) {
            return { available: false };
          }

          const controller = application.getControllerForElementAndIdentifier(item, 'sortable-lists--item');

          return {
            available: true,
            connected: Boolean(controller),
            idValue: controller?.idValue ?? null,
            hasCleanupFn: Boolean(controller?.cleanupFn)
          };
        }

        function dataSummary(data) {
          if (!data || typeof data !== 'object') {
            return data ?? null;
          }

          const entries = Object.fromEntries(Object.entries(data));
          const symbols = Object.getOwnPropertySymbols(data).map((symbol) => ({
            description: symbol.description,
            value: data[symbol]
          }));

          return { entries, symbols };
        }

        function dropTargetSummary(dropTarget) {
          return {
            data: dataSummary(dropTarget.data),
            element: describeElement(dropTarget.element)
          };
        }

        function patchSortableListsController() {
          const application = window.Stimulus;
          const root = sourceElement.closest('[data-controller~="sortable-lists"]');
          const sortableListsController = root && application?.getControllerForElementAndIdentifier
            ? application.getControllerForElementAndIdentifier(root, 'sortable-lists')
            : null;

          state.sortableListsController = {
            rootFound: Boolean(root),
            connected: Boolean(sortableListsController),
            patched: false
          };

          if (!sortableListsController?.handleDrop || sortableListsController.__opBacklogsDndProbePatched) {
            return;
          }

          const originalHandleDrop = sortableListsController.handleDrop.bind(sortableListsController);

          sortableListsController.handleDrop = (payload) => {
            state.handleDropCalls.push({
              source: {
                data: dataSummary(payload.source?.data),
                element: describeElement(payload.source?.element)
              },
              dropTargets: payload.location?.current?.dropTargets?.map(dropTargetSummary) ?? [],
              input: payload.location?.current?.input ?? null,
              time: Math.round(performance.now())
            });

            return originalHandleDrop(payload);
          };

          sortableListsController.__opBacklogsDndProbePatched = true;
          state.sortableListsController.patched = true;
        }

        function describeElement(element) {
          if (!element) {
            return { found: false };
          }

          const rect = element.getBoundingClientRect();
          const item = backlogsItemFor(element);
          const row = element.closest?.('.Box-row');

          return {
            found: true,
            tagName: element.tagName,
            itemId: itemIdFor(element),
            testSelector: element.closest?.('[data-test-selector]')?.getAttribute('data-test-selector') ?? null,
            itemTagName: item?.tagName ?? null,
            draggable: item?.draggable ?? element.draggable,
            draggableAttribute: item?.getAttribute('draggable') ?? element.getAttribute('draggable'),
            dataDropTargetForElement: item?.getAttribute('data-drop-target-for-element') ??
              element.getAttribute('data-drop-target-for-element'),
            controller: controllerInfo(element),
            rowClassName: row?.className ?? null,
            rect: {
              x: Math.round(rect.x),
              y: Math.round(rect.y),
              width: Math.round(rect.width),
              height: Math.round(rect.height)
            }
          };
        }

        function snapshot(label) {
          state.snapshots.push({
            label,
            draggingCount: document.querySelectorAll('[data-dragging]').length,
            honeyPotCount: document.querySelectorAll('[data-pdnd-honey-pot]').length,
            dropContainers: Array
              .from(document.querySelectorAll('[data-drop-container]'))
              .map((element) => element.getAttribute('data-drop-container')),
            dropTargets: document.querySelectorAll('[data-drop-target-for-element]').length,
            dropPositions: Array
              .from(document.querySelectorAll('[data-drop-position]'))
              .map((element) => ({
                itemId: itemIdFor(element),
                position: element.getAttribute('data-drop-position')
              })),
            source: describeElement(sourceElement),
            target: describeElement(targetElement),
            time: Math.round(performance.now())
          });
        }

        function pushEvent(event) {
          const elementsFromPoint = event.clientX == null || event.clientY == null
            ? []
            : Array
              .from(document.elementsFromPoint(event.clientX, event.clientY))
              .slice(0, 6)
              .map(describeElement);

          state.events.push({
            type: event.type,
            targetItemId: itemIdFor(event.target),
            clientX: event.clientX,
            clientY: event.clientY,
            defaultPrevented: event.defaultPrevented,
            dropEffect: event.dataTransfer?.dropEffect ?? null,
            effectAllowed: event.dataTransfer?.effectAllowed ?? null,
            draggingCount: document.querySelectorAll('[data-dragging]').length,
            honeyPotCount: document.querySelectorAll('[data-pdnd-honey-pot]').length,
            dropContainers: Array
              .from(document.querySelectorAll('[data-drop-container]'))
              .map((element) => element.getAttribute('data-drop-container')),
            dropPositions: Array
              .from(document.querySelectorAll('[data-drop-position]'))
              .map((element) => ({
                itemId: itemIdFor(element),
                position: element.getAttribute('data-drop-position')
              })),
            elementsFromPoint,
            time: Math.round(performance.now())
          });

          if (state.events.length > 100) {
            state.events.shift();
          }
        }

        ['mousedown', 'mousemove', 'mouseup', 'dragstart', 'dragenter', 'dragover', 'dragleave', 'drop', 'dragend']
          .forEach((type) => document.addEventListener(type, pushEvent, {
            capture: true,
            signal: controller.signal
          }));

        patchSortableListsController();
        snapshot('before-drag');

        window.__opBacklogsDndProbeAbort = controller;
        window.__opBacklogsDndProbeState = state;
      JS
    end

    def install_backlogs_move_request_probe
      page.execute_script(<<~JS)
        window.__opBacklogsMoveRequestProbe = { requests: [] };

        if (!window.__opBacklogsOriginalFetch) {
          window.__opBacklogsOriginalFetch = window.fetch;
        }

        window.fetch = (...args) => {
          const request = args[0];
          const options = args[1] ?? {};
          const url = String(request?.url ?? request);
          const method = String(request?.method ?? options.method ?? 'GET').toUpperCase();

          if (method === 'PUT' && url.includes('/backlogs/')) {
            window.__opBacklogsMoveRequestProbe.requests.push({
              url,
              method,
              time: Math.round(performance.now())
            });
          }

          return window.__opBacklogsOriginalFetch(...args);
        };
      JS
    end

    def stop_backlogs_move_request_probe
      page.execute_script(<<~JS)
        if (window.__opBacklogsOriginalFetch) {
          window.fetch = window.__opBacklogsOriginalFetch;
        }
      JS
    end

    def clear_pragmatic_dnd_honey_pot
      page.execute_script(<<~JS)
        document
          .querySelectorAll('[data-pdnd-honey-pot]')
          .forEach((element) => element.remove());
      JS
    end

    def sprint_complete_modal_selector
      "##{::Backlogs::FinishSprintDialogComponent::DIALOG_ID}"
    end

    def backlog_bucket_destroy_modal_selector
      test_selector(Backlogs::BucketDestroyModalComponent::TEST_SELECTOR)
    end

    def open_controlled_menu(button)
      button.click
      page.find(:menu, id: button[:controls] || button["aria-controls"])
    end

    def open_move_submenu(menu)
      move_item = menu.find(:menuitem, text: "Move to position")
      move_item.click
      page.find(:menu, id: move_item["aria-controls"])
    end

    def dismiss_menu(menu_owner)
      selector = menu_owner_overlay_selector(menu_owner)

      return unless page.has_css?(selector, visible: true, wait: 0)
      return if page.has_selector?(:modal, wait: 0)

      find(selector, wait: 0).click
    rescue Capybara::ElementNotFound,
           Ferrum::CoordinatesNotFoundError,
           Selenium::WebDriver::Error::ElementNotInteractableError
      # Menu actions can close the menu or open a modal between the checks
      # above and the click; once the menu is gone or a modal owns focus,
      # the overlay is unclickable (Cuprite raises CoordinatesNotFoundError,
      # Selenium ElementNotInteractableError) and dismissal is moot.
      raise unless page.has_selector?(:modal, wait: 0) ||
        page.has_no_css?(selector, visible: true, wait: 0)
    end

    def headed_section_titles(id_prefix:)
      page
        .all(:section, section_element: :section, heading_level: 4)
        .select { |section| section[:id].to_s.start_with?(id_prefix) }
        .map { |section| section.first(:heading, level: 4).text }
    end

    def sprint_names_in_order
      within_sprint_backlogs do
        headed_section_titles(id_prefix: "backlogs-sprint-component-")
      end
    end

    def bucket_names_in_order
      within_owner_backlogs do
        headed_section_titles(id_prefix: "backlogs-bucket-component-")
      end
    end
  end
end
