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

# Selenium, not Cuprite: the modifier combinations are driven through native
# `send_keys`, and only a real page can prove the root's capture-phase
# listener beats the card's own click and Enter handlers.
RSpec.describe "Backlogs batch selection", :js, :selenium, :settings_reset do
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
  let!(:story1) { create(:work_package, sprint:, type:, project:) }
  let!(:story2) { create(:work_package, sprint:, type:, project:) }
  let!(:story3) { create(:work_package, sprint:, type:, project:) }
  let!(:story4) { create(:work_package, sprint:, type:, project:) }
  let!(:bucket) { create(:backlog_bucket, project:, name: "Backlog bucket") }
  let!(:bucket_wp1) { create(:work_package, backlog_bucket: bucket, position: 1, type:, project:) }
  let!(:bucket_wp2) { create(:work_package, backlog_bucket: bucket, position: 2, type:, project:) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  describe "mouse gestures" do
    it "collapses a wider selection onto the clicked card and still opens its details" do
      backlogs_page.select_card(story1)
      backlogs_page.toggle_card(story2)
      backlogs_page.select_card(story3)

      expect(page).to have_css("[data-batch-selected]", count: 1)
      expect(backlogs_page.selected_card_ids).to eq([story3.id.to_s])
      backlogs_page.expect_details_view(story3)
    end

    it "toggles a sparse selection across two lists without navigating" do
      # Seeded with a toggle, not a plain click: a plain click schedules its
      # details-pane visit on a timer, so the path assertion below would pass
      # with a still-pending navigation either way.
      backlogs_page.toggle_card(story1)
      backlogs_page.toggle_card(bucket_wp1)

      expect(page).to have_css("[data-batch-selected]", count: 2)
      expect(backlogs_page.selected_card_ids).to contain_exactly(story1.id.to_s, bucket_wp1.id.to_s)
      # Had the modified click reached the card's own handler, the details
      # pane would have opened and the path would have changed.
      expect(page).to have_current_path(backlogs_page.path, ignore_query: true)
    end

    # BatchSelection#toggle re-bases the anchor even on a deselect, so a
    # later range starts from story2 rather than story1.
    it "re-bases the anchor to a toggled card even when the toggle deselects it" do
      backlogs_page.select_card(story1)
      backlogs_page.toggle_card(story2)
      backlogs_page.toggle_card(story2)

      expect(page).to have_css("[data-batch-selected]", count: 1)

      backlogs_page.extend_selection_to(story4)

      expect(page).to have_css("[data-batch-selected]", count: 3)
      expect(backlogs_page.selected_card_ids).to eq([story2, story3, story4].map { it.id.to_s })
    end

    it "resizes one fixed-anchor range rather than walking it" do
      backlogs_page.select_card(story1)
      backlogs_page.extend_selection_to(story3)

      expect(page).to have_css("[data-batch-selected]", count: 3)
      expect(backlogs_page.selected_card_ids).to eq([story1, story2, story3].map { it.id.to_s })

      backlogs_page.extend_selection_to(story2)

      expect(page).to have_css("[data-batch-selected]", count: 2)
      expect(backlogs_page.selected_card_ids).to eq([story1, story2].map { it.id.to_s })
    end

    # The follow-up range proves the cross-list gesture re-anchored rather
    # than being refused outright.
    it "refuses to extend a range across lists and starts a fresh selection there" do
      backlogs_page.select_card(story1)
      backlogs_page.extend_selection_to(bucket_wp2)

      expect(page).to have_css("[data-batch-selected]", count: 1)
      expect(backlogs_page.selected_card_ids).to eq([bucket_wp2.id.to_s])

      backlogs_page.extend_selection_to(bucket_wp1)

      expect(page).to have_css("[data-batch-selected]", count: 2)
      expect(backlogs_page.selected_card_ids).to eq([bucket_wp1, bucket_wp2].map { it.id.to_s })
    end
  end

  describe "keyboard interaction" do
    it "paints a row with a different background once it is selected" do
      # Focus is established first and held constant across both reads: a
      # click would move focus, open the details pane and toggle membership at
      # once, leaving the colour difference unattributable.
      backlogs_page.focus_work_package_card(story1)
      unselected_color = backlogs_page.row_background_color(story1)

      backlogs_page.work_package_card(story1).send_keys(:space)

      expect(page).to have_css("[data-batch-selected]", count: 1)
      expect(backlogs_page.row_background_color(story1)).not_to eq(unselected_color)
    end

    it "selects and clears with the keyboard" do
      backlogs_page.work_package_card(story1).send_keys(:space)

      expect(page).to have_css("[data-batch-selected]", count: 1)
      expect(backlogs_page.selected_card_ids).to eq([story1.id.to_s])

      backlogs_page.work_package_card(story1).send_keys(:escape)

      expect(page).to have_no_css("[data-batch-selected]")
      expect(backlogs_page.selected_card_ids).to be_empty
    end

    # A click on empty column space leaves focus nowhere, and Escape there
    # still means "drop the selection".
    it "clears the selection with Escape when no card holds focus" do
      backlogs_page.toggle_card(story1)
      expect(page).to have_css("[data-batch-selected]", count: 1)

      page.execute_script("document.activeElement.blur()")
      backlogs_page.send_keys_to_focused_element(:escape)

      expect(page).to have_no_css("[data-batch-selected]")
      expect(backlogs_page.selected_card_ids).to be_empty
    end

    # The fixtures span a sprint and a bucket, so a regression to root-wide
    # select-all would take this past the sprint's four cards.
    it "selects every orderable card of the focused card's list with Ctrl/Cmd+A" do
      backlogs_page.send_work_package_card_keys(story1, [backlogs_page.multi_select_modifier, "a"])

      expect(page).to have_css("[data-batch-selected]", count: 4)
      expect(backlogs_page.selected_card_ids).to contain_exactly(
        story1.id.to_s, story2.id.to_s, story3.id.to_s, story4.id.to_s
      )
    end

    it "extends the selection from a fixed anchor with Shift+ArrowDown" do
      backlogs_page.work_package_card(story1).send_keys(:space)
      expect(page).to have_css("[data-batch-selected]", count: 1)

      backlogs_page.send_work_package_card_keys(story1, %i[shift arrow_down])

      expect(page).to have_css("[data-batch-selected]", count: 2)
      expect(backlogs_page.selected_card_ids).to eq([story1, story2].map { it.id.to_s })
    end

    # Enter belongs to the card's own activation handler, which only a real
    # page can prove.
    it "opens details with Enter without the selection handler swallowing it" do
      backlogs_page.send_work_package_card_keys(story2, [:enter])

      backlogs_page.expect_details_view(story2)
    end
  end

  describe "selection persistence and accessibility" do
    it "keeps the batch selected when the current work package changes" do
      backlogs_page.select_card(story1)
      # A plain click waits out a double-click window before it visits, so
      # without this wait story1's pending visit lands while story3's lazily
      # loaded actions menu is opening below, racing its fetch.
      backlogs_page.expect_details_view(story1)
      backlogs_page.toggle_card(story2)

      expect(page).to have_css("[data-batch-selected]", count: 2)

      backlogs_page.open_work_package_details(story3)

      expect(page).to have_css("[data-batch-selected]", count: 2)
      expect(backlogs_page.selected_card_ids).to contain_exactly(story1.id.to_s, story2.id.to_s)
    end

    it "describes a selected card to assistive technology via the shared description" do
      backlogs_page.select_card(story1)
      backlogs_page.toggle_card(story2)

      expect(page).to have_css("[data-batch-selected]", count: 2)
      # Rendered exactly once, so the assertions below speak about one
      # element rather than two that happen to agree.
      backlogs_page.expect_selection_description_present

      # The card, not the row: a description is computed from the focused
      # element's own `aria-describedby`, never inherited. The computed value
      # also proves the browser traverses into the `hidden` element.
      description = I18n.t("js.backlogs.selection.card_state")
      backlogs_page.expect_work_package_card_described_as(story1, description)
      backlogs_page.expect_work_package_card_described_as(story2, description)
      # Without this, the two above would pass with every card described.
      backlogs_page.expect_work_package_card_not_described(story3)
    end

    # The expander is a frame navigation, not a morph: it swaps the inbox rows
    # wholesale. The selection made before it must be back on the fresh rows,
    # not stranded in the model while the cards paint as unselected.
    context "with a truncated inbox" do
      let!(:inbox_wps) { create_list(:work_package, 5, project:, type:) }

      # The constant has to be stubbed before the page renders, so the visit
      # from the outer hook is repeated here.
      before do
        stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 2)
        backlogs_page.visit!
      end

      it "keeps the selection across the show-more expander" do
        backlogs_page.expect_inbox_show_more
        backlogs_page.toggle_card(inbox_wps.first)
        expect(backlogs_page.selected_card_ids).to eq([inbox_wps.first.id.to_s])

        backlogs_page.click_inbox_show_more
        backlogs_page.expect_no_inbox_show_more

        expect(backlogs_page.selected_card_ids).to eq([inbox_wps.first.id.to_s])
      end
    end
  end

  # Selection consumes Space, the arrows, Home/End and Ctrl/Cmd+A. With every
  # card fixed those keys would stop scrolling the page for a capability it
  # never offers, so the root does not opt in at all.
  describe "without the permission to manage sprint items" do
    let(:view_role) do
      create(:project_role, permissions: %i(view_sprints view_work_packages))
    end

    current_user do
      create(:user, member_with_roles: { project => view_role })
    end

    # `current_user` declared here registers its login after the outer
    # `before` has already visited, so the page is visited again.
    before do
      backlogs_page.visit!
    end

    it "does not enable selection, and leaves its gestures to the browser" do
      backlogs_page.expect_batch_selection_disabled

      backlogs_page.toggle_card(story1)
      backlogs_page.send_work_package_card_keys(story2, [:space])

      expect(page).to have_no_css("[data-batch-selected]")
    end
  end
end
