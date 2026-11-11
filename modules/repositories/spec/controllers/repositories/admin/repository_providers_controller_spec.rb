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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Repositories::Admin::RepositoryProvidersController do
  render_views

  let(:admin) { create(:admin) }

  before { login_as admin }

  describe "GET #index" do
    let!(:provider) { create(:repository_provider) }

    it "lists the providers" do
      get :index

      expect(response).to be_successful
      expect(response.body).to include(provider.name)
    end

    context "when not an admin" do
      before { login_as create(:user) }

      it "is forbidden" do
        get :index

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET #new" do
    it "renders the general information form for a new provider" do
      get :new, params: { provider_type: "gitlab" }

      expect(response).to be_successful
      expect(assigns(:provider)).to be_a(Repositories::GitlabProvider).and(be_new_record)
      expect(assigns(:target_step)).to eq(:general_information)
    end

    it "responds with not found for unknown provider types" do
      get :new, params: { provider_type: "svn" }

      expect(response).to have_http_status(:not_found)
    end

    context "when continuing the wizard" do
      let(:provider) { create(:repository_provider) }

      it "renders the next pending step" do
        get :new, params: { continue_wizard: provider.id }

        expect(response).to be_successful
        expect(assigns(:target_step)).to eq(:webhook_user)
      end

      it "generates the webhook secret when reaching the webhook step" do
        provider.update!(gitlab_user_id: nil)

        get :new, params: { continue_wizard: provider.id }

        expect(assigns(:target_step)).to eq(:webhook)
        expect(provider.reload.webhook_secret).to be_present
        expect(response.body).to include(provider.webhook_secret)
      end

      it "redirects to the provider once all steps are completed" do
        provider.update!(gitlab_user_id: nil, webhook_secret: "secret")

        get :new, params: { continue_wizard: provider.id }

        expect(response).to redirect_to(edit_admin_settings_repository_provider_path(provider))
      end
    end
  end

  describe "POST #create" do
    let(:params) do
      { provider_type: "gitlab", repositories_gitlab_provider: { name: "Our GitLab", url: "https://gitlab.example.com" } }
    end

    it "creates the provider and continues the wizard" do
      expect { post :create, params: }.to change(Repositories::GitlabProvider, :count).by(1)

      provider = Repositories::GitlabProvider.last
      expect(provider).to have_attributes(name: "Our GitLab", url: "https://gitlab.example.com")
      expect(response).to redirect_to(new_admin_settings_repository_provider_path(continue_wizard: provider.id))
    end

    context "with invalid params" do
      before { params[:repositories_gitlab_provider][:url] = "" }

      it "re-renders the form via turbo stream" do
        expect { post :create, params:, format: :turbo_stream }.not_to change(Repositories::Provider, :count)

        expect(response).to be_successful
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("repository_provider_general_information_section")
      end
    end
  end

  describe "GET #edit" do
    let(:provider) { create(:repository_provider, gitlab_user_id: admin.id, webhook_secret: "s3cret-value") }

    it "renders all steps" do
      get :edit, params: { id: provider.id }

      expect(response).to be_successful
      expect(response.body).to include(provider.name, admin.name)
      expect(response.body).not_to include("s3cret-value")
    end
  end

  describe "GET #edit_step" do
    let(:provider) { create(:repository_provider, webhook_secret: "s3cret") }

    it "renders the form of the step" do
      get :edit_step, params: { id: provider.id, step: "webhook" }, format: :turbo_stream

      expect(response).to be_successful
      expect(response.body).to include("repository_provider_webhook_section", "s3cret")
    end

    it "responds with not found for unknown steps" do
      get :edit_step, params: { id: provider.id, step: "oauth_client" }, format: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH #update" do
    let(:provider) { create(:repository_provider, gitlab_user_id: admin.id) }

    it "updates the attributes of the step and redirects to the provider" do
      patch :update, params: { id: provider.id, step: "general_information",
                               repositories_gitlab_provider: { name: "Renamed", url: "https://gitlab.example.org" } }

      expect(provider.reload).to have_attributes(name: "Renamed", url: "https://gitlab.example.org")
      expect(response).to redirect_to(edit_admin_settings_repository_provider_path(provider))
    end

    it "clears the webhook user when the autocompleter submits nothing" do
      patch :update, params: { id: provider.id, step: "webhook_user" }

      expect(provider.reload.gitlab_user_id).to be_nil
      expect(provider).to be_webhook_user_configured
    end

    it "ignores attributes of other steps" do
      patch :update, params: { id: provider.id, step: "webhook_user",
                               repositories_gitlab_provider: { gitlab_user_id: admin.id, name: "Renamed" } }

      expect(provider.reload.name).not_to eq("Renamed")
    end

    it "continues the wizard when requested" do
      patch :update, params: { id: provider.id, step: "webhook_user", continue_wizard: provider.id }

      expect(response).to redirect_to(new_admin_settings_repository_provider_path(continue_wizard: provider.id))
    end

    it "re-renders the form via turbo stream on errors" do
      patch :update, params: { id: provider.id, step: "general_information",
                               repositories_gitlab_provider: { name: "", url: provider.url } },
                     format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(provider.reload.name).to be_present
    end
  end

  describe "GET #confirm_regenerate_webhook_secret" do
    let(:provider) { create(:repository_provider, webhook_secret: "old-secret") }

    it "renders the confirmation dialog without touching the secret" do
      get :confirm_regenerate_webhook_secret, params: { id: provider.id }, format: :turbo_stream

      expect(response).to be_successful
      expect(response.body).to include("repository-provider-regenerate-webhook-secret-dialog")
      expect(provider.reload.webhook_secret).to eq("old-secret")
    end
  end

  describe "POST #regenerate_webhook_secret" do
    let(:provider) { create(:repository_provider, webhook_secret: "old-secret") }

    it "replaces the webhook secret" do
      post :regenerate_webhook_secret, params: { id: provider.id }, format: :turbo_stream

      expect(response).to be_successful
      expect(provider.reload.webhook_secret).not_to eq("old-secret")
      expect(response.body).to include(provider.webhook_secret)
    end
  end

  describe "GET #confirm_destroy" do
    let(:provider) { create(:repository_provider) }

    it "renders the confirmation dialog" do
      get :confirm_destroy, params: { id: provider.id }, format: :turbo_stream

      expect(response).to be_successful
      expect(response.body).to include("repository-provider-destroy-dialog")
    end
  end

  describe "DELETE #destroy" do
    let!(:provider) { create(:repository_provider) }

    it "deletes the provider" do
      expect { delete :destroy, params: { id: provider.id } }.to change(Repositories::Provider, :count).by(-1)

      expect(response).to redirect_to(admin_settings_repository_providers_path)
      expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
    end
  end
end
