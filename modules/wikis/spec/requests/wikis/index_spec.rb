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

RSpec.describe "Wikis index", :skip_csrf, type: :rails_request do
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_wiki_pages]) }
  let(:project) { create(:project, members: { user => role }) }
  let(:wiki) { project.wiki }
  let!(:main_page) { create(:wiki_page, wiki:, title: "Architecture handbook") }
  let!(:sub_page) { create(:wiki_page, wiki:, parent: main_page, title: "Deployment guide") }

  let(:other_project) { create(:project) }
  let!(:other_page) { create(:wiki_page, wiki: other_project.wiki, title: "Hidden handbook") }

  before { login_as user }

  describe "GET /wikis" do
    context "when not logged in" do
      before { login_as User.anonymous }

      it "redirects to login" do
        get "/wikis"

        expect(response).to redirect_to(signin_path(back_url: wikis_url))
      end
    end

    it "lists main pages of projects the user can access, with their sub-page count" do
      get "/wikis"

      expect(response).to have_http_status(:ok)
      expect(page).to have_text "Architecture handbook"
      expect(page).to have_text "1 sub-page"
    end

    it "does not list sub-pages" do
      get "/wikis"

      expect(page).to have_no_text "Deployment guide"
    end

    it "does not list pages of projects the user cannot access" do
      get "/wikis"

      expect(page).to have_no_text "Hidden handbook"
    end

    it "clamps an out-of-range page param to the last page" do
      get "/wikis", params: { page: "5" }

      expect(response).to have_http_status(:ok)
      expect(page).to have_text "Architecture handbook"
    end

    context "with a name filter" do
      it "returns only pages with a matching title" do
        get "/wikis", params: { filters: [{ name: { operator: "~", values: ["Architecture"] } }].to_json }

        expect(page).to have_text "Architecture handbook"
      end

      it "shows a blank slate when no title matches" do
        get "/wikis", params: { filters: [{ name: { operator: "~", values: ["nonexistent_page_xyz"] } }].to_json }

        expect(page).to have_text I18n.t("wikis.index.no_results_title")
        expect(page).to have_no_text "Architecture handbook"
      end
    end
  end

  describe "GET /wikis?query_id=all" do
    it "lists main pages and sub-pages of projects the user can access" do
      get "/wikis", params: { query_id: "all" }

      expect(page).to have_text "Architecture handbook"
      expect(page).to have_text "Deployment guide"
      expect(page).to have_no_text "Hidden handbook"
    end

    it "falls back to main pages for unknown query ids" do
      get "/wikis", params: { query_id: "everything" }

      expect(page).to have_text "Architecture handbook"
      expect(page).to have_no_text "Deployment guide"
    end

    context "with a name filter" do
      it "matches sub-pages too" do
        get "/wikis", params: { query_id: "all",
                                filters: [{ name: { operator: "~", values: ["Deployment"] } }].to_json }

        expect(page).to have_text "Deployment guide"
        expect(page).to have_no_text "Architecture handbook"
      end
    end
  end
end
