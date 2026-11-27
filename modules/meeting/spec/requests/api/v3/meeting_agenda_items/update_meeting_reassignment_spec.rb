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

RSpec.describe "API v3 Meeting Agenda Item update meeting reassignment", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:source_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:target_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:author) { create(:user) }

  shared_let(:source_meeting) { create(:meeting, project: source_project, author:) }
  shared_let(:target_meeting) { create(:meeting, project: target_project, author:) }
  shared_let(:source_section) { create(:meeting_section, meeting: source_meeting, title: "Source Section") }
  shared_let(:target_section) { create(:meeting_section, meeting: target_meeting, title: "Target Section") }
  shared_let(:agenda_item) do
    create(:meeting_agenda_item, meeting: source_meeting, meeting_section: source_section, author:, title: "Source Item")
  end
  let!(:outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, author:) }

  let(:current_user) do
    create(:user, member_with_permissions: {
             source_project => %i[view_meetings],
             target_project => %i[view_meetings manage_agendas]
           })
  end

  let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id) }
  let(:body) do
    {
      title: "Reassigned Item",
      _links: {
        meeting: {
          href: api_v3_paths.meeting(target_meeting.id)
        },
        section: {
          href: api_v3_paths.meeting_section(target_section.id)
        }
      }
    }.to_json
  end

  before do
    login_as current_user
  end

  subject(:response) { patch path, body }

  it "does not reassign the agenda item without permission in the source project" do
    expect(response).to have_http_status(:forbidden)
    expect(agenda_item.reload).to have_attributes(
      meeting_id: source_meeting.id,
      meeting_section_id: source_section.id,
      title: "Source Item"
    )
    expect(MeetingOutcome).to exist(outcome.id)
  end

  context "with permission in the source and destination projects" do
    let(:current_user) do
      create(:user, member_with_permissions: {
               source_project => %i[view_meetings manage_agendas],
               target_project => %i[view_meetings manage_agendas]
             })
    end

    it "reassigns the agenda item to the target meeting" do
      expect(response).to have_http_status(:ok)
      expect(agenda_item.reload).to have_attributes(
        meeting_id: target_meeting.id,
        meeting_section_id: target_section.id,
        title: "Reassigned Item"
      )
      expect(MeetingOutcome).to exist(outcome.id)
    end
  end
end
