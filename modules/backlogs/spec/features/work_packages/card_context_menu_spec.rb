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
require_relative "../../support/pages/backlog"

# Selenium, not Cuprite: the presenter's behaviour hangs on a trusted
# `contextmenu` and on a real pointer sequence for the browser's light-dismiss
# to act on, neither of which a synthesised gesture reproduces.
RSpec.describe "Open a backlog card's action menu contextually",
               :js, :selenium do
  let!(:project) do
    create(:project,
           types: [type],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           manage_sprint_items
                           view_work_packages
                           edit_work_packages))
  end

  let(:type) { create(:type) }

  let!(:sprint) { create(:sprint, project:) }
  let!(:sprint_wp) { create(:work_package, sprint:, type:, project:) }
  # Declared here, ahead of the visit below, because RSpec runs an outer
  # group's `before` hooks before an inner group's `let!`: cards created by a
  # nested group would not exist yet when the page renders. Groups that need a
  # scrollable list override this.
  let!(:extra_sprint_wps) { [] }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  it "opens the lazily loaded menu on right-click and focuses its first action" do
    backlogs_page.open_card_menu(sprint_wp, via: :right_click)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end

    backlogs_page.expect_menu_anchored_contextually(sprint_wp)
  end

  # Escape has to travel through whatever currently holds focus. Sending it to
  # the card element would make the driver focus the card first, closing the
  # menu by focus-out and leaving focus on the card no matter what the
  # presenter does — the assertion would pass against a broken implementation.
  it "returns focus to the card when the menu closes" do
    backlogs_page.right_click_work_package_card(sprint_wp)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end

    backlogs_page.send_keys_to_focused_element(:escape)

    backlogs_page.expect_no_work_package_context_menu(sprint_wp)
    backlogs_page.expect_work_package_card_focused(sprint_wp)
  end

  # The first opening exercises the deferred fetch; the second exercises the
  # already-loaded menu, whose first-item focus runs through a different
  # Primer code path (the toggle handler rather than include-fragment-replaced).
  it "focuses the first action again when an already loaded menu reopens" do
    backlogs_page.right_click_work_package_card(sprint_wp)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end

    backlogs_page.send_keys_to_focused_element(:escape)
    backlogs_page.expect_no_work_package_context_menu(sprint_wp)

    backlogs_page.right_click_work_package_card(sprint_wp)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end
  end

  # Selenium's Element Send Keys focuses its receiver, so the card needs no
  # separate focus step. The menu has to take focus here just as it does for a
  # right-click: that is what the card's aria-keyshortcuts promise is worth.
  #
  # It opens where the More button opens it, not at a second, card-relative
  # position of its own: same menu, same card, so the two ways of asking for it
  # have no reason to disagree. Only the focus return stays contextual.
  it "opens the same menu from the keyboard with Shift+F10" do
    backlogs_page.open_card_menu(sprint_wp, via: :shift_f10)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end

    backlogs_page.expect_menu_anchored_at_button(sprint_wp)
  end

  # The card's own actions button keeps no native context menu: right-clicking
  # the control that exists to open this menu opens this menu, at the position
  # that button has always produced. Every other interactive descendant — the
  # subject link, fields, clipboard controls — still falls through to the
  # browser, which the unit specs pin down.
  it "opens the menu at its trigger when the trigger is right-clicked" do
    backlogs_page.right_click_work_package_menu_button(sprint_wp)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end

    backlogs_page.expect_menu_anchored_at_button(sprint_wp)
  end

  # The presenter rewrites the overlay's anchoring for one invocation; if it
  # failed to restore it, the More button would reopen the menu at the last
  # pointer position instead of beside the button.
  it "leaves the More button menu working after a contextual invocation" do
    backlogs_page.right_click_work_package_card(sprint_wp)

    backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
    end

    backlogs_page.expect_menu_anchored_contextually(sprint_wp)

    backlogs_page.send_keys_to_focused_element(:escape)
    backlogs_page.expect_no_work_package_context_menu(sprint_wp)

    backlogs_page.within_work_package_menu(sprint_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"))
      # Still inside the block: the More button has to be anchoring this very
      # opening, not merely be back in place after it was dismissed again.
      backlogs_page.expect_menu_anchored_at_button(sprint_wp)
    end
  end

  # Regression (AGILE-348 QA): the menu used to be anchored on a synthetic
  # `position: fixed` element placed at the pointer. Primer does reposition the
  # overlay on scroll, but a fixed element never moves in viewport space, so
  # every reposition recomputed the same point while the card scrolled out from
  # under it. Only a real browser can show that: the anchoring the unit specs
  # can read is identical either way.
  describe "with the page scrolled while the menu is open" do
    # Enough cards for the page to actually overflow. Without them the scroll
    # below is a no-op and the assertion would hold against any implementation,
    # which is what the `moved` guard makes impossible to do silently.
    # rubocop:disable FactoryBot/ExcessiveCreateList
    let!(:extra_sprint_wps) { create_list(:work_package, 25, sprint:, type:, project:) }
    # rubocop:enable FactoryBot/ExcessiveCreateList

    let(:scroll_distance) { 120 }

    before do
      # The sprint list arrives in a lazily loaded turbo-frame, and this many
      # cards take long enough to render that right-clicking one straight after
      # the visit hands Selenium a node about to be replaced.
      backlogs_page.expect_sprint_work_package_count(sprint, extra_sprint_wps.size + 1)
    end

    it "keeps the menu with the card" do
      backlogs_page.right_click_work_package_card(sprint_wp)

      backlogs_page.within_work_package_context_menu(sprint_wp) do |menu|
        expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
      end

      offset_before = backlogs_page.work_package_menu_offset_from_card(sprint_wp)
      moved = backlogs_page.scroll_past_work_package_card(sprint_wp, distance: scroll_distance)

      # The page really did scroll, and the card really did move with it, so
      # what follows is a repositioning rather than a pair of untouched rects.
      expect(moved).to be_within(scroll_distance / 4).of(scroll_distance)

      # Primer repositions from a scroll listener and applies it a frame later,
      # so the menu settles back onto the card rather than being there already.
      wait_for { backlogs_page.work_package_menu_offset_from_card(sprint_wp)[:top] }
        .to be_within(2).of(offset_before[:top])
      expect(backlogs_page.work_package_menu_offset_from_card(sprint_wp)[:left])
        .to be_within(2).of(offset_before[:left])
    end
  end
end
