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
    shared_examples "lists reserved slugs of all formats" do
      let!(:project) { create(:project) }

      before do
        FriendlyId::Slug.create!(sluggable: project, slug: "old-classic")
        FriendlyId::Slug.create!(sluggable: project, slug: "OLDPROJ")
        FriendlyId::Slug.create!(sluggable: project, slug: "12345")
      end

      it "responds 200" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "includes classic-format and semantic-format slugs, excluding pure-numeric ones" do
        get :index
        expect(assigns(:slugs).map(&:slug)).to include("old-classic", "OLDPROJ")
        expect(assigns(:slugs).map(&:slug)).not_to include("12345")
      end
    end

    context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it_behaves_like "lists reserved slugs of all formats"
    end

    context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
      it_behaves_like "lists reserved slugs of all formats"
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

    describe "work package warning" do
      render_views

      let!(:project) { create(:project) }
      let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

      context "with affected work packages" do
        before do
          create(:work_package_semantic_alias, identifier: "old-id-1")
          create(:work_package_semantic_alias, identifier: "old-id-2")
        end

        %w[semantic classic].each do |mode|
          context "in #{mode} mode", with_settings: { work_packages_identifier: mode } do
            it "shows the warning with the affected work package count" do
              get :confirm_dialog, params: { id: slug.id }, format: :turbo_stream
              expect(response.body)
                .to include(I18n.t("admin.reserved_identifiers.dialog.description_with_work_packages", count: 2))
            end
          end
        end
      end

      context "without affected work packages" do
        it "does not show the warning" do
          get :confirm_dialog, params: { id: slug.id }, format: :turbo_stream
          expect(response.body).not_to include("work package")
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:project) { create(:project) }
    let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

    context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "destroys the slug and redirects with a flash notice" do
        expect { delete :destroy, params: { id: slug.id } }
          .to change(FriendlyId::Slug, :count).by(-1)

        expect(response).to redirect_to(admin_settings_project_reserved_identifiers_path)
        expect(flash[:notice]).to include("old-id")
      end

      it "also deletes work package aliases left over from a previous semantic phase" do
        create(:work_package_semantic_alias, identifier: "old-id-1")

        expect { delete :destroy, params: { id: slug.id } }
          .to change(WorkPackageSemanticAlias, :count).by(-1)
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

    # Exact-prefix and case-sensitivity edge cases live in the service and
    # scope specs; this guards the formerly mode-gated endpoint end to end.
    context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "destroys the slug and deletes its aliases" do
        create(:work_package_semantic_alias, identifier: "old-id-1")

        expect { delete :destroy, params: { id: slug.id } }
          .to change(FriendlyId::Slug, :count).by(-1)
          .and change(WorkPackageSemanticAlias, :count).by(-1)

        expect(response).to redirect_to(admin_settings_project_reserved_identifiers_path)
        expect(flash[:notice]).to include("old-id")
      end
    end
  end
end
