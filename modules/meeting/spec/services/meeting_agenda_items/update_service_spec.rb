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

RSpec.describe MeetingAgendaItems::UpdateService do
  let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] }) }
  let(:project) { create(:project) }
  let(:meeting_a) { create(:meeting, project:) }
  let(:meeting_b) { create(:meeting, project:) }
  let(:agenda_item) { create(:meeting_agenda_item, meeting: meeting_a) }

  subject(:service_call) { described_class.new(user:, model: agenda_item).call(params) }

  describe "moving agenda item to a different meeting" do
    context "when agenda item has attachments referenced in notes" do
      let!(:attachment) do
        create(:attachment, container: meeting_a, filename: "test.png", author: user)
      end
      let(:params) do
        {
          meeting_id: meeting_b.id,
          meeting_section: nil
        }
      end
      let(:initial_notes) { "Here is an image: ![test](/api/v3/attachments/#{attachment.id}/content)" }

      before do
        agenda_item.update_column(:notes, initial_notes)
      end

      it "copies the attachment to the new meeting" do
        expect { service_call }.to change { meeting_b.attachments.count }.by(1)
      end

      it "updates the notes to reference the new attachment" do
        service_call
        agenda_item.reload

        new_attachment = Attachment.last

        expect(agenda_item.notes).not_to include("/api/v3/attachments/#{attachment.id}/content")
        expect(agenda_item.notes).to include("/api/v3/attachments/#{new_attachment.id}/content")
      end
    end

    context "when agenda item has no attachments" do
      let(:params) { { meeting_id: meeting_b.id, meeting_section: nil } }

      before do
        agenda_item.update_column(:notes, "Just text")
      end

      it "does not create any attachments" do
        expect { service_call }.not_to change(Attachment, :count)
      end
    end

    context "when meeting does not change" do
      let!(:attachment) do
        create(:attachment, container: meeting_a, filename: "test.png", author: user)
      end
      let(:params) { { title: "Updated title" } }

      before do
        agenda_item.update_column(:notes, "Here is an image: ![test](/api/v3/attachments/#{attachment.id}/content)")
      end

      it "does not copy attachments" do
        expect { service_call }.not_to change(Attachment, :count)
      end
    end
  end
end
