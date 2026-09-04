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
require "rack/test"

RSpec.describe "GET /api/v3/work_packages/:id/activities with meeting-cause journals" do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:meeting) { create(:meeting, project:, title: "Confidential weekly sync") }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:added_journal) do
    create(:work_package_journal,
           journable: work_package,
           version: 2,
           cause: { "type" => "meeting_agenda_item_added", "meeting_id" => meeting.id })
  end

  before do
    allow(User).to receive(:current).and_return(current_user)
    get api_v3_paths.work_package_activities work_package.id
  end

  context "when the user can see the meeting" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages view_meetings] })
    end

    it "includes the meeting-cause activity" do
      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to include(meeting.title)
    end
  end

  context "when the user cannot see the meeting" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] })
    end

    it "excludes the meeting-cause activity" do
      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).not_to include(meeting.title)
    end
  end
end
