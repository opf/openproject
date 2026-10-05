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

RSpec.describe "API v3 screen layout resolver" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:admin) { create(:admin) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:assigner) { create(:user, member_with_permissions: { project => %i[view_work_packages assign_screen_scheme] }) }

  let(:json) { JSON.parse(last_response.body) }

  describe "GET /projects/:id/types/:type_id/screens/:context" do
    it "returns native with no scheme and hides diagnostics from a plain viewer" do
      login_as(viewer)
      get api_v3_paths.project_type_screen_layout(project.id, type.id, "create")
      expect(last_response).to have_http_status(:ok)
      expect(json).to include("source" => "native", "reason" => "no_scheme")
      expect(last_response.headers["Cache-Control"]).to eq("private")
      expect(json["diagnostics"]).to eq({})
    end

    it "returns diagnostics to an assigner" do
      login_as(assigner)
      get api_v3_paths.project_type_screen_layout(project.id, type.id, "create")
      expect(json["diagnostics"]).to be_a(Hash)
      expect(json["diagnostics"]).to have_key("requiredNotPlaced")
    end

    it "answers 422 for an invalid context before querying" do
      login_as(viewer)
      get api_v3_paths.project_type_screen_layout(project.id, type.id, "foo")
      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(json.dig("errorIdentifier")).to include("PropertyConstraintViolation")
    end

    it "answers 404 when the type is not enabled in the project" do
      other = create(:type, name: "Not enabled")
      login_as(viewer)
      get api_v3_paths.project_type_screen_layout(project.id, other.id, "create")
      expect(last_response).to have_http_status(:not_found)
    end

    it "answers 401 for anonymous users" do
      get api_v3_paths.project_type_screen_layout(project.id, type.id, "create")
      expect(last_response).to have_http_status(:unauthorized)
    end
  end
end
