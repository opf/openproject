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

RSpec.describe "API v3 type schemes" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, types: [epic, story, bug]) }
  shared_let(:admin) { create(:admin) }
  shared_let(:member) do
    create(:user, member_with_permissions: { project => %i[view_work_packages assign_type_scheme] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:scheme) { create(:type_scheme, name: "Dev", types: [story, epic]) }

  let(:json) { JSON.parse(last_response.body) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  def body_for(name, types)
    { name:,
      typeItems: types.each_with_index.map do |type, i|
        { _links: { type: { href: api_v3_paths.type(type.id) } }, position: i + 1, default: i.zero? }
      end }.to_json
  end

  describe "reading" do
    before { login_as(viewer) }

    it "lists schemes" do
      get api_v3_paths.type_schemes
      expect(last_response).to have_http_status(:ok)
      expect(json["_embedded"]["elements"].pluck("name")).to include("Dev")
    end

    it "shows a scheme with ordered type items" do
      get api_v3_paths.type_scheme(scheme.id)
      expect(last_response).to have_http_status(:ok)
      expect(json["typeItems"].map { _1.dig("_links", "type", "href") })
        .to eq([api_v3_paths.type(story.id), api_v3_paths.type(epic.id)])
      expect(json["typeItems"].first["default"]).to be true
    end

    it "returns 404 for an unknown scheme" do
      get api_v3_paths.type_scheme(0)
      expect(last_response).to have_http_status(:not_found)
    end

    it "forbids writing" do
      post api_v3_paths.type_schemes, body_for("X", [bug]), headers
      expect(last_response).to have_http_status(:forbidden)
      delete api_v3_paths.type_scheme(scheme.id)
      expect(last_response).to have_http_status(:forbidden)
    end
  end

  describe "writing as admin" do
    before { login_as(admin) }

    it "creates, updates and deletes a scheme" do
      post api_v3_paths.type_schemes, body_for("New", [bug, epic]), headers
      expect(last_response).to have_http_status(:created)
      id = json["id"]
      expect(TypeScheme.find(id).default_type).to eq bug

      patch api_v3_paths.type_scheme(id), body_for("Renamed", [epic]), headers
      expect(last_response).to have_http_status(:ok)
      expect(TypeScheme.find(id)).to have_attributes(name: "Renamed", types: [epic])

      delete api_v3_paths.type_scheme(id)
      expect(last_response).to have_http_status(:no_content)
      expect(TypeScheme.exists?(id)).to be false
    end

    it "rejects an item without a type link" do
      body = { name: "Bad", typeItems: [{ position: 1, default: true }] }
      post api_v3_paths.type_schemes, body.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a scheme without a default type" do
      body = { name: "Bad", typeItems: [{ _links: { type: { href: api_v3_paths.type(bug.id) } }, position: 1 }] }
      post api_v3_paths.type_schemes, body.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "refuses to delete an assigned scheme and names the project" do
      TypeSchemes::SchemeService.assign(project, scheme)
      delete api_v3_paths.type_scheme(scheme.id)
      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(last_response.body).to include(project.name)
    end
  end

  describe "project assignment" do
    it "requires assign_type_scheme" do
      login_as(viewer)
      put api_v3_paths.project_type_scheme(project.id), { scheme_id: scheme.id }.to_json, headers
      expect(last_response).to have_http_status(:forbidden)
    end

    it "assigns and unassigns" do
      login_as(member)
      put api_v3_paths.project_type_scheme(project.id), { scheme_id: scheme.id }.to_json, headers
      expect(last_response).to have_http_status(:no_content)
      expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq scheme

      put api_v3_paths.project_type_scheme(project.id), { scheme_id: nil }.to_json, headers
      expect(last_response).to have_http_status(:no_content)
      expect(ProjectTypeScheme.where(project_id: project.id)).to be_empty
    end

    it "returns 404 for a project the user cannot see" do
      login_as(create(:user))
      put api_v3_paths.project_type_scheme(project.id), { scheme_id: scheme.id }.to_json, headers
      expect(last_response).to have_http_status(:not_found)
    end

    it "returns 404 for an unknown scheme" do
      login_as(member)
      put api_v3_paths.project_type_scheme(project.id), { scheme_id: 0 }.to_json, headers
      expect(last_response).to have_http_status(:not_found)
    end

    it "rejects an inactive scheme" do
      login_as(member)
      inactive = create(:type_scheme, name: "Off", types: [bug])
      inactive.update_columns(active: false)
      put api_v3_paths.project_type_scheme(project.id), { scheme_id: inactive.id }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "available types" do
    before { login_as(viewer) }

    it "returns scheme types in order, default first" do
      TypeSchemes::SchemeService.assign(project, scheme)
      get api_v3_paths.project_available_types(project.id)

      expect(last_response).to have_http_status(:ok)
      expect(json["_embedded"]["elements"].pluck("id")).to eq([story.id, epic.id])
    end

    it "is forbidden without view_work_packages" do
      login_as(create(:user, member_with_permissions: { project => %i[assign_type_scheme] }))
      get api_v3_paths.project_available_types(project.id)
      expect(last_response).to have_http_status(:forbidden)
    end

    it "returns all enabled types without a scheme" do
      get api_v3_paths.project_available_types(project.id)
      expect(json["_embedded"]["elements"].pluck("id")).to match_array([epic.id, story.id, bug.id])
    end
  end
end
