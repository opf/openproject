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
require "rack/test"

RSpec.describe "API v3 Meeting Agenda Item move to next meeting", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:author) { create(:user) }
  shared_let(:series) { create(:recurring_meeting, project:, author:) }

  let!(:current_meeting) do
    create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: series.first_occurrence)
  end
  let!(:section) { create(:meeting_section, meeting: current_meeting) }
  let!(:agenda_item) do
    create(:meeting_agenda_item, meeting: current_meeting, meeting_section: section, author:, title: "Carry over")
  end

  let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] })
  end

  let(:path) { api_v3_paths.meeting_agenda_item_move_to_next_meeting(agenda_item.id) }

  before { login_as current_user }

  subject(:response) { post path }

  def next_slot
    series.next_occurrence(from_time: current_meeting.recurrence_start_time)
  end

  it "moves the agenda item to the next occurrence" do
    expect(response).to have_http_status(:ok)

    target = series.meetings.not_templated.find_by(recurrence_start_time: next_slot)
    expect(agenda_item.reload.meeting_id).to eq(target.id)

    expect(last_response.body)
      .to be_json_eql(api_v3_paths.meeting(target.id).to_json)
      .at_path("_links/meeting/href")
  end

  context "without manage_agendas permission" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_meetings] })
    end

    it "does not move the agenda item or materialize an occurrence" do
      expect { response }.not_to change { series.meetings.not_templated.count }
      expect(response).to have_http_status(:forbidden)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end

  context "when the meeting is not recurring" do
    let!(:current_meeting) { create(:meeting, project:, author:) }

    it "returns an unprocessable error" do
      expect(response).to have_http_status(:unprocessable_entity)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end

  context "when the meeting is closed" do
    before { current_meeting.reload.update!(state: :closed) }

    it "returns an unprocessable error" do
      expect(response).to have_http_status(:unprocessable_entity)
      expect(agenda_item.reload.meeting_id).to eq(current_meeting.id)
    end
  end
end
