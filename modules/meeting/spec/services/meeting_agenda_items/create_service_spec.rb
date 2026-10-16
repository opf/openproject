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

RSpec.describe MeetingAgendaItems::CreateService do
  shared_let(:project) { create(:project) }
  shared_let(:meeting) { create(:meeting, project:) }

  let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] }) }
  let(:params) { { meeting_id: meeting.id, title: "Budget review", notes: "Review the numbers" } }

  subject(:service_call) { described_class.new(user:).call(params) }

  context "when the user can manage agendas" do
    it "creates the agenda item in the meeting" do
      expect(service_call).to be_success
      expect(service_call.result).to have_attributes(meeting:, title: "Budget review", author: user)
    end

    it "journals the meeting with the new agenda item" do
      agenda_item = service_call.result

      expect(meeting.journals.last.agenda_item_journals.pluck(:agenda_item_id)).to include(agenda_item.id)
    end
  end

  context "when the user cannot manage agendas" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

    it "fails without creating the agenda item" do
      expect { service_call }.not_to change(MeetingAgendaItem, :count)
      expect(service_call.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end
end
