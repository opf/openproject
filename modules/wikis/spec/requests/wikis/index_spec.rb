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

RSpec.describe "Wiki pages index", :skip_csrf, type: :rails_request do
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_wiki_pages]) }
  let(:project) { create(:project, :with_internal_wiki, members: { user => role }) }
  let(:wiki) { project.wiki }
  let!(:main_page) { create(:wiki_page, wiki:, title: "Architecture handbook") }
  let!(:sub_page) { create(:wiki_page, wiki:, parent: main_page, title: "Deployment guide") }

  let(:other_project) { create(:project, :with_internal_wiki) }
  let!(:other_page) { create(:wiki_page, wiki: other_project.wiki, title: "Hidden handbook") }

  before { login_as user }

  describe "GET /wiki_pages" do
    context "when not logged in and a login is required", with_settings: { login_required: true } do
      before { login_as User.anonymous }

      it "redirects to login" do
        get "/wiki_pages"

        expect(response).to redirect_to(signin_path(back_url: wiki_pages_url))
      end
    end

    context "when not logged in and no login is required", with_settings: { login_required: false } do
      let!(:anonymous_role) { create(:anonymous_role, permissions: %i[view_wiki_pages]) }
      let!(:public_page) do
        create(:wiki_page,
               wiki: create(:public_project, :with_internal_wiki).wiki,
               title: "Public handbook")
      end

      before { login_as User.anonymous }

      it "lists the main pages of public projects with anonymous wiki access" do
        get "/wiki_pages"

        expect(response).to have_http_status(:ok)
        expect(page).to have_text "Public handbook"
        expect(page).to have_no_text "Architecture handbook"
      end
    end

    it "lists all pages of projects the user can access, with their sub-page count" do
      get "/wiki_pages"

      expect(response).to have_http_status(:ok)
      expect(page).to have_text "Architecture handbook"
      expect(page).to have_text "Deployment guide"
      expect(page).to have_text "1 sub-page"
    end

    it "does not list pages of projects the user cannot access" do
      get "/wiki_pages"

      expect(page).to have_no_text "Hidden handbook"
    end

    it "clamps an out-of-range page param to the last page" do
      get "/wiki_pages", params: { page: "5" }

      expect(response).to have_http_status(:ok)
      expect(page).to have_text "Architecture handbook"
    end

    context "with a name filter" do
      it "returns only pages with a matching title" do
        get "/wiki_pages", params: { filters: [{ name: { operator: "~", values: ["Architecture"] } }].to_json }

        expect(page).to have_text "Architecture handbook"
      end

      it "shows a blank slate when no title matches" do
        get "/wiki_pages", params: { filters: [{ name: { operator: "~", values: ["nonexistent_page_xyz"] } }].to_json }

        expect(page).to have_text I18n.t("wikis.index.no_results_title")
        expect(page).to have_no_text "Architecture handbook"
      end
    end

    it "falls back to all pages for unknown query ids" do
      get "/wiki_pages", params: { query_id: "everything" }

      expect(page).to have_text "Architecture handbook"
      expect(page).to have_text "Deployment guide"
    end

    it "shows the immediate parent of sub-pages and a dash for main pages" do
      get "/wiki_pages", params: { query_id: "all" }

      expect(page).to have_css(".op-border-box-grid__row-item.parent", text: "Architecture handbook", count: 1)
      expect(page).to have_css(".op-border-box-grid__row-item.parent", text: "-", count: 1)
    end
  end

  describe "GET /wiki_pages?query_id=main" do
    it "lists main pages only" do
      get "/wiki_pages", params: { query_id: "main" }

      expect(page).to have_text "Architecture handbook"
      expect(page).to have_no_text "Deployment guide"
      expect(page).to have_no_text "Hidden handbook"
    end

    context "with a name filter" do
      it "does not match sub-pages" do
        get "/wiki_pages", params: { query_id: "main",
                                     filters: [{ name: { operator: "~", values: ["Deployment"] } }].to_json }

        expect(page).to have_text I18n.t("wikis.index.no_results_title")
      end
    end
  end
end
