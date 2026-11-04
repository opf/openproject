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

RSpec.describe "API v3 wiki_api: per-page operations" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project)     { create(:project, enabled_module_names: %i[wiki]) }
  let(:wiki)        { create(:wiki, project:) }
  let!(:page)       { create(:wiki_page, wiki:, title: "Source", text: "v1") }
  let(:role)        { create(:project_role, permissions:) }
  let(:permissions) { %i[view_wiki_pages edit_wiki_pages view_wiki_edits manage_wiki] }
  let(:current_user) { create(:user, member_with_roles: { project => role }) }

  subject(:response) { last_response }

  before { login_as(current_user) }

  describe "PATCH /api/v3/wiki_pages/:id" do
    let(:body) do
      { text: { raw: "v2" }, lockVersion: page.lock_version }.to_json
    end

    before do
      header "Content-Type", "application/json"
      patch api_v3_paths.wiki_page(page.id), body
    end

    it "updates the page" do
      expect(response.status).to eq(200)
      expect(page.reload.text).to eq("v2")
    end
  end

  describe "DELETE /api/v3/wiki_pages/:id" do
    before { delete api_v3_paths.wiki_page(page.id) }

    it "returns 204 and removes the page" do
      expect(response.status).to eq(204)
      expect(WikiPage.find_by(id: page.id)).to be_nil
    end

    context "without manage_wiki permission" do
      let(:permissions) { %i[view_wiki_pages edit_wiki_pages] }

      it "returns 403" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "GET /api/v3/wiki_pages/:id/versions" do
    before do
      ::WikiPages::UpdateService
        .new(user: current_user, contract_class: ::WikiPages::UpdateContract, model: page)
        .call(text: "v2", lock_version: page.lock_version)
      get "#{api_v3_paths.wiki_page(page.id)}/versions"
    end

    it "returns the list of versions" do
      expect(response.status).to eq(200)
      total = JSON.parse(response.body)["total"]
      expect(total).to be >= 1
    end
  end

  describe "POST /api/v3/wiki_pages/:id/lock and /unlock" do
    it "locks then unlocks the page" do
      header "Content-Type", "application/json"
      post "#{api_v3_paths.wiki_page(page.id)}/lock", "{}"
      expect(response.status).to eq(200)
      expect(page.reload.protected?).to be true

      post "#{api_v3_paths.wiki_page(page.id)}/unlock", "{}"
      expect(response.status).to eq(200)
      expect(page.reload.protected?).to be false
    end
  end

  describe "POST /api/v3/wiki_pages/:id/copy" do
    let(:body) { { title: "Source Copy" }.to_json }

    before do
      header "Content-Type", "application/json"
      post "#{api_v3_paths.wiki_page(page.id)}/copy", body
    end

    it "creates a copy" do
      expect(response.status).to eq(201)
      expect(WikiPage.find_by(title: "Source Copy", wiki:)).to be_present
    end
  end
end
