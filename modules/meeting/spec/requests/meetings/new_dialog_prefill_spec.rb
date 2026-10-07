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

RSpec.describe "New meeting dialog prefilled with a title and participants", :skip_csrf, type: :rails_request do
  let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  let(:permissions) { %i[view_meetings create_meetings] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:colleague) { create(:user, firstname: "Sakura", lastname: "Haruno", member_with_permissions: { project => permissions }) }
  let(:stranger) { create(:user, firstname: "Nobody", lastname: "Known") }

  current_user { user }

  it "opens with the title and the visible participants" do
    get new_dialog_meetings_path(title: "Wiki permissions", participant_ids: [colleague.id, stranger.id]),
        as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('value="Wiki permissions"')
    expect(response.body).to include("meeting-prefilled-participants")
    expect(response.body).to include("Sakura Haruno")
    expect(response.body).not_to include("Nobody Known")
    expect(response.body.scan('name="meeting[participants_attributes][][user_id]"').size).to eq(2)
  end

  it "opens as usual without them" do
    get new_dialog_meetings_path, as: :turbo_stream

    expect(response.body).not_to include("meeting-prefilled-participants")
  end

  it "keeps them when a project is picked" do
    post fetch_templates_meetings_path,
         params: { meeting: { project_id: project.id, title: "Wiki permissions",
                              participants_attributes: [{ user_id: user.id, invited: "1" },
                                                        { user_id: colleague.id, invited: "1" }] } },
         as: :turbo_stream

    expect(response.body).to include('value="Wiki permissions"')
    expect(response.body).to include("Sakura Haruno")
  end

  it "invites them when the meeting is created" do
    post meetings_path,
         params: { meeting: { project_id: project.id, title: "Wiki permissions", start_date: Date.tomorrow.iso8601,
                              start_time_hour: "10:00", duration: "1h",
                              participants_attributes: [{ user_id: user.id, invited: "1" },
                                                        { user_id: colleague.id, invited: "1" }] } },
         as: :turbo_stream

    meeting = Meeting.find_by!(title: "Wiki permissions")
    expect(meeting.participants.map(&:user)).to contain_exactly(user, colleague)
  end
end
