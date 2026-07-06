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

RSpec.describe Meeting do
  shared_let (:user) { create(:user) }
  current_user { user }

  let!(:meeting) do
    User.execute_as current_user do
      create(:meeting, author: user)
    end
  end

  describe "#journal" do
    context "for meeting creation" do
      it { expect(Journal.for_meeting.count).to eq(1) }

      it "has a journal entry" do
        expect(Journal.for_meeting.first.journable).to eq(meeting)
      end

      it "notes the changes to title" do
        expect(meeting.last_journal.details[:title])
          .to contain_exactly(nil, meeting.title)
      end

      it "notes the changes to project" do
        expect(meeting.last_journal.details[:project_id])
          .to contain_exactly(nil, meeting.project_id)
      end

      it "notes the location" do
        expect(meeting.last_journal.details[:location])
          .to contain_exactly(nil, meeting.location)
      end

      it "notes the start time" do
        expect(meeting.last_journal.details[:start_time])
          .to contain_exactly(nil, meeting.start_time)
      end

      it "notes the duration" do
        expect(meeting.last_journal.details[:duration])
          .to contain_exactly(nil, meeting.duration)
      end

      it "has the timestamp of the meeting update time for created_at" do
        expect(meeting.last_journal.created_at)
          .to eql(meeting.reload.updated_at)
      end

      it "has the updated_at of the meeting as the lower bound for validity_period and no upper bound" do
        expect(meeting.last_journal.validity_period)
          .to eql(meeting.reload.updated_at...)
      end
    end

    context "when nothing is changed" do
      it { expect { meeting.save! }.not_to change(Journal, :count) }

      it "does not update the updated_at time of the work package" do
        expect { meeting.save! }.not_to change(meeting, :updated_at)
      end
    end

    describe "agenda_items" do
      let(:work_package) { nil }
      let(:agenda_item_attributes) { {} }
      let(:agenda_item) { meeting.agenda_items.first }
      let(:agenda_item_journals) { meeting.journals.last.agenda_item_journals }

      before do
        meeting.agenda_items << create(:meeting_agenda_item, meeting:, work_package:, **agenda_item_attributes)
        meeting.save
      end

      context "for a new agenda item within aggregation time" do
        it { expect(meeting.journals.count).to eq(1) }
        it { expect(agenda_item_journals.count).to eq(1) }

        it {
          expect(agenda_item_journals.last).to have_attributes agenda_item.attributes.slice(
            "author_id", "title", "notes", "position", "duration_in_minutes",
            "start_time", "end_time", "work_package_id", "item_type"
          )
        }
      end

      context "for a new agenda item outside aggregation time", with_settings: { journal_aggregation_time_minutes: 0 } do
        it { expect(meeting.journals.count).to eq(2) }
        it { expect(meeting.journals.first.agenda_item_journals).to be_empty }
        it { expect(agenda_item_journals.count).to eq(1) }

        it {
          expect(agenda_item_journals.last).to have_attributes agenda_item.attributes.slice(
            "author_id", "title", "notes", "position", "duration_in_minutes",
            "start_time", "end_time", "work_package_id", "item_type"
          )
        }
      end

      context "when agenda item saved w/o change" do
        it {
          expect do
            agenda_item.save
            meeting.save_journals
          end.not_to change(Journal, :count)
        }
      end

      Journal::MeetingAgendaItemJournal.columns_hash.slice(
        "notes", "position", "duration_in_minutes", "work_package_id", "item_type"
      ).each do |column_name, column_info|
        column_value =
          if column_name == "item_type" then "work_package"
          elsif column_info.type == :integer then 11
          else "A string"
          end

        if column_name == "item_type"
          # When testing the work_package item_type, a work_package is required.
          let(:work_package) { create(:work_package) }
        end

        context "when updating an agenda_item within the aggregation time" do
          shared_examples "it updates the existing journals" do
            subject(:update_agenda_item) do
              agenda_item.update(column_name => updated_value)
              meeting.save_journals
            end

            it { expect { update_agenda_item }.not_to change(Journal, :count) }

            it "updates the agenda item journal" do
              expect { update_agenda_item }
                 .to change { agenda_item_journals.last.send(column_name) }
                 .to(updated_value)
            end
          end

          describe "setting a value for the #{column_name} column" do
            it_behaves_like "it updates the existing journals" do
              let(:updated_value) { column_value }
            end
          end

          describe "unsetting a value for the #{column_name} column" do
            let(:agenda_item_attributes) { { column_name => column_value } }

            it_behaves_like "it updates the existing journals" do
              let(:updated_value) { nil }
            end
          end
        end

        context "when updating an agenda_item outside the aggregation time",
                with_settings: { journal_aggregation_time_minutes: 0 } do
          shared_examples "creates a new journal and keeps old journal intact" do
            subject(:update_agenda_item) do
              agenda_item.update(column_name => updated_value)
              meeting.save_journals
            end

            it { expect { update_agenda_item }.to change(Journal, :count).by(1) }
            it { expect { update_agenda_item }.to change(Journal::MeetingJournal, :count).by(1) }
            it { expect { update_agenda_item }.to change(Journal::MeetingAgendaItemJournal, :count).by(1) }

            it "does not update the previous agenda item journal" do
              previous_journal_agenda_items = agenda_item_journals
              expect { update_agenda_item }
                .not_to change { previous_journal_agenda_items.reload }
            end

            it "updates the new agenda item journal" do
              expect { update_agenda_item }
                .to change { Journal::MeetingAgendaItemJournal.last.send(column_name) }
                .to(updated_value)
            end
          end

          describe "setting a value for the #{column_name} column" do
            it_behaves_like "creates a new journal and keeps old journal intact" do
              let(:updated_value) { column_value }
            end
          end

          describe "unsetting a value for the #{column_name} column" do
            let(:agenda_item_attributes) { { column_name => column_value } }

            it_behaves_like "creates a new journal and keeps old journal intact" do
              let(:updated_value) { nil }
            end
          end
        end
      end

      context "for a removed agenda_item within aggregation time" do
        subject(:remove_agenda_item) do
          agenda_item.destroy
          meeting.save_journals
        end

        it { expect { remove_agenda_item }.not_to change(Journal, :count) }

        it {
          expect { remove_agenda_item }
            .to change { agenda_item_journals.reload.count }
            .from(1)
            .to(0)
        }
      end

      context "for a removed agenda_item outside aggregation time", with_settings: { journal_aggregation_time_minutes: 0 } do
        let(:agenda_item_journals) { meeting.journals.second.agenda_item_journals }

        subject(:remove_agenda_item) do
          agenda_item.destroy
          meeting.save_journals
        end

        it {
          expect { remove_agenda_item }
            .to change { meeting.journals.count }
            .from(2)
            .to(3)
        }

        it {
          expect { remove_agenda_item }
            .not_to change { meeting.journals.first.agenda_item_journals.reload.size }
        }

        it {
          expect { remove_agenda_item }
            .not_to change { agenda_item_journals.reload.count }
        }

        it {
          remove_agenda_item
          expect(agenda_item_journals.last).to have_attributes agenda_item.attributes.slice(
            "author_id", "title", "notes", "position", "duration_in_minutes",
            "start_time", "end_time", "work_package_id"
          )
        }

        it "removes the agenda_item_journals from the new journal" do
          remove_agenda_item
          expect(meeting.journals.last.agenda_item_journals).to be_empty
        end
      end
    end
  end

  describe "participants" do
    shared_let(:participant_user) { create(:user) }

    let(:participant) { meeting.participants.find_by(user: participant_user) }
    let(:participant_journals) { meeting.journals.last.participant_journals }

    before do
      meeting.participants << MeetingParticipant.new(user: participant_user, invited: true, attended: false)
      meeting.touch_and_save_journals
    end

    context "when a participant is added" do
      it "creates a participant journal entry" do
        expect(participant_journals.count).to eq(1)
      end

      it "records the correct user, invited, and attended values" do
        expect(participant_journals.last).to have_attributes(
          user_id: participant_user.id,
          invited: true,
          attended: false
        )
      end
    end

    context "when a participant is removed", with_settings: { journal_aggregation_time_minutes: 0 } do
      subject(:remove_participant) do
        participant.destroy
        meeting.touch_and_save_journals
      end

      it "creates a new journal" do
        expect { remove_participant }.to change { meeting.journals.count }.by(1)
      end

      it "removes the participant journal from the new journal" do
        remove_participant
        expect(meeting.journals.last.participant_journals).to be_empty
      end

      it "keeps the participant journal in the previous journal" do
        remove_participant

        previous_journal = meeting.journals.order(:id).second_to_last
        expect(previous_journal.participant_journals.count).to eq(1)
        expect(previous_journal.participant_journals.first.user_id).to eq(participant_user.id)
      end
    end

    context "when a participant's invited status changes", with_settings: { journal_aggregation_time_minutes: 0 } do
      subject(:update_participant) do
        participant.update!(invited: false)
        meeting.touch_and_save_journals
      end

      it "creates a new journal" do
        expect { update_participant }.to change { meeting.journals.count }.by(1)
      end

      it "reflects the updated invited value in the new journal" do
        update_participant
        expect(meeting.journals.last.participant_journals.last).to have_attributes(invited: false)
      end
    end

    context "when no participant changes occur" do
      it "does not create a new journal" do
        expect do
          meeting.save_journals
        end.not_to change(Journal, :count)
      end
    end

    context "when save_journals is called again within the aggregation window (regression: PG::UniqueViolation)" do
      it "does not raise a unique violation" do
        # Simulates save_journals being called a second time while the first journal is still
        # the aggregation predecessor (e.g., template_completed updates the meeting right after creation)
        meeting.update_column(:title, "Updated title")
        expect { meeting.save_journals }.not_to raise_error
      end

      it "participant journals reflect the current state" do
        meeting.update_column(:title, "Updated title")
        meeting.save_journals
        expect(meeting.journals.last.participant_journals.count).to eq(1)
      end
    end

    context "when persisted participants contain duplicate users",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      before do
        MeetingParticipant.insert_all!(
          [
            {
              meeting_id: meeting.id,
              user_id: participant_user.id,
              invited: false,
              attended: true,
              participation_status: "accepted",
              created_at: Time.current,
              updated_at: Time.current
            }
          ]
        )
      end

      it "deduplicates the participant snapshot by user" do
        meeting.update_column(:title, "Updated title")

        expect { meeting.save_journals }.not_to raise_error

        expect(meeting.journals.last.participant_journals.count).to eq(1)
        expect(meeting.journals.last.participant_journals.last).to have_attributes(
          user_id: participant_user.id,
          invited: false,
          attended: true,
          participation_status: "accepted"
        )
      end
    end
  end

  describe "participant change details" do
    shared_let(:participant505) { create(:user, firstname: "Participant", lastname: "505") }
    shared_let(:participant401) { create(:user, firstname: "Oliver", lastname: "Captchatest") }
    shared_let(:participant502) { create(:user, firstname: "Test", lastname: "Calculated Values") }
    shared_let(:participant328) { create(:user, firstname: "Participant", lastname: "328") }
    shared_let(:participant329) { create(:user, firstname: "Test", lastname: "User 329") }

    let(:details_meeting) do
      User.execute_as current_user do
        create(:meeting, author: user)
      end
    end

    it "computes added and removed participants from previous snapshot in journal order",
       with_settings: { journal_aggregation_time_minutes: 0 } do
      details_meeting.participants << MeetingParticipant.new(user: participant505, invited: true, attended: false)
      details_meeting.touch_and_save_journals

      details_meeting.participants << MeetingParticipant.new(user: participant401, invited: true, attended: false)
      details_meeting.participants << MeetingParticipant.new(user: participant502, invited: true, attended: false)
      details_meeting.touch_and_save_journals

      details_meeting.participants.find_by(user: participant502).destroy!
      details_meeting.participants << MeetingParticipant.new(user: participant328, invited: true, attended: false)
      details_meeting.participants << MeetingParticipant.new(user: participant329, invited: true, attended: false)
      details_meeting.touch_and_save_journals

      details_meeting.participants.find_by(user: participant401).destroy!
      details_meeting.participants.find_by(user: participant329).destroy!
      details_meeting.touch_and_save_journals

      journal = details_meeting.journals.last
      allow(journal).to receive(:predecessor).and_return(details_meeting.journals.first)

      expect(journal.details).to include(
        participants_removed: [nil, "Oliver Captchatest, Test User 329"]
      )
      expect(journal.details[:participants_added]).to be_nil
    end
  end

  describe "#destroy" do
    let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }

    before do
      meeting.agenda_items << meeting_agenda_item
      meeting.save
    end

    let(:journal) { meeting.journals.first }
    let(:agenda_item_journals) { journal.agenda_item_journals }

    subject { meeting.destroy }

    it "removes the journal" do
      expect { subject }
        .to change { Journal.exists?(journal.id) }
        .from(true)
        .to(false)
    end

    it "removes the journal data" do
      expect { subject }
        .to change { Journal::MeetingJournal.exists?(id: journal.data_id) }
        .from(true)
        .to(false)
    end

    it "removes the meeting agenda items journals" do
      expect { subject }
        .to change {
          Journal::MeetingAgendaItemJournal.where(id: agenda_item_journals.map(&:id)).count
        }.by(-1)
    end
  end
end
