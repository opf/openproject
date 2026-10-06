# frozen_string_literal: true

require "spec_helper"

RSpec.describe MeetingAgendaItems::VoteService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based) }
  let(:agenda_item) { create(:meeting_agenda_item, meeting:) }
  let(:reaction) { "thumbs_up" }

  subject(:service_call) { described_class.new(user:, meeting_agenda_item: agenda_item).call(reaction:) }

  it "allows a viewer to vote without managing agendas" do
    expect(service_call).to be_success
    expect(agenda_item.emoji_reactions.pluck(:user_id, :reaction)).to eq([[user.id, "thumbs_up"]])
    expect(agenda_item.reload.vote_score).to eq(1)
  end

  it "removes an existing vote when selected again" do
    agenda_item.emoji_reactions.create!(user:, reaction:)

    expect(service_call).to be_success
    expect(agenda_item.emoji_reactions).to be_empty
    expect(agenda_item.reload.vote_score).to eq(0)
  end

  it "switches an existing vote to the opposite reaction" do
    agenda_item.emoji_reactions.create!(user:, reaction: :thumbs_down)

    expect(service_call).to be_success
    expect(agenda_item.emoji_reactions.pluck(:reaction)).to eq(["thumbs_up"])
    expect(agenda_item.reload.vote_score).to eq(1)
  end

  it "leaves other users' votes unchanged" do
    other_user = create(:user)
    other_vote = agenda_item.emoji_reactions.create!(user: other_user, reaction: :thumbs_down)

    expect(service_call).to be_success
    expect(other_vote.reload.reaction).to eq("thumbs_down")
    expect(agenda_item.reload.vote_score).to eq(0)
  end

  it "changes polling without editing the agenda item or its manual position" do
    agenda_item
    original_updated_at = agenda_item.updated_at
    original_position = agenda_item.position
    original_hash = meeting.changed_hash

    expect(service_call).to be_success
    expect(meeting.reload.changed_hash).not_to eq(original_hash)
    expect(agenda_item.reload.updated_at).to eq(original_updated_at)
    expect(agenda_item.position).to eq(original_position)
  end

  it "changes polling when the final vote is removed" do
    travel_to Time.current.change(usec: 0) do
      agenda_item.emoji_reactions.create!(user:, reaction:)
      original_hash = meeting.changed_hash
      travel 1.second

      expect(service_call).to be_success
      expect(meeting.reload.changed_hash).not_to eq(original_hash)
    end
  end

  context "with a downvote" do
    let(:reaction) { "thumbs_down" }

    it "records a negative score" do
      expect(service_call).to be_success
      expect(agenda_item.reload.vote_score).to eq(-1)
    end
  end

  context "with a symbol reaction" do
    let(:reaction) { :thumbs_up }

    it "records the vote" do
      expect(service_call).to be_success
      expect(agenda_item.reload.vote_score).to eq(1)
    end
  end

  %i[draft in_progress].each do |state|
    context "when the meeting is #{state}" do
      let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based, state:) }

      it "allows voting" do
        expect(service_call).to be_success
        expect(agenda_item.reload.vote_score).to eq(1)
      end
    end
  end

  context "with another emoji" do
    let(:reaction) { "heart" }

    it "rejects the reaction without replacing an existing vote" do
      agenda_item.emoji_reactions.create!(user:, reaction: :thumbs_up)

      expect(service_call).to be_failure
      expect(agenda_item.emoji_reactions.pluck(:reaction)).to eq(["thumbs_up"])
    end
  end

  context "without view permission" do
    let(:user) { create(:user) }

    it "rejects voting" do
      expect(service_call).to be_failure
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end

  context "with manual sorting" do
    let(:meeting) { create(:meeting, project:) }

    it "rejects voting" do
      expect(service_call).to be_failure
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end

  context "with a stale meeting instance" do
    it "checks the current persisted sorting mode" do
      agenda_item
      Meeting.find(meeting.id).update!(agenda_sorting_mode: :manual)

      expect(service_call).to be_failure
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end

  context "when the item is moved to another meeting before voting" do
    it "rejects voting even when the user can view both meetings" do
      service = described_class.new(user:, meeting_agenda_item: agenda_item)
      other_meeting = create(:meeting, project:, agenda_sorting_mode: :vote_based)
      other_section = create(:meeting_section, meeting: other_meeting)
      MeetingAgendaItem.find(agenda_item.id).update!(meeting_section: other_section)

      result = service.call(reaction:)

      expect(result).to be_failure
      expect(result.errors).to be_of_kind(:base, :error_unauthorized)
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end

  it "rolls back replacing a vote when persisting the new reaction fails" do
    existing_vote = agenda_item.emoji_reactions.create!(user:, reaction: :thumbs_down)
    invalid_vote = agenda_item.emoji_reactions.build(user:, reaction:)
    invalid_vote.errors.add :reaction, :invalid
    reactions = agenda_item.emoji_reactions
    allow(agenda_item).to receive(:emoji_reactions).and_return(reactions)
    allow(reactions).to receive(:build).with(user:, reaction:).and_return(invalid_vote)
    allow(invalid_vote).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(invalid_vote))

    expect(service_call).to be_failure
    expect(EmojiReaction.find(existing_vote.id).reaction).to eq("thumbs_down")
  end

  context "with a backlog item" do
    let(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog) }

    it "rejects voting" do
      expect(service_call).to be_failure
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end

  %i[closed cancelled].each do |state|
    context "when the meeting is #{state}" do
      let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based, state:) }

      it "rejects voting" do
        expect(service_call).to be_failure
        expect(agenda_item.emoji_reactions).to be_empty
      end
    end
  end

  context "with a template" do
    let(:meeting) { create(:onetime_template, project:, agenda_sorting_mode: :vote_based) }

    it "rejects voting" do
      expect(service_call).to be_failure
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end
end
