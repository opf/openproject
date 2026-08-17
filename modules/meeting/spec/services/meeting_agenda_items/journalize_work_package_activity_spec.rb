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

RSpec.describe "Journalizing work package meeting activity", type: :model do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_meetings create_meetings manage_agendas manage_outcomes
                                                    add_work_packages view_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:, author: user) }
  shared_let(:meeting) { create(:meeting, project:, author: user) }

  before { login_as(user) }

  describe "adding a work package to a meeting" do
    subject(:service_call) do
      MeetingAgendaItems::CreateService
        .new(user:)
        .call(meeting_id: meeting.id, work_package_id: work_package.id, item_type: "work_package")
    end

    it "records a cause-only journal on the work package" do
      expect { service_call }.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_added")
      expect(journal.cause_meeting_id).to eq(meeting.id)
      expect(journal.get_changes.keys).to eq(["cause"])
    end

    context "for a simple (non work package) agenda item" do
      subject(:service_call) do
        MeetingAgendaItems::CreateService
          .new(user:)
          .call(meeting_id: meeting.id, title: "Just text", item_type: "simple")
      end

      it "does not journalize any work package" do
        expect { service_call }.not_to change(Journal.for_work_package, :count)
      end
    end
  end

  describe "removing a work package from a meeting" do
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:, author: user) }

    subject(:service_call) { MeetingAgendaItems::DeleteService.new(user:, model: agenda_item).call }

    it "records a cause-only journal on the work package" do
      expect { service_call }.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_removed")
      expect(journal.cause_meeting_id).to eq(meeting.id)
    end
  end

  describe "moving a work package to another meeting" do
    shared_let(:other_meeting) { create(:meeting, project:, author: user) }
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:, author: user) }

    it "records a cause-only journal referencing the destination meeting" do
      expect do
        MeetingAgendaItems::UpdateService
          .new(user:, model: agenda_item)
          .call(meeting_id: other_meeting.id, meeting_section: nil)
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_moved")
      expect(journal.cause_meeting_id).to eq(other_meeting.id)
    end

    it "does not journalize an update that leaves the meeting unchanged" do
      expect do
        MeetingAgendaItems::UpdateService
          .new(user:, model: agenda_item)
          .call(notes: "edited")
      end.not_to change { work_package.journals.reload.count }
    end
  end

  describe "moving a work package across a recurring series via drag-and-drop" do
    shared_let(:recurring_meeting) { create(:recurring_meeting, project:) }
    shared_let(:occurrence) { create(:recurring_meeting_occurrence, project:, recurring_meeting:) }
    shared_let(:occurrence_section) { create(:meeting_section, meeting: occurrence) }
    let!(:agenda_item) do
      create(:wp_meeting_agenda_item, meeting: occurrence, meeting_section: occurrence_section, work_package:, author: user)
    end

    it "records a cause-only journal referencing the destination meeting" do
      expect do
        MeetingAgendaItems::DropService
          .new(user:, meeting_agenda_item: agenda_item)
          .call(target_id: occurrence.backlog.id, position: 1)
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_moved")
      expect(journal.cause_meeting_id).to eq(recurring_meeting.template.id)
      expect(journal.cause_source_meeting_id).to eq(occurrence.id)
    end
  end

  describe "adding a work package to a recurring series template" do
    shared_let(:recurring_meeting) { create(:recurring_meeting, project:) }

    it "records a cause-only journal referencing the template" do
      expect do
        MeetingAgendaItems::CreateService
          .new(user:)
          .call(meeting_id: recurring_meeting.template.id, work_package_id: work_package.id, item_type: "work_package")
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_added")
      expect(journal.cause_meeting_id).to eq(recurring_meeting.template.id)
    end
  end

  describe "creating an occurrence from a series template with a work package" do
    shared_let(:recurring_meeting) do
      create(:recurring_meeting,
             project:,
             start_time: Time.zone.tomorrow + 10.hours,
             frequency: "daily",
             interval: 1,
             end_after: "specific_date",
             end_date: 1.month.from_now)
    end

    before do
      create(:wp_meeting_agenda_item,
             meeting: recurring_meeting.template,
             meeting_section: recurring_meeting.template.sections.first,
             work_package:,
             author: user)
    end

    it "records an 'added' journal referencing the new occurrence" do
      result = nil
      expect do
        result = RecurringMeetings::InitOccurrenceService
          .new(user: User.system, recurring_meeting:)
          .call(start_time: recurring_meeting.start_time + 3.days)
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_added")
      expect(journal.cause_meeting_id).to eq(result.result.id)
    end
  end

  describe "converting a simple agenda item into a work package" do
    shared_let(:status) { create(:default_status) }
    shared_let(:priority) { create(:default_priority) }
    let!(:agenda_item) { create(:meeting_agenda_item, meeting:, author: user, title: "Discuss the roadmap") }

    it "records an 'added' journal on the newly created work package" do
      result = MeetingAgendaItems::ConvertToWorkPackageService
        .new(user:, project:)
        .call(meeting_agenda_item: agenda_item,
              work_package_params: { subject: "Discuss the roadmap", type: project.enabled_types.first })

      expect(result).to be_success
      journal = result.result.journals.reload.last
      expect(journal.cause_type).to eq("meeting_agenda_item_added")
      expect(journal.cause_meeting_id).to eq(meeting.id)
    end
  end

  describe "duplicating a meeting that contains a work package" do
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:, author: user) }

    it "records an 'added' journal on the work package referencing the copied meeting" do
      copy = nil
      expect do
        copy = Meetings::CopyService.new(user:, model: meeting).call(copy_agenda: true).result
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_added")
      expect(journal.cause_meeting_id).to eq(copy.id)
    end
  end

  describe "deleting a section that contains a work package" do
    shared_let(:section) { create(:meeting_section, meeting:) }
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, meeting_section: section, work_package:, author: user) }

    it "records a 'removed' journal on the work package" do
      expect do
        MeetingSections::DeleteService.new(user:, model: section).call
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_removed")
      expect(journal.cause_meeting_id).to eq(meeting.id)
    end
  end

  describe "visibility of the recorded journals" do
    let(:added_journal) do
      MeetingAgendaItems::CreateService
        .new(user:)
        .call(meeting_id: meeting.id, work_package_id: work_package.id, item_type: "work_package")
      work_package.journals.reload.last
    end
    let(:initial_journal) { work_package.journals.first }

    it "is visible to a user who can see the meeting" do
      expect(work_package.journals.meeting_cause_visible(user)).to include(added_journal)
    end

    it "is hidden from a user who cannot see the meeting" do
      other_user = create(:user, member_with_permissions: { project => %i[view_work_packages] })
      expect(work_package.journals.meeting_cause_visible(other_user)).not_to include(added_journal)
    end

    it "does not hide ordinary journals from anyone" do
      other_user = create(:user, member_with_permissions: { project => %i[view_work_packages] })
      expect(work_package.journals.meeting_cause_visible(other_user)).to include(initial_journal)
    end

    it "keeps the entry for everyone once the meeting is deleted and its project is unknown" do
      added_journal
      other_user = create(:user, member_with_permissions: { project => %i[view_work_packages] })
      meeting.destroy

      expect(work_package.journals.meeting_cause_visible(other_user)).to include(added_journal)
    end

    describe "the without_meeting_causes scope" do
      it "drops meeting cause journals entirely, regardless of meeting access" do
        expect(work_package.journals.without_meeting_causes).not_to include(added_journal)
      end

      it "keeps ordinary journals" do
        expect(work_package.journals.without_meeting_causes).to include(initial_journal)
      end
    end

    describe "#meeting_cause?" do
      it "is true for a meeting cause journal and false for an ordinary one" do
        expect(added_journal.meeting_cause?).to be(true)
        expect(initial_journal.meeting_cause?).to be(false)
      end
    end
  end

  describe "notifications" do
    shared_let(:recipient) do
      create(:user, member_with_permissions: { project => %i[view_work_packages view_meetings] })
    end

    before do
      work_package.update_columns(assigned_to_id: recipient.id)
      Watcher.new(watchable: work_package, user: recipient).save(validate: false)
    end

    it "does not notify the assignee/watcher when a work package is added to a meeting" do
      expect do
        perform_enqueued_jobs do
          MeetingAgendaItems::CreateService
            .new(user:)
            .call(meeting_id: meeting.id, work_package_id: work_package.id, item_type: "work_package")
        end
      end.not_to change { Notification.where(recipient:).count }
    end

    it "does not notify the assignee/watcher when a work package is removed from a meeting" do
      agenda_item = create(:wp_meeting_agenda_item, meeting:, work_package:, author: user)

      expect do
        perform_enqueued_jobs do
          MeetingAgendaItems::DeleteService.new(user:, model: agenda_item).call
        end
      end.not_to change { Notification.where(recipient:).count }
    end
  end

  describe "recording an outcome on a work package agenda item" do
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:, author: user) }

    before { agenda_item.meeting.update_column(:state, :in_progress) }

    it "records a 'discussed' cause-only journal on the discussed work package" do
      expect do
        MeetingOutcomes::CreateService
          .new(user:)
          .call(meeting_agenda_item: agenda_item, kind: :information, notes: "We decided to proceed")
      end.to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      expect(journal.cause_type).to eq("meeting_agenda_item_discussed")
      expect(journal.cause_meeting_id).to eq(meeting.id)
    end

    context "when the outcome references a different work package" do
      shared_let(:outcome_work_package) { create(:work_package, project:, author: user) }

      it "journalizes both work packages with their differing causes" do
        expect do
          MeetingOutcomes::CreateService
            .new(user:)
            .call(meeting_agenda_item: agenda_item, kind: :work_package, work_package_id: outcome_work_package.id)
        end.to change { work_package.journals.reload.count }.by(1)
          .and change { outcome_work_package.journals.reload.count }.by(1)

        expect(work_package.journals.last.cause_type).to eq("meeting_agenda_item_discussed")
        expect(work_package.journals.last.cause_meeting_id).to eq(meeting.id)

        expect(outcome_work_package.journals.last.cause_type).to eq("meeting_outcome_recorded")
        expect(outcome_work_package.journals.last.cause_meeting_id).to eq(meeting.id)
      end
    end

    context "for a non work package agenda item with a work package outcome" do
      let!(:agenda_item) { create(:meeting_agenda_item, meeting:, author: user) }

      shared_let(:outcome_work_package) { create(:work_package, project:, author: user) }

      it "journalizes only the outcome work package" do
        expect do
          MeetingOutcomes::CreateService
            .new(user:)
            .call(meeting_agenda_item: agenda_item, kind: :work_package, work_package_id: outcome_work_package.id)
        end.to change { outcome_work_package.journals.reload.count }.by(1)
          .and change { work_package.journals.reload.count }.by(0)

        expect(outcome_work_package.journals.last.cause_type).to eq("meeting_outcome_recorded")
      end
    end
  end
end
