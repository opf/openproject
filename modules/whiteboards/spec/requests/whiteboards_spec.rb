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

require_relative "../spec_helper"

RSpec.describe "Whiteboards", with_flag: { whiteboards: true } do
  let(:project) { create(:project, enabled_module_names: %w[whiteboards]) }
  let(:permissions) { %i[view_whiteboards manage_whiteboards] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before do
    login_as(user)
  end

  describe "POST /projects/:project_id/whiteboards" do
    it "creates a whiteboard authored by the user and opens it" do
      expect { post project_whiteboards_path(project) }.to change(Whiteboard, :count).by(1)

      whiteboard = Whiteboard.last
      expect(whiteboard.author).to eq(user)
      expect(response).to redirect_to(whiteboard_path(whiteboard))
    end

    context "for a user who can only view" do
      let(:permissions) { %i[view_whiteboards] }

      it "is forbidden" do
        expect { post project_whiteboards_path(project) }.not_to change(Whiteboard, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /whiteboards/:id",
           with_settings: {
             collaborative_editing_hocuspocus_url: "wss://hocuspocus.example",
             collaborative_editing_hocuspocus_secret: "secret"
           } do
    let(:whiteboard) { create(:whiteboard, project:) }

    it "renders the full-screen canvas with the collaboration provider" do
      get whiteboard_path(whiteboard)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<op-whiteboard")
      expect(response.body).to include("collaboration--init-yjs-provider")
      expect(response.body).not_to include("op-app-header")
    end
  end

  describe "POST /projects/:project_id/whiteboards/:id/refresh_token",
           with_settings: { collaborative_editing_hocuspocus_secret: "secret" } do
    let(:whiteboard) { create(:whiteboard, project:) }

    it "returns a fresh encrypted token" do
      post project_whiteboard_refresh_token_path(project, whiteboard)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("encrypted_token", "expires_in_seconds")
    end
  end
end
