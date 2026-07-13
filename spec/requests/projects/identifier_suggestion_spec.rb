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

require "rails_helper"

RSpec.describe "GET /projects/identifier_suggestion", type: :rails_request do
  current_user { create(:user, global_permissions: %i[add_project]) }

  context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    it "returns a suggested identifier derived from the name" do
      get "/projects/identifier_suggestion", params: { name: "Flight Planning Algorithm" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["identifier"]).to eq("FPA")
    end

    it "returns a single-word suggestion for single-word names" do
      get "/projects/identifier_suggestion", params: { name: "Banana" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["identifier"]).to eq("BAN")
    end

    it "returns an identifier starting with a letter for digit-prefixed names" do
      get "/projects/identifier_suggestion", params: { name: "3D Printing Lab" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["identifier"]).to match(/\A[A-Z]/)
    end

    it "transliterates accented characters" do
      get "/projects/identifier_suggestion", params: { name: "Équipe Réseau" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["identifier"]).to match(/\A[A-Z][A-Z0-9_]*\z/)
    end

    it "returns 422 when name is blank" do
      get "/projects/identifier_suggestion", params: { name: "" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "when not logged in" do
      current_user { User.anonymous }

      it "requires login" do
        get "/projects/identifier_suggestion", params: { name: "Test" }, as: :json
        expect(response).to have_http_status(:unauthorized).or have_http_status(:redirect)
      end
    end

    context "when user has no permissions" do
      current_user { create(:user) }

      it "returns forbidden" do
        get "/projects/identifier_suggestion", params: { name: "Test" }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user has add_subprojects permission on a project" do
      let(:project) { create(:project, identifier: "PRNT") }

      current_user { create(:user, member_with_permissions: { project => %i[add_subprojects] }) }

      it "returns a suggestion" do
        get "/projects/identifier_suggestion", params: { name: "Test" }, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "with classic identifiers", with_settings: { work_packages_identifier: "classic" } do
    it "returns a slugified lowercase identifier" do
      get "/projects/identifier_suggestion", params: { name: "My Cool Project" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["identifier"]).to eq("my-cool-project")
    end

    it "returns 422 when name is blank" do
      get "/projects/identifier_suggestion", params: { name: "" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
