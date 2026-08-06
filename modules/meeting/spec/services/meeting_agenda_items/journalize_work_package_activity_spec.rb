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
    create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas view_work_packages] })
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
end
