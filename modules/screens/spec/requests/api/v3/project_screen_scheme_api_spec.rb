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

RSpec.describe "API v3 project screen scheme" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:admin) { create(:admin) }
  shared_let(:scheme) { create(:screen_scheme, name: "Dev") }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:assigner) { create(:user, member_with_permissions: { project => %i[view_work_packages assign_screen_scheme] }) }

  let(:json) { JSON.parse(last_response.body) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "GET /projects/:id/screen_scheme" do
    it "requires the assign permission" do
      login_as(viewer)
      get api_v3_paths.project_screen_scheme(project.id)
      expect(last_response).to have_http_status(:forbidden)
    end

    it "returns the assignment for an assigner" do
      create(:project_screen_scheme, project:, scheme:)
      login_as(assigner)
      get api_v3_paths.project_screen_scheme(project.id)
      expect(last_response).to have_http_status(:ok)
      expect(json["schemeId"]).to eq(scheme.id)
    end
  end

  describe "PUT /projects/:id/screen_scheme" do
    it "assigns an active scheme and returns 204" do
      login_as(assigner)
      put api_v3_paths.project_screen_scheme(project.id), { schemeId: scheme.id }.to_json, headers
      expect(last_response).to have_http_status(:no_content)
      expect(ProjectScreenScheme.find_by(project_id: project.id).scheme).to eq(scheme)
    end

    it "rejects an inactive scheme with 422" do
      inactive = create(:screen_scheme, name: "Inactive", active: false)
      login_as(assigner)
      put api_v3_paths.project_screen_scheme(project.id), { schemeId: inactive.id }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "clears the assignment with schemeId null" do
      create(:project_screen_scheme, project:, scheme:)
      login_as(assigner)
      put api_v3_paths.project_screen_scheme(project.id), { schemeId: nil }.to_json, headers
      expect(last_response).to have_http_status(:no_content)
      expect(ProjectScreenScheme.find_by(project_id: project.id)).to be_nil
    end

    it "answers 400 for a non-object body" do
      login_as(assigner)
      put api_v3_paths.project_screen_scheme(project.id), "[]", headers
      expect(last_response).to have_http_status(:bad_request)
    end
  end
end
