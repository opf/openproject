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
# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 screens" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }
  shared_let(:screen) { create(:create_screen, name: "Bug create") }

  let(:json) { JSON.parse(last_response.body) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "read" do
    it "lets a logged in user list and read screens" do
      login_as(user)
      get api_v3_paths.screens
      expect(last_response).to have_http_status(:ok)
      expect(json["_embedded"]["elements"].pluck("name")).to include("Bug create")

      get api_v3_paths.screen(screen.id)
      expect(last_response).to have_http_status(:ok)
      expect(last_response.headers["ETag"]).to be_present
      expect(json["screenType"]).to eq("create")
    end

    it "answers 401 for anonymous users" do
      get api_v3_paths.screens
      expect(last_response).to have_http_status(:unauthorized)
    end
  end

  describe "write" do
    it "forbids non administrators" do
      login_as(user)
      post api_v3_paths.screens, { name: "X", screenType: "create" }.to_json, headers
      expect(last_response).to have_http_status(:forbidden)
    end

    it "creates and updates as administrator" do
      login_as(admin)
      post api_v3_paths.screens, { name: "View screen", screenType: "view" }.to_json, headers
      expect(last_response).to have_http_status(:created)
      id = json["id"]

      patch api_v3_paths.screen(id), { name: "Renamed" }.to_json, headers
      expect(last_response).to have_http_status(:ok)
      expect(json["name"]).to eq("Renamed")
    end

    it "treats screenType as read-only" do
      login_as(admin)
      patch api_v3_paths.screen(screen.id), { screenType: "edit" }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(json["errorIdentifier"]).to include("PropertyIsReadOnly")
    end

    it "requires If-Match for the layout endpoint" do
      login_as(admin)
      put api_v3_paths.screen_layout(screen.id), { sections: [] }.to_json, headers
      expect(last_response).to have_http_status(428)
    end

    it "rejects a stale If-Match with UpdateConflict" do
      login_as(admin)
      put api_v3_paths.screen_layout(screen.id), { sections: [] }.to_json, headers.merge("If-Match" => "stale")
      expect(last_response).to have_http_status(:conflict)
    end
  end
end
