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

RSpec.describe Wikis::WikisController do
  render_views

  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_wiki_pages]) }
  let(:project) { create(:project, members: { user => role }) }
  let(:wiki) { project.wiki }
  let!(:main_page) { create(:wiki_page, wiki:, title: "Architecture handbook") }
  let!(:sub_page) { create(:wiki_page, wiki:, parent: main_page, title: "Deployment guide") }

  let(:other_project) { create(:project) }
  let!(:other_page) { create(:wiki_page, wiki: other_project.wiki, title: "Hidden handbook") }

  describe "GET #index" do
    context "when not logged in" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(signin_path(back_url: wikis_url))
      end
    end

    context "when logged in" do
      before { login_as user }

      it "renders successfully" do
        get :index
        expect(response).to be_successful
        expect(response).to render_template :index
      end

      it "assigns main pages of projects the user can access" do
        get :index
        expect(assigns(:pages)).to include(main_page)
      end

      it "excludes sub-pages" do
        get :index
        expect(assigns(:pages)).not_to include(sub_page)
      end

      it "excludes pages from projects the user cannot access" do
        get :index
        expect(assigns(:pages)).not_to include(other_page)
      end

      context "with a name filter" do
        it "returns only pages with a matching title" do
          get :index, params: { filters: [{ name: { operator: "~", values: ["handbook"] } }].to_json }
          expect(assigns(:pages)).to contain_exactly(main_page)
        end

        it "returns nothing when no title matches" do
          get :index, params: { filters: [{ name: { operator: "~", values: ["nonexistent_page_xyz"] } }].to_json }
          expect(assigns(:pages)).to be_empty
        end
      end

      context "with a project name filter" do
        it "returns only pages of matching projects" do
          get :index, params: { filters: [{ project_name: { operator: "~", values: [project.name] } }].to_json }
          expect(assigns(:pages)).to contain_exactly(main_page)
        end

        it "returns nothing when no project name matches" do
          get :index,
              params: { filters: [{ project_name: { operator: "~", values: ["nonexistent_project_xyz"] } }].to_json }
          expect(assigns(:pages)).to be_empty
        end
      end
    end
  end
end
