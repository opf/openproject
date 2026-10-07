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
    original_updated_at = agenda_item.reload.updated_at
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
      expect(service_call.errors).to be_of_kind(:base, :vote_based_sorting_required)
      expect(agenda_item.emoji_reactions).to be_empty
    end
  end

  context "with a stale meeting instance" do
    it "checks the current persisted sorting mode" do
      agenda_item
      Meeting.find(meeting.id).update!(agenda_sorting_mode: :manual)

      expect(service_call).to be_failure
      expect(service_call.errors).to be_of_kind(:base, :vote_based_sorting_required)
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

  it "keeps the existing vote and returns the errors when saving the new reaction fails" do
    existing_vote = agenda_item.emoji_reactions.create!(user:, reaction: :thumbs_down)
    existing_vote.errors.add :reaction, :invalid
    reactions = agenda_item.emoji_reactions
    allow(agenda_item).to receive(:emoji_reactions).and_return(reactions)
    allow(reactions).to receive(:find_or_initialize_by).with(user:).and_return(existing_vote)
    allow(existing_vote).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(existing_vote))

    expect(service_call).to be_failure
    expect(service_call.errors).to be_of_kind(:reaction, :invalid)
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
