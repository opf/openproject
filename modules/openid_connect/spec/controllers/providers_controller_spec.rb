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

RSpec.describe OpenIDConnect::ProvidersController do
  let(:user) { build_stubbed(:admin) }

  let(:valid_params) do
    {
      name: "azure",
      identifier: "IDENTIFIER",
      secret: "SECRET"
    }
  end

  before do
    login_as user
  end

  context "without an EE token", with_ee: false do
    it "renders upsale" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(response).to render_template "openid_connect/providers/upsale"
    end
  end

  context "with an EE token", with_ee: %i[openid_providers] do
    before do
      login_as user
    end

    context "when not admin" do
      let(:user) { build_stubbed(:user) }

      it "renders 403" do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not logged in" do
      let(:user) { User.anonymous }

      it "renders 403" do
        get :index
        expect(response.status).to redirect_to(signin_url(back_url: openid_connect_providers_url))
      end
    end

    describe "#index" do
      it "renders the index page" do
        get :index
        expect(response).to be_successful
        expect(response).to render_template "index"
      end
    end

    describe "#new" do
      it "renders the new page" do
        get :new
        expect(response).to be_successful
        expect(assigns[:provider]).to be_new_record
        expect(response).to render_template "new"
      end

      it "redirects to the index page if no provider available", with_settings: {
        plugin_openproject_openid_connect: {
          "providers" => OpenIDConnect::Provider::ALLOWED_TYPES.inject({}) do |accu, name|
            accu.merge(name => { "identifier" => "IDENTIFIER", "secret" => "SECRET" })
          end
        }
      } do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "#create" do
      context "with valid params" do
        let(:params) { { openid_connect_provider: valid_params } }

        before do
          post :create, params:
        end

        it "is successful" do
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
          expect(Setting.plugin_openproject_openid_connect["providers"]).to have_key("azure")
          expect(response).to be_redirect
        end

        context "with limit_self_registration checked" do
          let(:params) do
            { openid_connect_provider: valid_params.merge(limit_self_registration: 1) }
          end

          it "sets the setting" do
            expect(OpenProject::Plugins::AuthPlugin)
              .to be_limit_self_registration provider: valid_params[:name]
          end
        end

        context "with limit_self_registration unchecked" do
          let(:params) do
            { openid_connect_provider: valid_params.merge(limit_self_registration: 0) }
          end

          it "does not set the setting" do
            expect(OpenProject::Plugins::AuthPlugin)
              .not_to be_limit_self_registration provider: valid_params[:name]
          end
        end
      end

      it "renders an error if invalid params" do
        post :create, params: { openid_connect_provider: valid_params.merge(identifier: "") }
        expect(response).to render_template "new"
      end
    end

    describe "#edit" do
      context "when found", with_settings: {
        plugin_openproject_openid_connect: {
          "providers" => { "azure" => { "identifier" => "IDENTIFIER", "secret" => "SECRET" } }
        }
      } do
        it "renders the edit page" do
          get :edit, params: { id: "azure" }
          expect(response).to be_successful
          expect(assigns[:provider]).to be_present
          expect(response).to render_template "edit"
        end

        context(
          "with limit_self_registration set",
          with_settings: {
            plugin_openproject_openid_connect: {
              "providers" => {
                "azure" => {
                  "identifier" => "IDENTIFIER",
                  "secret" => "SECRET",
                  "limit_self_registration" => true
                }
              }
            }
          }
        ) do
          before do
            get :edit, params: { id: "azure" }
          end

          it "shows limit_self_registration as checked" do
            expect(assigns[:provider]).to be_limit_self_registration
          end
        end

        context "with limit_self_registration not set" do
          before do
            get :edit, params: { id: "azure" }
          end

          it "shows limit_self_registration as checked" do
            expect(assigns[:provider]).to be_limit_self_registration
          end
        end
      end

      context "when not found" do
        it "renders 404" do
          get :edit, params: { id: "doesnoexist" }
          expect(response).not_to be_successful
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#update" do
      context "when found" do
        before do
          Setting.plugin_openproject_openid_connect = {
            "providers" => { "azure" => { "identifier" => "IDENTIFIER", "secret" => "SECRET" } }
          }
        end

        it "successfully updates the provider configuration" do
          put :update, params: { id: "azure", openid_connect_provider: valid_params.merge(secret: "NEWSECRET") }
          expect(response).to be_redirect
          expect(flash[:notice]).to be_present
          provider = OpenProject::OpenIDConnect.providers.find { |item| item.name == "azure" }
          expect(provider.secret).to eq("NEWSECRET")
        end

        context "with limit_self_registration checked" do
          let(:params) do
            { id: "azure", openid_connect_provider: valid_params.merge(limit_self_registration: 1) }
          end

          it "sets the setting" do
            put(:update, params:)

            expect(OpenProject::Plugins::AuthPlugin)
              .to be_limit_self_registration provider: :azure
            provider = OpenProject::OpenIDConnect.providers.find { |item| item.name == "azure" }
            expect(provider.limit_self_registration).to be true
          end
        end

        context "with limit_self_registration unchecked" do
          let(:params) do
            { id: :azure, openid_connect_provider: valid_params.merge(limit_self_registration: 0) }
          end

          it "does not set the setting" do
            put(:update, params:)

            expect(OpenProject::Plugins::AuthPlugin)
              .not_to be_limit_self_registration provider: valid_params[:name]

            provider = OpenProject::OpenIDConnect.providers.find { |item| item.name == "azure" }
            expect(provider.limit_self_registration).to be false
          end
        end
      end
    end

    describe "#destroy" do
      context "when found" do
        before do
          Setting.plugin_openproject_openid_connect = {
            "providers" => { "azure" => { "identifier" => "IDENTIFIER", "secret" => "SECRET" } }
          }
        end

        it "removes the provider" do
          delete :destroy, params: { id: "azure" }
          expect(response).to be_redirect
          expect(flash[:notice]).to be_present
          expect(OpenProject::OpenIDConnect.providers).to be_empty
        end
      end
    end
  end
end
