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
require_relative "../../support/pages/backlog"

RSpec.describe "Backlogs destination reveal", :js, :selenium, :settings_reset do
  include RSpec::Wait

  batch_sizes = [false, true]

  let!(:project) { create(:project, types: [type], enabled_module_names: %w[work_package_tracking backlogs]) }
  let(:type) { create(:type) }
  let(:role) do
    create(:project_role, permissions: %i[view_sprints manage_sprint_items view_work_packages edit_work_packages])
  end
  let!(:source) { create(:sprint, project:, name: "A source") }
  let(:visible_status) { create(:status) }
  let!(:story) { create(:work_package, project:, type:, sprint: source, status: visible_status, position: 1) }
  let!(:second_story) { create(:work_package, project:, type:, sprint: source, status: visible_status, position: 2) }
  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user { create(:user, member_with_roles: { project => role }) }

  def settle_backlogs_frame
    page.evaluate_async_script(<<~JS)
      const done = arguments[0], frame = document.getElementById('backlogs_container');
      frame.loaded.then(() => requestAnimationFrame(() => requestAnimationFrame(done)));
    JS
  end

  def install_focus_scroll_probe
    settle_backlogs_frame
    page.execute_script(<<~JS)
      window.revealProbe = [];
      window.revealProbeVisible = (card) => {
        const rect = card.getBoundingClientRect();
        let top = 0, bottom = window.innerHeight, left = 0, right = window.innerWidth;
        for (let parent = card.parentElement; parent; parent = parent.parentElement) {
          const style = getComputedStyle(parent), bounds = parent.getBoundingClientRect();
          if (/(auto|scroll|hidden|clip)/.test(style.overflowY)) {
            top = Math.max(top, bounds.top);
            bottom = Math.min(bottom, bounds.bottom);
          }
          if (/(auto|scroll|hidden|clip)/.test(style.overflowX)) {
            left = Math.max(left, bounds.left);
            right = Math.min(right, bounds.right);
          }
        }
        return rect.top >= top - 1 && rect.bottom <= bottom + 1 && rect.left >= left - 1 && rect.right <= right + 1;
      };
      const describe = (element) => ({
        tag: element?.tagName,
        id: element?.id,
        row: element?.closest?.('[data-sortable-lists--item-id-value]')?.getAttribute('data-sortable-lists--item-id-value')
      });
      const record = (kind, target, options) => window.revealProbe.push({ kind, target: describe(target), options, active: describe(document.activeElement) });
      const focus = HTMLElement.prototype.focus;
      HTMLElement.prototype.focus = function(options) {
        record('focus', this, options);
        return focus.call(this, options);
      };
      const scroll = Element.prototype.scrollIntoView;
      Element.prototype.scrollIntoView = function(options) {
        record('scrollIntoView', this, options);
        window.revealProbe.at(-1).visibleBefore = window.revealProbeVisible(this);
        return scroll.call(this, options);
      };
      document.addEventListener('focusin', (event) => record('focusin', event.target));
      for (const name of ['turbo:frame-render', 'turbo:frame-load']) {
        document.addEventListener(name, (event) => {
          if (event.target.id === 'backlogs_container') record(name, document.activeElement);
        });
      }
      document.addEventListener('op-dispatched:backlogs:work-package-moved', () => record('moved', document.activeElement));
    JS
  end

  def settled_probe
    page.evaluate_async_script("const done = arguments[0]; requestAnimationFrame(() => requestAnimationFrame(done));")
    page.evaluate_script(<<~JS)
      ({ events: window.revealProbe, active: { tag: document.activeElement.tagName, id: document.activeElement.id } })
    JS
  end

  def expect_destination_revealed(observation, first)
    events = observation.fetch("events")
    expect(events.pluck("kind")).to include("moved", "turbo:frame-render", "turbo:frame-load")
    completion = events.index { |event| event.fetch("kind") == "turbo:frame-load" }
    scrolls = events.drop(completion + 1).select { |event| event.fetch("kind") == "scrollIntoView" }
    expect(scrolls.size).to eq(1)
    expect(scrolls.first.dig("target", "row")).to eq(first.id.to_s)
    expect(events.index(scrolls.first)).to be > events.index { |event| event.fetch("kind") == "turbo:frame-load" }
    expect(scrolls.first.fetch("visibleBefore")).to be(false)
    expect(scrolls.first.fetch("active").slice("tag", "id")).to eq(observation.fetch("active"))
    expect(card_in_scrollport?(first)).to be(true)
  end

  def card_in_scrollport?(work_package)
    page.evaluate_script(<<~JS, work_package.id.to_s)
      window.revealProbeVisible(document.querySelector(`[data-backlogs--work-package-id-value="${arguments[0]}"]`))
    JS
  end

  %i[inbox backlog_bucket sprint].each do |target|
    context "with a populated #{target}" do
      let!(:destination) { create(target, project:, name: "Destination") unless target == :inbox }
      let!(:destination_stories) do
        attributes = target == :inbox ? {} : { target => destination }
        Array.new(20) { |index| create(:work_package, project:, type:, position: index + 1, **attributes) }
      end

      batch_sizes.each do |batch|
        it "reveals the first #{batch ? 'batch' : 'singleton'} member without changing settled focus" do
          backlogs_page.visit!
          settle_backlogs_frame
          moved = batch ? [story, second_story] : [story]
          backlogs_page.select_contiguous_cards(*moved) if batch
          invoker = moved.last
          if target == :inbox
            install_focus_scroll_probe
            backlogs_page.move_to_backlog_inbox(invoker)
            backlogs_page.expect_inbox_items_in_order(items: destination_stories + moved)
          else
            label = target == :sprint ? "Move to sprint" : "Move to backlog bucket"
            backlogs_page.activate_card_menu_action(invoker, label, via: :more)
            install_focus_scroll_probe
            backlogs_page.submit_destination_dialog(label, option: "Destination")
            if target == :sprint
              backlogs_page.expect_sprint_items_in_order(destination, items: destination_stories + moved)
            else
              backlogs_page.expect_bucket_items_in_order(destination, items: destination_stories + moved)
            end
          end

          expect_destination_revealed(settled_probe, moved.first)
        end
      end

      if target == :sprint
        it "reveals a cross-container drag through the same owning-frame path" do
          dragged = create(:work_package, project:, type:)
          backlogs_page.visit!
          install_focus_scroll_probe
          backlogs_page.drag_work_package(dragged, after: destination_stories.last)
          backlogs_page.expect_sprint_items_in_order(destination, items: destination_stories + [dragged])

          expect_destination_revealed(settled_probe, dragged)
        end
      end
    end
  end

  context "when the first appended inbox member is truncated" do
    let!(:destination_stories) { Array.new(10) { |index| create(:work_package, project:, type:, position: index + 1) } }

    it "does not substitute the visible later member or emit a filter warning" do
      stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 5)
      backlogs_page.visit!
      settle_backlogs_frame
      backlogs_page.select_contiguous_cards(story, second_story)
      install_focus_scroll_probe
      backlogs_page.move_to_backlog_inbox(second_story)
      within("#backlogs_container [data-sortable-lists--list-type-value='inbox']") do
        rendered_ids = all("[data-backlogs--work-package-id-value]").pluck("data-backlogs--work-package-id-value")
        expect(rendered_ids).to eq((destination_stories.first(5) + [second_story]).map { |wp| wp.id.to_s })
      end

      expect(page).to have_no_css("[data-backlogs--work-package-id-value='#{story.id}']")
      expect(settled_probe.fetch("events").pluck("kind")).not_to include("scrollIntoView")
      expect(page).to have_no_text(I18n.t(:notice_work_package_invisible_after_move, count: 1, backlog: I18n.t(:label_inbox)))
    end
  end

  context "with an unavailable first result" do
    let!(:destination) { create(:sprint, project:, name: "Destination") }

    it "keeps the existing filter flash without scrolling to a visible later member" do
      excluded_type = create(:type)
      project.project_types.create!(type: excluded_type)
      project.backlog_excluded_types << excluded_type
      story.update_columns(type_id: excluded_type.id)
      filtered_destination = create(:backlog_bucket, project:, name: "Filtered destination")
      backlogs_page.visit!
      settle_backlogs_frame
      backlogs_page.select_contiguous_cards(story, second_story)
      backlogs_page.open_destination_dialog(second_story, "Move to backlog bucket")
      install_focus_scroll_probe
      backlogs_page.submit_destination_dialog("Move to backlog bucket", option: filtered_destination.name)
      backlogs_page.expect_bucket_items_in_order(filtered_destination, items: [second_story])

      expect(page).to have_no_css("[data-backlogs--work-package-id-value='#{story.id}']")
      expect(settled_probe.fetch("events").pluck("kind")).not_to include("scrollIntoView")
      expect(page).to have_text(I18n.t(:notice_work_package_invisible_after_move, count: 1, backlog: filtered_destination.name))
    end

    it "does not reveal a failed move on a later unrelated frame reload" do
      backlogs_page.visit!
      backlogs_page.open_destination_dialog(story, "Move to sprint")
      destination.destroy!
      install_focus_scroll_probe
      backlogs_page.submit_destination_dialog("Move to sprint", option: "Destination", frame_reload: false)
      backlogs_page.expect_sprint_items_in_order(source, items: [story, second_story])
      expect(settled_probe.fetch("events").pluck("kind")).not_to include("moved", "scrollIntoView")

      page.evaluate_async_script(<<~JS)
        const done = arguments[0], frame = document.getElementById('backlogs_container');
        frame.addEventListener('turbo:frame-load', () => done(), { once: true });
        frame.reload();
      JS
      expect(settled_probe.fetch("events").pluck("kind")).not_to include("scrollIntoView")
    end
  end

  it "does not reveal a same-list reposition" do
    backlogs_page.visit!
    install_focus_scroll_probe
    backlogs_page.click_in_work_package_move_submenu(story, "Move down")
    backlogs_page.expect_sprint_items_in_order(source, items: [second_story, story])
    wait_for { settled_probe.fetch("events").pluck("kind") }.to include("moved")

    expect(settled_probe.fetch("events").pluck("kind")).not_to include("scrollIntoView", "turbo:frame-load")
  end
end
