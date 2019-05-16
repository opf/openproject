#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'

describe ::OpenIDConnect::ProvidersController, type: :controller do
  let(:user) { FactoryBot.build_stubbed :admin }

  let(:valid_params) do
    {
      name: 'azure',
      identifier: "IDENTIFIER",
      secret: "SECRET"
    }
  end

  before do
    login_as user
  end

  context 'when not admin' do
    let(:user) { FactoryBot.build_stubbed :user }

    it 'renders 403' do
      get :index
      expect(response.status).to eq 403
    end
  end

  context 'when not logged in' do
    let(:user) { User.anonymous }

    it 'renders 403' do
      get :index
      expect(response.status).to redirect_to(signin_url(back_url: openid_connect_providers_url))
    end
  end

  describe '#index' do
    it 'renders the index page' do
      get :index
      expect(response).to be_successful
      expect(response).to render_template 'index'
    end
  end

  describe '#new' do
    it 'renders the new page' do
      get :new
      expect(response).to be_successful
      expect(assigns[:provider]).to be_new_record
      expect(response).to render_template 'new'
    end

    it 'redirects to the index page if no provider available', with_settings: {
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

  describe '#create' do
    it 'is successful if valid params' do
      post :create, params: { openid_connect_provider: valid_params }
      expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
      expect(Setting.plugin_openproject_openid_connect["providers"]).to have_key("azure")
      expect(response).to be_redirect
    end

    it 'renders an error if invalid params' do
      post :create, params: { openid_connect_provider: valid_params.merge(identifier: "") }
      expect(response).to render_template 'new'
    end
  end

  describe '#edit' do
    context 'when found', with_settings: {
      plugin_openproject_openid_connect: {
        "providers" => { "azure" => { "identifier" => "IDENTIFIER", "secret" => "SECRET" } }
      }
    } do
      it 'renders the edit page' do
        get :edit, params: { id: 'azure' }
        expect(response).to be_successful
        expect(assigns[:provider]).to be_present
        expect(response).to render_template 'edit'
      end
    end

    context 'when not found' do
      it 'renders 404' do
        get :edit, params: { id: 'doesnoexist' }
        expect(response).not_to be_successful
        expect(response.status).to eq 404
      end
    end
  end

  describe '#update' do
    context 'when found', with_settings: {
      plugin_openproject_openid_connect: {
        "providers" => { "azure" => { "identifier" => "IDENTIFIER", "secret" => "SECRET" } }
      }
    } do
      it 'successfully updates the provider configuration' do
        put :update, params: { id: "azure", openid_connect_provider: valid_params.merge(secret: "NEWSECRET") }
        expect(response).to be_redirect
        expect(flash[:notice]).to be_present
        provider = OpenProject::OpenIDConnect.providers.find { |item| item.name == "azure" }
        expect(provider.secret).to eq("NEWSECRET")
      end
    end
  end

  describe '#destroy' do
    context 'when found', with_settings: {
      plugin_openproject_openid_connect: {
        "providers" => { "azure" => { "identifier" => "IDENTIFIER", "secret" => "SECRET" } }
      }
    } do

      it 'removes the provider' do
        delete :destroy, params: { id: "azure" }
        expect(response).to be_redirect
        expect(flash[:notice]).to be_present
        expect(OpenProject::OpenIDConnect.providers).to be_empty
      end
    end
  end
end
