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

require_relative "../../../spec_helper"
require "rack/test"

RSpec.describe "API v3 whiteboards resource", with_flag: { whiteboards: true } do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, enabled_module_names: %w[whiteboards]) }
  let(:whiteboard) { create(:whiteboard, project:, content_binary: "AAEC") }
  let(:permissions) { %i[view_whiteboards manage_whiteboards] }
  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:path) { api_v3_paths.whiteboard(whiteboard.id) }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "GET /api/v3/whiteboards/:id" do
    before { get path }

    it "returns the Y.Doc binary and an update link" do
      expect(response).to have_http_status(200)
      expect(response.body).to be_json_eql("Whiteboard".to_json).at_path("_type")
      expect(response.body).to be_json_eql("AAEC".to_json).at_path("contentBinary")
      expect(response.body).to have_json_path("_links/update")
    end

    context "for a user who can only view" do
      let(:permissions) { %i[view_whiteboards] }

      it "omits the update link, which makes the collaboration server read-only" do
        expect(response).to have_http_status(200)
        expect(response.body).not_to have_json_path("_links/update")
      end
    end

    context "with the feature flag disabled", with_flag: { whiteboards: false } do
      it "responds with 404" do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "PATCH /api/v3/whiteboards/:id" do
    let(:scene) { { "elements" => [{ "id" => "a", "type" => "text", "text" => "Hello" }], "files" => {} } }
    let(:body) { { content_binary: "AQID", scene:, searchable_text: "Hello", title: "ignored" }.to_json }

    before do
      patch path, body, { "CONTENT_TYPE" => "application/json" }
    end

    it "stores the binary and its projections, but nothing else" do
      expect(response).to have_http_status(200)
      expect(whiteboard.reload).to have_attributes(
        content_binary: "AQID",
        scene:,
        searchable_text: "Hello",
        title: whiteboard.title
      )
    end

    context "for a user who can only view" do
      let(:permissions) { %i[view_whiteboards] }

      it "rejects the change" do
        expect(response).to have_http_status(403)
        expect(whiteboard.reload.content_binary).to eq("AAEC")
      end
    end
  end
end
