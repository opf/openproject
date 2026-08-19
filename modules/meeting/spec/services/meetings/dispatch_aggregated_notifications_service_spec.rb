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

RSpec.describe Meetings::DispatchAggregatedNotificationsService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:actor) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:existing_user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:new_user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:removed_user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

  let(:fixed_start_time) { 1.day.from_now.change(usec: 0) }
  let(:since_journal) { instance_double(Journal, user: actor, data: since_data) }
  let(:latest_journal) { instance_double(Journal, user: actor, data: latest_data) }
  let(:since_data) { instance_double(Journal::MeetingJournal, title: "Old Title", location: nil, start_time: fixed_start_time, duration: 1.0) }
  let(:latest_data) { instance_double(Journal::MeetingJournal, title: "Old Title", location: nil, start_time: fixed_start_time, duration: 1.0) }

  let(:meeting) do
    create(:meeting, project:, author: actor, notify: true)
  end

  let(:since_participant_journals) { class_double(Journal::MeetingParticipantJournal) }
  let(:latest_participant_journals) { class_double(Journal::MeetingParticipantJournal) }
  let(:mail_delivery) { double(deliver_later: nil) }

  before do
    allow(since_journal).to receive(:participant_journals).and_return(since_participant_journals) if since_journal
    allow(latest_journal).to receive(:participant_journals).and_return(latest_participant_journals)
    allow(since_participant_journals).to receive(:where).with(invited: true).and_return(since_participant_journals)
    allow(latest_participant_journals).to receive(:where).with(invited: true).and_return(latest_participant_journals)

    allow(Journal::NotificationConfiguration).to receive(:active?).and_return(true)
    allow(MeetingMailer).to receive_messages(
      invited: mail_delivery,
      cancelled: mail_delivery,
      updated: mail_delivery
    )
    allow(MeetingSeriesMailer).to receive_messages(
      invited: mail_delivery,
      updated: mail_delivery
    )
  end

  subject(:service) do
    described_class.new(meeting:, since_journal:, latest_journal:).call
  end

  def stub_invited_ids(journal_double, user_ids)
    allow(journal_double).to receive(:pluck).with(:user_id).and_return(user_ids)
  end

  context "when a user is added (not previously invited)" do
    before do
      stub_invited_ids(since_participant_journals, [existing_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id, new_user.id])
    end

    it "sends invite to the newly added user" do
      service
      expect(MeetingMailer).to have_received(:invited).with(meeting, new_user, actor)
    end

    it "sends an updated email with the added participant to the existing user" do
      service
      expect(MeetingMailer)
        .to have_received(:updated)
        .with(meeting, existing_user, actor,
              hash_including(added_participants: [new_user.name],
                             removed_participants: []))
    end

    it "does not send an updated email to the newly added user" do
      service
      expect(MeetingMailer).not_to have_received(:updated).with(meeting, new_user, anything, anything)
    end
  end

  context "when a user is removed (was previously invited)" do
    before do
      stub_invited_ids(since_participant_journals, [existing_user.id, removed_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id])
    end

    it "sends cancellation to the removed user" do
      service
      expect(MeetingMailer)
        .to have_received(:cancelled)
        .with(meeting, removed_user, actor)
    end

    it "sends an updated email with the removed participant to the still-invited user" do
      service
      expect(MeetingMailer)
        .to have_received(:updated)
        .with(meeting, existing_user, actor,
              hash_including(added_participants: [],
                             removed_participants: [removed_user.name]))
    end
  end

  context "when a user is added and another is removed in the same window" do
    before do
      stub_invited_ids(since_participant_journals, [existing_user.id, removed_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id, new_user.id])
    end

    it "sends a single updated email with participant changes to the still-invited user" do
      service
      expect(MeetingMailer).to have_received(:updated)
        .with(meeting, existing_user, actor,
              hash_including(added_participants: [new_user.name],
                             removed_participants: [removed_user.name]))
    end
  end

  context "when the same user is added and removed within the window (net zero)" do
    before do
      stub_invited_ids(since_participant_journals, [existing_user.id, removed_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id, removed_user.id])
    end

    it "sends no emails" do
      service
      expect(MeetingMailer).not_to have_received(:invited)
      expect(MeetingMailer).not_to have_received(:cancelled)
      expect(MeetingMailer).not_to have_received(:updated)
    end
  end

  context "when meeting attributes change" do
    let(:new_start_time) { 2.days.from_now }

    before do
      stub_invited_ids(since_participant_journals, [existing_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id])
      allow(since_data).to receive(:start_time).and_return(1.day.from_now)
      allow(latest_data).to receive(:start_time).and_return(new_start_time)
    end

    it "sends updated email to the still-invited user" do
      service
      expect(MeetingMailer)
        .to have_received(:updated)
        .with(meeting, existing_user, actor, hash_including(changes: hash_including(:old_start, :new_start)))
    end
  end

  context "when explicit since_attributes are provided" do
    subject(:service) do
      described_class.new(
        meeting:,
        since_journal: nil,
        latest_journal:,
        since_invited_ids: [existing_user.id],
        since_attributes: { "title" => "Old Title", "start_time" => fixed_start_time.iso8601 }
      ).call
    end

    before do
      stub_invited_ids(latest_participant_journals, [existing_user.id])
      allow(latest_data).to receive(:title).and_return("New Title")
    end

    it "uses them as the baseline for the updated email" do
      service
      expect(MeetingMailer)
        .to have_received(:updated)
        .with(meeting, existing_user, actor,
              hash_including(changes: hash_including(old_title: "Old Title",
                                                     new_title: "New Title")))
    end
  end

  context "when nothing changes" do
    before do
      stub_invited_ids(since_participant_journals, [existing_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id])
    end

    it "sends no emails" do
      service
      expect(MeetingMailer).not_to have_received(:invited)
      expect(MeetingMailer).not_to have_received(:cancelled)
      expect(MeetingMailer).not_to have_received(:updated)
    end
  end

  context "when since_journal is nil" do
    let(:since_journal) { nil }

    before do
      stub_invited_ids(latest_participant_journals, [new_user.id])
    end

    it "treats all latest participants as newly added" do
      service
      expect(MeetingMailer)
        .to have_received(:invited)
        .with(meeting, new_user, actor)
    end
  end

  context "when since_invited_ids is provided explicitly (journal aggregation override)" do
    subject(:service) do
      described_class.new(
        meeting:,
        since_journal: nil,
        latest_journal:,
        since_invited_ids: [existing_user.id]
      ).call
    end

    before do
      stub_invited_ids(latest_participant_journals, [existing_user.id, new_user.id])
    end

    it "sends invite only to the newly added user (not the existing one)" do
      service
      expect(MeetingMailer).to have_received(:invited).with(meeting, new_user, actor)
      expect(MeetingMailer).not_to have_received(:invited).with(meeting, existing_user, anything)
    end

    it "sends an updated email with the added participant to the existing user" do
      service
      expect(MeetingMailer)
        .to have_received(:updated)
        .with(meeting, existing_user, actor,
              hash_including(added_participants: [new_user.name],
                             removed_participants: []))
    end
  end

  context "when meeting is a series template" do
    let(:recurring_meeting) { create(:recurring_meeting, project:, author: actor) }
    let(:meeting) { recurring_meeting.template }

    before do
      allow(meeting).to receive(:send_emails?).and_return(true)
      stub_invited_ids(since_participant_journals, [existing_user.id])
      stub_invited_ids(latest_participant_journals, [existing_user.id, new_user.id])
    end

    it "sends series invite via MeetingSeriesMailer" do
      service
      expect(MeetingSeriesMailer)
        .to have_received(:invited)
        .with(recurring_meeting, new_user, actor)
    end

    it "sends updated via MeetingSeriesMailer with the added participant" do
      service
      expect(MeetingSeriesMailer)
        .to have_received(:updated)
        .with(recurring_meeting, existing_user, actor,
              hash_including(added_participants: [new_user.name],
                             removed_participants: []))
    end

    it "does not send meeting attribute changes via MeetingSeriesMailer" do
      service
      expect(MeetingSeriesMailer)
        .to have_received(:updated)
        .with(recurring_meeting, existing_user, actor,
              hash_including(changes: { old_schedule: recurring_meeting.full_schedule_in_words,
                                        old_location: nil }))
    end
  end

  context "when Journal::NotificationConfiguration is inactive" do
    before do
      allow(Journal::NotificationConfiguration).to receive(:active?).and_return(false)
    end

    it "sends no emails" do
      service
      expect(MeetingMailer).not_to have_received(:invited)
    end
  end

  context "when meeting cannot send emails" do
    before do
      allow(meeting).to receive(:send_emails?).and_return(false)
    end

    it "sends no emails" do
      service
      expect(MeetingMailer).not_to have_received(:invited)
    end
  end
end
