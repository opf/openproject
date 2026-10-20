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

RSpec.describe MeetingAgendaItems::MoveToNextMeetingService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] }) }
  shared_let(:series) { create(:recurring_meeting, project:, author: user) }

  let(:current_meeting) do
    create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: series.first_occurrence, project:)
  end
  let(:section) { create(:meeting_section, meeting: current_meeting) }
  let(:agenda_item) do
    create(:meeting_agenda_item, meeting: current_meeting, meeting_section: section, title: "Carry over")
  end

  subject(:service_call) { described_class.new(user:, meeting_agenda_item: agenda_item).call }

  def next_slot
    series.next_occurrence(from_time: current_meeting.recurrence_start_time)
  end

  it "materializes the next occurrence and moves the item into it" do
    expect(service_call).to be_success

    target = series.meetings.not_templated.find_by(recurrence_start_time: next_slot)
    expect(target).to be_present

    expect(agenda_item.reload).to have_attributes(
      meeting_id: target.id,
      title: "Carry over"
    )
    expect(agenda_item.meeting_section.meeting_id).to eq(target.id)
  end

  it "reuses an already materialized next occurrence" do
    target = create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: next_slot)

    expect { service_call }.not_to change { series.meetings.not_templated.count }
    expect(agenda_item.reload.meeting_id).to eq(target.id)
  end

  context "when the meeting is not recurring" do
    let(:current_meeting) { create(:meeting, project:, author: user) }

    it "fails without moving the item" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to include(:not_in_recurring_series)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end

  context "when the item belongs to the series template" do
    let(:current_meeting) { series.template }
    let(:section) { create(:meeting_section, meeting: current_meeting) }

    it "fails without moving the item" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to include(:meeting_is_template)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end

  context "when the meeting is closed" do
    before { current_meeting.update!(state: :closed) }

    it "fails without moving the item" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to include(:meeting_closed)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end

  context "when the series has no upcoming occurrence left" do
    before do
      allow(series).to receive(:first_available_occurrence).and_return(nil)
      allow(current_meeting).to receive(:recurring_meeting).and_return(series)
      allow(agenda_item).to receive(:meeting).and_return(current_meeting)
    end

    it "fails without moving the item" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to include(:no_available_occurrence)
    end
  end

  context "when the user may view but not manage agendas" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

    it "fails without materializing an occurrence" do
      current_meeting

      expect { service_call }.not_to change { series.meetings.not_templated.count }
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end
end
