# frozen_string_literal: true

require "spec_helper"

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

  def expect_item_order(*items)
    expect(page).to have_css(".op-meeting-agenda-item-wrapper", count: items.size)
    expect(all(".op-meeting-agenda-item-wrapper").map { |element| element[:id] })
      .to eq(items.map { |item| "meeting-agenda-item-#{item.id}" })
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

    set_sorting_mode("Manual")
    expect_item_order(first_item, second_item)
    expect(page).to have_no_text("Votes:")
    expect(second_item.reload.vote_score).to eq(1)
    expect(first_item.reload.position).to eq(1)
    expect(second_item.position).to eq(2)
  end

  it "reveals score buttons on hover and supports switching and removing votes" do
    login_as viewer
    visit project_meeting_path(project, meeting)

    find(".meeting-infoline").hover
    score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score", visible: :all)
    expect(score_line.style("opacity")["opacity"]).to eq("0")

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

  it "keeps votes and buttons visible on mobile without hovering" do
    login_as viewer
    original_size = page.current_window.size
    page.current_window.resize_to(400, 900)
    visit project_meeting_path(project, meeting)

    score_line = find("#meeting-agenda-item-#{second_item.id} .op-meeting-agenda-item-vote-score")
    expect(score_line.style("opacity")["opacity"]).to eq("1")
    expect(score_line).to have_text("Votes: 0")
    within(score_line) { find('button[aria-label="Upvote"]').click }
    expect(page).to have_css("#meeting-agenda-item-#{second_item.id}", text: "Votes: 1")
  ensure
    page.current_window.resize_to(*original_size)
  end
end
