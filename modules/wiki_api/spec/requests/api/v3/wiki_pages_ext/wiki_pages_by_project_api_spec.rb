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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 wiki_api: project-scoped endpoints" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project)     { create(:project, enabled_module_names: %i[wiki]) }
  let(:wiki)        { create(:wiki, project:) }
  let!(:page_a)     { create(:wiki_page, wiki:, title: "Alpha") }
  let!(:page_b)     { create(:wiki_page, wiki:, title: "Beta") }
  let(:role)        { create(:project_role, permissions:) }
  let(:permissions) { %i[view_wiki_pages edit_wiki_pages] }
  let(:current_user) { create(:user, member_with_roles: { project => role }) }

  subject(:response) { last_response }

  before { login_as(current_user) }

  describe "GET /api/v3/projects/:project_id/wiki_pages" do
    let(:path) { api_v3_paths.wiki_pages_by_project(project.id) }

    before { get path }

    it "returns 200 with both pages" do
      expect(response.status).to eq(200)
      expect(response.body).to be_json_eql(2.to_json).at_path("total")
      titles = JSON.parse(response.body).dig("_embedded", "elements").map { |e| e["title"] }
      expect(titles).to match_array(%w[Alpha Beta])
    end

    context "without any wiki permission" do
      let(:permissions) { [] }

      it "returns 403" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "POST /api/v3/projects/:project_id/wiki_pages" do
    let(:path) { api_v3_paths.wiki_pages_by_project(project.id) }
    let(:body) do
      {
        title: "Gamma",
        text:  { raw: "Hello **world**" }
      }.to_json
    end

    before do
      header "Content-Type", "application/json"
      post path, body
    end

    it "creates a page" do
      expect(response.status).to eq(201)
      expect(response.body).to be_json_eql("WikiPage".to_json).at_path("_type")
      expect(response.body).to be_json_eql("Gamma".to_json).at_path("title")
      expect(WikiPage.find_by(title: "Gamma")).to be_present
    end

    context "without edit_wiki_pages permission" do
      let(:permissions) { %i[view_wiki_pages] }

      it "returns 403" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "GET /api/v3/projects/:project_id/wiki_pages/tree" do
    let!(:child) { create(:wiki_page, wiki:, parent: page_a, title: "AlphaChild") }
    let(:path)   { "#{api_v3_paths.wiki_pages_by_project(project.id)}/tree" }

    before { get path }

    it "returns a nested tree" do
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      alpha = json["tree"].find { |n| n["title"] == "Alpha" }
      expect(alpha).to be_present
      expect(alpha["children"].map { |c| c["title"] }).to include("AlphaChild")
    end
  end

  describe "GET /api/v3/projects/:project_id/wiki_pages/search" do
    let!(:matching) { create(:wiki_page, wiki:, title: "Delta", text: "Full description about delta") }
    let(:path)      { "#{api_v3_paths.wiki_pages_by_project(project.id)}/search?q=delta" }

    before { get path }

    it "matches on title/text" do
      expect(response.status).to eq(200)
      titles = JSON.parse(response.body).dig("_embedded", "elements").map { |e| e["title"] }
      expect(titles).to include("Delta")
    end

    context "with an empty query" do
      let(:path) { "#{api_v3_paths.wiki_pages_by_project(project.id)}/search?q=" }

      it "returns zero elements" do
        expect(response.status).to eq(200)
        expect(response.body).to be_json_eql(0.to_json).at_path("total")
      end
    end
  end
end
