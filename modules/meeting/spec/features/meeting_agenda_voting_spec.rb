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

require_relative "../support/pages/meetings/show"

RSpec.describe "Meeting agenda voting", :js, :selenium do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:editor) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas] }) }
  let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based, state: :open) }
  let!(:section) { create(:meeting_section, meeting:, title: "Discussion") }
  let!(:first_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, title: "First topic") }
  let!(:second_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, title: "Second topic") }

  def vote_on_item(item, action)
    within("#meeting-agenda-item-#{item.id}") do
      find('[data-test-selector="op-meeting-agenda-actions"]').click
      click_on action
    end
  end

  def set_sorting_mode(mode)
    find('[data-test-selector="agenda-sorting-mode-selector-button"]').click

    within("dialog#agenda-sorting-dialog") do
      choose mode
      click_on "Save"
    end

    expect(page).to have_no_css("dialog#agenda-sorting-dialog[open]")
    if mode == "Vote-based"
      expect(page).to have_css(".meeting-infoline", text: "Agenda sorted by votes.")
    else
      expect(page).to have_no_text("Agenda sorted by votes.")
    end
  end

  def expect_add_item_action(item, present:)
    within("#meeting-agenda-item-#{item.id}") do
      find('[data-test-selector="op-meeting-agenda-actions"]').click
    end

    expect(page).to have_selector(:menuitem, text: "Copy link to clipboard")
    if present
      expect(page).to have_selector(:menuitem, text: "Add agenda item")
    else
      expect(page).to have_no_selector(:menuitem, text: "Add agenda item")
    end
    page.send_keys(:escape)
  end

  def hover_pointer?
    page.evaluate_script("matchMedia('(hover: hover) and (pointer: fine)').matches")
  end

  def expect_item_order(*items)
    expected = items.map { |item| "meeting-agenda-item-#{item.id}" }
    page.document.synchronize do
      found = all(".op-meeting-agenda-item-wrapper").map { it[:id] }
      raise Capybara::ExpectationNotMet, "Expected #{expected}, got #{found}" unless found == expected
    end
  end

  it "lets a viewer upvote, switch, and remove votes through the menu" do
    login_as viewer
    visit project_meeting_path(project, meeting)

    expect_item_order(first_item, second_item)
    expect(page).to have_no_css('.op-meeting-agenda-item-wrapper [data-draggable-type="agenda-item"]')

    vote_on_item(second_item, "👍 Upvote")
    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 1", visible: :all)
    expect_item_order(second_item, first_item)

    vote_on_item(second_item, "👎 Downvote")
    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: -1", visible: :all)
    expect_item_order(first_item, second_item)

    vote_on_item(second_item, "👎 Remove downvote")
    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 0", visible: :all)
    expect(second_item.emoji_reactions).to be_empty
  end

  it "lets an editor configure vote sorting and restore manual order" do
    login_as editor
    meeting.update!(agenda_sorting_mode: :manual)
    visit project_meeting_path(project, meeting)

    set_sorting_mode("Vote-based")
    vote_on_item(second_item, "👍 Upvote")
    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 1", visible: :all)
    expect_item_order(second_item, first_item)
    expect_add_item_action(second_item, present: false)

    set_sorting_mode("Manual")
    expect_item_order(first_item, second_item)
    expect_add_item_action(second_item, present: true)
    expect(page).to have_no_text("Votes:")
    expect(second_item.reload.vote_score).to eq(1)
    expect(first_item.reload.position).to eq(1)
    expect(second_item.position).to eq(2)
  end

  it "lets an editor drag a backlog item into a vote-sorted section" do
    backlog_item = create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog, title: "Backlog topic")
    second_item.emoji_reactions.create!(user: viewer, reaction: :thumbs_up)
    show_page = Pages::Meetings::Show.new(meeting)

    login_as editor
    show_page.visit!
    show_page.expect_backlog(collapsed: false)

    drag_handle = page.find("#meeting-agenda-items-item-component-show-component-#{backlog_item.id} .handle svg")
    target_section = page.find("#meeting-sections-show-component-#{section.id}")
    drag_n_drop_element(from: drag_handle, to: target_section)

    show_page.expect_agenda_item_in_section(title: "Backlog topic", section:)
    expect_item_order(second_item, first_item, backlog_item)
    expect(backlog_item.reload.meeting_section).to eq(section)
  end

  it "reveals score buttons on hover and supports switching and removing votes" do
    login_as viewer
    visit project_meeting_path(project, meeting)

    find(".meeting-infoline").hover
    score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score", visible: :all)
    expect(score_line.style("opacity")["opacity"]).to eq(hover_pointer? ? "0" : "1")

    score_line.hover
    expect(score_line.style("opacity")["opacity"]).to eq("1")
    within(score_line) { find('button[aria-label="Upvote"]').click }

    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 1", visible: :all)
    expect_item_order(second_item, first_item)

    score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score", visible: :all)
    score_line.hover
    expect(score_line).to have_css('button[aria-label="Remove upvote"][aria-pressed="true"]')
    within(score_line) { find('button[aria-label="Downvote"]').click }

    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: -1", visible: :all)
    expect_item_order(first_item, second_item)

    score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score", visible: :all)
    score_line.hover
    within(score_line) { find('button[aria-label="Remove downvote"]').click }

    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 0", visible: :all)
    expect(second_item.emoji_reactions).to be_empty
  end

  it "reveals score buttons when reached by keyboard" do
    login_as viewer
    visit project_meeting_path(project, meeting)

    find("#meeting-agenda-item-#{second_item.id} [data-test-selector='op-meeting-agenda-actions']").send_keys(:tab)

    score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score")
    expect(score_line.style("opacity")["opacity"]).to eq("1")
    expect(score_line).to have_css('button[aria-label="Upvote"]:focus')
  end

  context "as an anonymous visitor of a public project", with_settings: { login_required: false } do
    before do
      project.update!(public: true)
      create(:anonymous_role, permissions: %i[view_project view_meetings])
      second_item.emoji_reactions.create!(user: viewer, reaction: :thumbs_up)
    end

    it "shows vote counts without voting controls" do
      visit project_meeting_path(project, meeting)

      expect_item_order(second_item, first_item)
      expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 1", visible: :all)
      expect(page).to have_no_css(".op-meeting-agenda-item-vote-score button", visible: :all)

      within("#meeting-agenda-item-#{second_item.id}") do
        find('[data-test-selector="op-meeting-agenda-actions"]').click
      end
      expect(page).to have_selector(:menuitem, text: "Copy link to clipboard")
      expect(page).to have_no_selector(:menuitem, text: "Upvote")
      expect(page).to have_no_selector(:menuitem, text: "Downvote")
    end
  end

  context "on a mobile screen" do
    include_context "with mobile screen size", 400, 900

    it "keeps vote counts visible and supports voting through the action menu" do
      login_as viewer
      visit project_meeting_path(project, meeting)

      score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score")
      expect(score_line.style("opacity")["opacity"]).to eq("1")
      expect(score_line).to have_text("Votes: 0")
      expect(score_line).to have_no_button

      vote_on_item(second_item, "👍 Upvote")
      expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 1")
      expect_item_order(second_item, first_item)

      vote_on_item(second_item, "👎 Downvote")
      expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: -1")
      expect_item_order(first_item, second_item)
    end
  end
end
