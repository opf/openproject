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

RSpec.describe "Editing a split agenda item in presentation mode",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] })
  end
  shared_let(:meeting) { create(:meeting, project:) }

  let!(:meeting_agenda_item) do
    create(:meeting_agenda_item, meeting:, notes: "First slide\n\n---\n\nSecond slide")
  end

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:presentation_params) { { presentation_mode: true, slide: 2 } }

  before { login_as(user) }

  describe "GET edit" do
    it "keeps the slide in the submit and cancel paths" do
      get edit_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item, **presentation_params),
          headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        project_meeting_agenda_item_path(project, meeting, meeting_agenda_item,
                                         format: :turbo_stream, presentation_mode: true, slide: 2).gsub("&", "&amp;")
      )
      expect(response.body).to include(
        cancel_edit_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item,
                                                     presentation_mode: true, slide: 2).gsub("&", "&amp;")
      )
    end
  end

  describe "GET cancel_edit" do
    it "returns to the slide that was presented" do
      get cancel_edit_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item, **presentation_params),
          headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Second slide")
      expect(response.body).not_to include("First slide")
    end

    context "when not in presentation mode" do
      let(:presentation_params) { { slide: 2 } }

      it "shows all notes" do
        get cancel_edit_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item, **presentation_params),
            headers: turbo_headers

        expect(response.body).to include("First slide")
        expect(response.body).to include("Second slide")
      end
    end
  end

  describe "PUT update" do
    it "returns to the slide that was presented with the updated notes" do
      put project_meeting_agenda_item_path(project, meeting, meeting_agenda_item,
                                           format: :turbo_stream, **presentation_params),
          params: { meeting_agenda_item: { notes: "First slide\n\n---\n\nUpdated second slide" } },
          headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Updated second slide")
      expect(response.body).not_to include("First slide")
    end
  end
end
