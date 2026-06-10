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

require "spec_helper"

RSpec.describe Admin::Settings::ProjectReservedIdentifiersController do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "GET #index" do
    context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "redirects to the identifier settings page" do
        get :index
        expect(response).to redirect_to(admin_settings_work_packages_identifier_path)
      end
    end

    context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "responds 200" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      context "with a classic reserved slug" do
        let!(:project) { create(:project, identifier: "current-id") }

        before { FriendlyId::Slug.create!(sluggable: project, slug: "old-classic") }

        it "includes the slug in @slugs" do
          get :index
          expect(assigns(:slugs).map(&:slug)).to include("old-classic")
        end
      end

      context "with a pure-numeric reserved slug" do
        let!(:project) { create(:project, identifier: "current-id") }

        before { FriendlyId::Slug.create!(sluggable: project, slug: "12345") }

        it "excludes pure-numeric slugs" do
          get :index
          expect(assigns(:slugs).map(&:slug)).not_to include("12345")
        end
      end
    end
  end

  describe "GET #search", with_settings: { work_packages_identifier: "classic", per_page_options: "1 5 10" } do
    render_views

    it "responds with turbo stream" do
      get :search, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    context "with multiple reserved slugs triggering pagination" do
      let!(:project1) { create(:project, identifier: "proj-a") }
      let!(:project2) { create(:project, identifier: "proj-b") }

      before do
        FriendlyId::Slug.create!(sluggable: project1, slug: "old-a")
        FriendlyId::Slug.create!(sluggable: project2, slug: "old-b")
      end

      it "renders pagination links that target the index action, not the search action (regression #STC-811)" do
        get :search, params: { per_page: 1 }, format: :turbo_stream

        expect(response.body).not_to include("#{search_admin_settings_project_reserved_identifiers_path}?")
      end
    end

    context "with a reserved slug" do
      let!(:project) { create(:project, identifier: "current-id") }

      before { FriendlyId::Slug.create!(sluggable: project, slug: "old-search") }

      it "includes the slug in @slugs when no filter is set" do
        get :search, format: :turbo_stream
        expect(assigns(:slugs).map(&:slug)).to include("old-search")
      end

      it "filters @slugs by the name filter" do
        filters = JSON.generate([{ "name" => { "operator" => "~", "values" => ["old-search"] } }])
        get :search, params: { filters: }, format: :turbo_stream
        expect(assigns(:slugs).map(&:slug)).to include("old-search")
      end

      it "returns no slugs when the filter matches nothing" do
        filters = JSON.generate([{ "name" => { "operator" => "~", "values" => ["zzz-no-match"] } }])
        get :search, params: { filters: }, format: :turbo_stream
        expect(assigns(:slugs)).to be_empty
      end
    end
  end

  describe "GET #confirm_dialog", with_settings: { work_packages_identifier: "classic" } do
    let!(:project) { create(:project, identifier: "current-id") }

    context "with a historically reserved slug" do
      let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

      it "responds with a turbo stream" do
        get :confirm_dialog, params: { id: slug.id }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      context "with an unknown id" do
        it "responds with a turbo stream error flash" do
          get :confirm_dialog, params: { id: 0 }, format: :turbo_stream
          expect(response).to have_http_status(:not_found)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include(I18n.t("admin.reserved_identifiers.identifier_not_found"))
        end
      end
    end

    context "when the slug is the project's own current active identifier" do
      let!(:slug) { project.slugs.find_by!(slug: "current-id") }

      it "responds with a turbo stream error flash because the slug is not historically reserved" do
        get :confirm_dialog, params: { id: slug.id }, format: :turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include(I18n.t("admin.reserved_identifiers.identifier_not_found"))
      end
    end
  end

  describe "DELETE #destroy", with_settings: { work_packages_identifier: "classic" } do
    let!(:project) { create(:project, identifier: "current-id") }
    let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

    it "destroys the slug and redirects with a flash notice" do
      expect { delete :destroy, params: { id: slug.id } }
        .to change(FriendlyId::Slug, :count).by(-1)

      expect(response).to redirect_to(admin_settings_project_reserved_identifiers_path)
      expect(flash[:notice]).to include("old-id")
    end

    context "with an unknown id" do
      it "responds with a turbo stream error flash" do
        delete :destroy, params: { id: 0 }, format: :turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include(I18n.t("admin.reserved_identifiers.identifier_not_found"))
      end
    end
  end
end
