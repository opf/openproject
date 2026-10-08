# frozen_string_literal: true

require "rails_helper"

RSpec.describe MeetingAgendaItems::VoteControlsComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based) }
  let(:item) { create(:meeting_agenda_item, meeting:) }
  let(:voting_enabled) { true }
  let(:component) { described_class.new(meeting_agenda_item: item, voting_enabled:) }

  before { User.current = user }

  it "shows a zero vote count and accessible voting buttons" do
    render_inline(component)

    expect(page).to have_text("Votes: 0")
    expect(page).to have_css('button[aria-label="Upvote"][aria-pressed="false"]', text: "👍")
    expect(page).to have_css('button[aria-label="Downvote"][aria-pressed="false"]', text: "👎")
  end

  it "shows negative votes and the selected action" do
    item.emoji_reactions.create!(user:, reaction: :thumbs_down)
    render_inline(component)

    expect(page).to have_text("Votes: -1")
    expect(page).to have_css('button[aria-label="Remove downvote"][aria-pressed="true"]')
  end

  context "when voting is disabled" do
    let(:voting_enabled) { false }

    it "shows the count without actions" do
      render_inline(component)

      expect(page).to have_text("Votes: 0")
      expect(page).to have_no_button
    end
  end
end
