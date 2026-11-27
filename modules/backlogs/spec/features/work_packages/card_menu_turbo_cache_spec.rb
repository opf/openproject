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

require "spec_helper"
require_relative "../../support/pages/backlog"

RSpec.describe "Backlog card menus restored or morphed by Turbo",
               :js,
               :selenium do
  let!(:project) do
    create(:project, types: [type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i[view_sprints manage_sprint_items view_work_packages edit_work_packages])
  end
  let!(:sprint) { create(:sprint, project:, name: "Sprint") }
  let!(:first_story) { create(:work_package, project:, type:, sprint:, position: 1) }
  let!(:second_story) { create(:work_package, project:, type:, sprint:, position: 2) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  def install_menu_request_probe
    page.execute_script(<<~JS)
      window.menuRequests = [];
      window.menuRequestStacks = [];
      const originalFetch = window.fetch;
      window.fetch = function(input, options) {
        const url = new URL(input instanceof Request ? input.url : input.toString(), window.location.href);
        if (url.pathname.endsWith('/backlogs/work_packages/menu')) {
          window.menuRequests.push(url.searchParams.getAll('ids[]'));
          window.menuRequestStacks.push(new Error().stack);
        }
        return originalFetch.call(this, input, options);
      };
    JS
  end

  def expect_menu_requests(*batches)
    page.evaluate_async_script("const done = arguments[0]; requestAnimationFrame(() => requestAnimationFrame(done));")
    expect(page.evaluate_script("window.menuRequests"))
      .to eq(batches.map { |batch| batch.map { |wp| wp.id.to_s } }), page.evaluate_script("window.menuRequestStacks.join('\\n')")
  end

  def inbox_form_ids(menu)
    button = menu.find(:menuitem, text: "Move to backlog inbox", exact_text: true)
    page.evaluate_script("new FormData(arguments[0].form).getAll('ids[]')", button)
  end

  def submit_inbox(menu)
    menu.find(:menuitem, text: "Move to backlog inbox", exact_text: true).click
  end

  it "starts with an empty primary body and an inert server-rendered loader" do
    menu = backlogs_page.work_package_card(first_story).find("action-menu", visible: :all)
    markup = page.evaluate_script(<<~JS, menu)
      (() => {
        const menu = arguments[0];
        return {
          children: menu.querySelector('[data-target="action-menu.overlayBody"]')?.childElementCount,
          src: menu.querySelector('template[data-target="action-menu.loaderTemplate"]')?.content.firstElementChild?.getAttribute('src')
        };
      })()
    JS
    expect(markup).to eq("children" => 0, "src" => menu["src"])
  end

  %i[more right_click].each do |via|
    it "deduplicates healthy reopens, refreshes changed IDs and submits their order via #{via}" do
      install_menu_request_probe
      backlogs_page.open_card_menu(first_story, via:)
      expect_menu_requests([first_story])
      backlogs_page.dismiss_card_menu(first_story, via:)
      backlogs_page.clear_card_selection(first_story)
      backlogs_page.select_cards(second_story, first_story)

      menu = backlogs_page.open_card_menu(second_story, via:)
      expect_menu_requests([first_story], [first_story, second_story])
      expect(inbox_form_ids(menu)).to eq([first_story.id, second_story.id].map(&:to_s))
      backlogs_page.dismiss_card_menu(second_story, via:)
      menu = backlogs_page.open_card_menu(second_story, via:)
      expect_menu_requests([first_story], [first_story, second_story])
      submit_inbox(menu)

      backlogs_page.expect_inbox_items_in_order(items: [first_story, second_story])
      expect(first_story.reload.sprint_id).to be_nil
      expect(second_story.reload.sprint_id).to be_nil
    end

    it "loads and submits only the singleton after restoring a card whose batch menu had loaded via #{via}" do
      backlogs_page.select_cards(first_story, second_story)
      backlogs_page.open_card_menu(second_story, via:)
      backlogs_page.leave_for_all_sprints
      backlogs_page.go_back_to_backlogs
      backlogs_page.clear_card_selection(second_story)
      install_menu_request_probe

      menu = backlogs_page.open_card_menu(second_story, via:)
      expect_menu_requests([second_story])
      expect(inbox_form_ids(menu)).to eq([second_story.id.to_s])
      submit_inbox(menu)
      backlogs_page.expect_inbox_items_in_order(items: [second_story])
      backlogs_page.expect_sprint_items_in_order(sprint, items: [first_story])
      expect(first_story.reload.sprint_id).to eq(sprint.id)
    end
  end

  it "adopts a shell-first loader from a real Turbo morph and submits the current singleton" do
    backlogs_page.select_cards(first_story, second_story)
    install_menu_request_probe
    backlogs_page.open_card_menu(first_story, via: :more)
    backlogs_page.dismiss_card_menu(first_story, via: :more)
    backlogs_page.clear_card_selection(first_story)
    menu = backlogs_page.work_package_card(first_story).find("action-menu", visible: :all)
    page.execute_script(<<~JS, menu, first_story.id.to_s)
      const menu = arguments[0], id = arguments[1];
      const fragment = menu.querySelector('template[data-target="action-menu.loaderTemplate"]').content.firstElementChild.cloneNode(true);
      const url = new URL(menu.getAttribute('src'), window.location.href);
      url.searchParams.delete('ids[]');
      url.searchParams.append('ids[]', id);
      fragment.setAttribute('src', url.pathname + url.search);
      fragment.setAttribute('loading', 'lazy');
      const body = menu.querySelector('[data-target="action-menu.overlayBody"]');
      body.id = 'shell-first-menu-body';
      Turbo.renderStreamMessage(`<turbo-stream action="update" method="morph" target="${body.id}"><template>${fragment.outerHTML}</template></turbo-stream>`);
    JS
    expect(page).to have_css("#shell-first-menu-body > include-fragment[loading='lazy']", visible: :all)
    expect_menu_requests([first_story, second_story])

    loaded_menu = backlogs_page.open_card_menu(first_story, via: :more)
    expect_menu_requests([first_story, second_story], [first_story])
    submit_inbox(loaded_menu)
    backlogs_page.expect_inbox_items_in_order(items: [first_story])
    backlogs_page.expect_sprint_items_in_order(sprint, items: [second_story])
  end

  context "with a full inbox selection and no other destination" do
    let!(:sprint) { nil }

    it "deduplicates a healthy explained batch menu on reopen" do
      explanation = "No actions available for the selected work packages."
      backlogs_page.select_cards(first_story, second_story)
      install_menu_request_probe
      menu = backlogs_page.open_card_menu(first_story, via: :more)
      expect(menu).to have_selector(:menuitem, text: explanation, disabled: true)
      expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
      expect_menu_requests([first_story, second_story])
      backlogs_page.dismiss_card_menu(first_story, via: :more)

      menu = backlogs_page.open_card_menu(first_story, via: :more)
      expect(menu).to have_selector(:menuitem, text: explanation, disabled: true)
      expect_menu_requests([first_story, second_story])
    end
  end

  it "loads a menu that was loaded before leaving for the current selection" do
    backlogs_page.expect_work_package_actions(first_story, present: ["Open details view"])

    backlogs_page.leave_for_all_sprints
    backlogs_page.go_back_to_backlogs

    backlogs_page.select_cards(first_story, second_story)
    backlogs_page.open_work_package_menu(first_story)
    expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
    expect(page).to have_selector(:menuitem, text: "Move to backlog inbox")
    expect(page).to have_no_selector(:menuitem, text: "Open details view")
  end

  it "restores the singular menu of a page cached while its batch menu was open" do
    backlogs_page.leave_for_all_sprints
    backlogs_page.go_back_to_backlogs

    backlogs_page.select_cards(first_story, second_story)
    backlogs_page.open_work_package_menu(first_story)
    expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")

    backlogs_page.go_forward_to_all_sprints
    backlogs_page.go_back_to_backlogs

    backlogs_page.within_work_package(first_story) do
      expect(page).to have_button(accessible_name: "Work package actions")
    end
    backlogs_page.expect_work_package_actions(first_story, present: ["Open details view"])
  end

  it "loads a menu that was loaded before a morphing refresh" do
    backlogs_page.expect_work_package_actions(first_story, present: ["Open details view"])

    backlogs_page.move_to_backlog_inbox(second_story)
    backlogs_page.expect_inbox_items_in_order(items: [second_story])

    backlogs_page.within_work_package_menu(first_story) do |menu|
      expect(menu).to have_selector(:menuitem, text: "Open details view", focused: true)
    end
    backlogs_page.expect_selected_cards_in_order(first_story)

    backlogs_page.toggle_card(second_story)
    backlogs_page.expect_selected_cards_in_order(second_story, first_story)
    backlogs_page.open_work_package_menu(first_story)
    expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
    expect(page).to have_selector(:menuitem, text: "Move to sprint")
    expect(page).to have_no_selector(:menuitem, text: "Open details view")
  end
end
