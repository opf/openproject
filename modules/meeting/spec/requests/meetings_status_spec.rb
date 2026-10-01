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

RSpec.describe "Meeting requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:meeting) { create(:meeting, project:, author: user, state: :open) }

  before do
    login_as user
  end

  describe "Update meeting state" do
    it "allows to update the state with edit_meetings permission (Regression #63745)" do
      put change_state_project_meeting_path(project, meeting, state: "in_progress"),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)

      expect(meeting.reload).to be_in_progress
    end

    it "handles a stale object gracefully (Bug #68703)" do
      allow_any_instance_of(Meeting).to receive(:in_progress!).and_raise(ActiveRecord::StaleObjectError) # rubocop:disable RSpec/AnyInstance

      put change_state_project_meeting_path(project, meeting, state: "in_progress"),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(meeting.reload).to be_open
    end
  end
end
