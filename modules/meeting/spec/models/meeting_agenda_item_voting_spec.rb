# frozen_string_literal: true

require "spec_helper"

RSpec.describe MeetingAgendaItem, "voting" do
  shared_let(:user) { create(:user) }
  let(:meeting) { create(:meeting, agenda_sorting_mode: :vote_based) }
  let!(:first_section) { create(:meeting_section, meeting:) }
  let!(:second_section) { create(:meeting_section, meeting:) }
  let!(:first_item) { create(:meeting_agenda_item, meeting:, meeting_section: first_section) }
  let!(:second_item) { create(:meeting_agenda_item, meeting:, meeting_section: first_section) }
  let!(:third_item) { create(:meeting_agenda_item, meeting:, meeting_section: first_section) }
  let!(:other_section_item) { create(:meeting_agenda_item, meeting:, meeting_section: second_section) }

  it "sorts by net score within manually ordered sections, including negative scores" do
    first_item.emoji_reactions.create!(user:, reaction: :thumbs_down)
    third_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    other_section_item.emoji_reactions.create!(user:, reaction: :thumbs_up)

    expect(first_section.ordered_agenda_items).to eq([third_item, second_item, first_item])
    expect(meeting.ordered_agenda_items).to eq([third_item, second_item, first_item, other_section_item])
    expect(meeting.sections).to eq([first_section, second_section])
  end

  it "uses manual positions to resolve ties" do
    first_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    second_item.emoji_reactions.create!(user:, reaction: :thumbs_up)

    expect(first_section.ordered_agenda_items).to eq([first_item, second_item, third_item])
  end

  it "restores manual ordering and retains votes when switching modes" do
    third_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    expect(first_section.ordered_agenda_items.first).to eq(third_item)

    meeting.update!(agenda_sorting_mode: :manual)

    expect(first_section.ordered_agenda_items).to eq([first_item, second_item, third_item])
    expect(third_item.reload.vote_score).to eq(1)

    meeting.update!(agenda_sorting_mode: :vote_based)
    expect(first_section.ordered_agenda_items.first).to eq(third_item)
  end

  it "keeps backlogs manual and excludes them from the meeting agenda" do
    backlog_item = create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog)

    expect(meeting.backlog.ordered_agenda_items).to eq([backlog_item])
    expect(meeting.ordered_agenda_items).not_to include(backlog_item)
  end

  it "rejects other emojis at the model level" do
    reaction = first_item.emoji_reactions.build(user:, reaction: :heart)

    expect(reaction).not_to be_valid
    expect(reaction.errors[:reaction]).to be_present
  end

  it "allows only one vote per user on an agenda item" do
    first_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    second_vote = first_item.emoji_reactions.build(user:, reaction: :thumbs_down)

    expect(second_vote).not_to be_valid
    expect(second_vote.errors[:user_id]).to be_present

    expect do
      EmojiReaction.transaction(requires_new: true) { second_vote.save!(validate: false) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects non-vote reactions at the database level" do
    reaction = first_item.emoji_reactions.build(user:, reaction: :heart)

    expect do
      EmojiReaction.transaction(requires_new: true) { reaction.save!(validate: false) }
    end.to raise_error(ActiveRecord::StatementInvalid, /emoji_reactions_agenda_item_votes/)
  end

  it "removes votes with the agenda item" do
    reaction = first_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    first_item.destroy!

    expect(EmojiReaction.exists?(reaction.id)).to be(false)
  end

  it "retains votes when moving between sections" do
    first_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    first_item.update!(meeting_section: second_section)

    expect(first_item.reload.vote_score).to eq(1)
  end

  it "resets votes when moving to another meeting" do
    first_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    destination = create(:meeting_section)
    first_item.update!(meeting_section: destination)

    expect(first_item.reload.vote_score).to eq(0)
    expect(first_item.meeting).to eq(destination.meeting)
  end

  it "copies the sorting mode without copying votes" do
    first_item.emoji_reactions.create!(user:, reaction: :thumbs_up)
    admin = create(:admin)

    call = Meetings::CopyService.new(user: admin, model: meeting).call

    expect(call).to be_success
    expect(call.result).to be_agenda_sorting_vote_based
    expect(call.result.ordered_agenda_items.map(&:vote_score)).to eq([0, 0, 0, 0])
    expect(first_item.reload.vote_score).to eq(1)
  end
end
