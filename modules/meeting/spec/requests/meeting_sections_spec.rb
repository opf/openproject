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

RSpec.describe "Meeting sections requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:meeting) { create(:meeting, project:, author: user) }

  before do
    login_as user
  end

  describe "edit" do
    context "when meeting belongs to another project the user has no access to" do
      let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
      let(:other_meeting) { create(:meeting, project: other_project) }
      let(:other_section) { create(:meeting_section, meeting: other_meeting) }

      it "returns 403" do
        get edit_project_meeting_section_path(other_meeting.project, other_meeting, other_section)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "create" do
    context "when meeting belongs to another project the user has no access to" do
      let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
      let(:other_meeting) { create(:meeting, project: other_project) }

      it "returns 403" do
        post project_meeting_sections_path(other_meeting.project, other_meeting)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "update" do
    context "when meeting belongs to another project the user has no access to" do
      let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
      let(:other_meeting) { create(:meeting, project: other_project) }
      let(:other_section) { create(:meeting_section, meeting: other_meeting) }

      it "returns 403" do
        put project_meeting_section_path(other_meeting.project, other_meeting, other_section),
            params: { meeting_section: { title: "New title" } }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "destroy" do
    context "when meeting belongs to another project the user has no access to" do
      let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
      let(:other_meeting) { create(:meeting, project: other_project) }
      let(:other_section) { create(:meeting_section, meeting: other_meeting) }

      it "returns 403" do
        delete project_meeting_section_path(other_meeting.project, other_meeting, other_section)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
