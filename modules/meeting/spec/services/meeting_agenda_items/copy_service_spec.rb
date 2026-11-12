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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe MeetingAgendaItems::CopyService do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas view_work_packages] })
  end
  shared_let(:source_meeting) { create(:meeting, project:) }
  shared_let(:target_meeting) { create(:meeting, project:) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:agenda_item) { create(:meeting_agenda_item, meeting: source_meeting, title: "Budget", notes: "Item notes") }
  let!(:information_outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, notes: "Noted") }
  let!(:decision_outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, kind: :decision, notes: "Agreed") }
  let!(:work_package_outcome) do
    create(:meeting_outcome, meeting_agenda_item: agenda_item, kind: :work_package, work_package:, notes: nil)
  end
  let(:include_outcomes) { false }
  let(:copy) { service_call.result }

  subject(:service_call) do
    described_class
      .new(user:, model: agenda_item)
      .call(include_outcomes:, attributes: { meeting_id: target_meeting.id })
  end

  it "copies the agenda item into the target meeting" do
    expect(service_call).to be_success
    expect(copy).not_to eq(agenda_item)
    expect(copy).to have_attributes(meeting: target_meeting, title: "Budget", notes: "Item notes", author: user)
  end

  it "does not copy the outcomes" do
    expect(copy.outcomes).to be_empty
  end

  context "when agenda item has attachments referenced in notes" do
    let!(:attachment) do
      create(:attachment, container: source_meeting, filename: "test.png", author: user)
    end
    let(:agenda_item) do
      create(:meeting_agenda_item,
             meeting: source_meeting,
             notes: "Here is an image: ![test](/api/v3/attachments/#{attachment.id}/content)")
    end

    it "copies the attachment to the new meeting" do
      expect { service_call }.to change { target_meeting.attachments.count }.by(1)
    end

    it "updates the notes to reference the new attachment" do
      service_call
      created_item = service_call.result

      new_attachment = Attachment.last

      expect(created_item.notes).not_to include("/api/v3/attachments/#{attachment.id}/content")
      expect(created_item.notes).to include("/api/v3/attachments/#{new_attachment.id}/content")
    end

    it "journals the new meeting with the copied attachment and the rewritten notes" do
      created_item = service_call.result
      new_attachment = target_meeting.attachments.sole
      journal = target_meeting.journals.last

      expect(journal.attachable_journals.pluck(:attachment_id)).to contain_exactly(new_attachment.id)
      expect(journal.agenda_item_journals.find_by(agenda_item_id: created_item.id).notes)
        .to include("/api/v3/attachments/#{new_attachment.id}/content")
    end
  end

  context "when agenda item has no attachments" do
    it "does not create any attachments" do
      expect { service_call }.not_to change(Attachment, :count)
    end
  end

  context "when including outcomes" do
    let(:include_outcomes) { true }

    it "copies the outcomes as new records" do
      expect(copy.outcomes.map { [it.kind, it.notes, it.work_package, it.author] })
        .to eq([["information", "Noted", nil, user],
                ["decision", "Agreed", nil, user],
                ["work_package", nil, work_package, user]])
      expect(copy.outcomes.ids).not_to include(*agenda_item.outcomes.ids)
    end

    it "keeps the original outcomes" do
      expect { service_call }.not_to change { agenda_item.outcomes.reload.map(&:attributes) }
    end

    it "journals the copied outcomes on the target meeting" do
      copied_outcome_ids = copy.outcomes.ids

      expect(target_meeting.journals.last.outcome_journals.pluck(:outcome_id)).to match_array(copied_outcome_ids)
    end

    context "when an outcome's work package was deleted" do
      before do
        work_package_outcome.update_column(:work_package_id, nil)
      end

      it "skips that outcome" do
        expect(copy.outcomes.map(&:notes)).to eq(%w[Noted Agreed])
      end
    end

    context "when an outcome references an attachment of the source meeting" do
      let!(:attachment) { create(:attachment, container: source_meeting, author: user) }
      let!(:information_outcome) do
        create(:meeting_outcome,
               meeting_agenda_item: agenda_item,
               notes: "See ![image](/api/v3/attachments/#{attachment.id}/content)")
      end

      it "copies the attachment into the target meeting and references it" do
        copied_notes = copy.outcomes.first.notes
        copied_attachment = target_meeting.attachments.sole

        expect(copied_notes).to eq("See ![image](/api/v3/attachments/#{copied_attachment.id}/content)")
      end
    end
  end
end
