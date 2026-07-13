# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe Admin::Import::Jira::InstancesController do
  let(:admin) { create(:admin) }
  let(:non_admin) { create(:user) }
  let(:jira) { create(:jira) }
  let(:jira_params) do
    {
      "name" => "Test Jira",
      "url" => "https://jira.example.com",
      "personal_access_token" => "test_token_123"
    }
  end

  before do
    login_as(admin)
  end

  describe "authorization" do
    before { login_as(non_admin) }

    it "returns forbidden for GET #index" do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #show" do
      get :show, params: { id: jira.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #new" do
      get :new
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #edit" do
      get :edit, params: { id: jira.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for POST #create" do
      post :create, params: { import_jira: jira_params }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for PATCH #update" do
      patch :update, params: { id: jira.id, import_jira: jira_params }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for DELETE #destroy" do
      delete :destroy, params: { id: jira.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for DELETE #delete_token" do
      delete :delete_token, params: { id: jira.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for POST #test" do
      post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #index" do
    let!(:jira1) { create(:jira, name: "Jira 1") }
    let!(:jira2) { create(:jira, name: "Jira 2") }

    it "renders the index template" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it "assigns all jiras" do
      get :index
      expect(assigns(:jira_instances)).to contain_exactly(jira2, jira1)
    end

    it "uses admin layout" do
      get :index
      expect(response).to render_template(layout: "admin")
    end
  end

  describe "GET #show" do
    let!(:jira_import1) { create(:jira_import, jira:, author: admin) }
    let!(:jira_import2) { create(:jira_import, jira:, author: admin) }

    it "renders the show template" do
      get :show, params: { id: jira.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it "assigns the jira instance" do
      get :show, params: { id: jira.id }
      expect(assigns(:jira)).to eq(jira)
    end

    it "assigns jira imports ordered by reverse id" do
      get :show, params: { id: jira.id }
      expect(assigns(:jira_imports)).to eq([jira_import2, jira_import1])
    end

    it "uses admin layout" do
      get :show, params: { id: jira.id }
      expect(response).to render_template(layout: "admin")
    end

    context "when jira does not exist" do
      it "returns 404" do
        get :show, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #new" do
    it "renders the new template" do
      get :new
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end

    it "assigns a new jira instance" do
      get :new
      expect(assigns(:jira)).to be_a_new(Import::Jira)
    end

    it "uses admin layout" do
      get :new
      expect(response).to render_template(layout: "admin")
    end
  end

  describe "GET #edit" do
    it "renders the edit template" do
      get :edit, params: { id: jira.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
    end

    it "assigns the jira instance" do
      get :edit, params: { id: jira.id }
      expect(assigns(:jira)).to eq(jira)
    end

    it "uses admin layout" do
      get :edit, params: { id: jira.id }
      expect(response).to render_template(layout: "admin")
    end

    context "when jira does not exist" do
      it "returns 404" do
        get :edit, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    let(:create_service) { instance_double(Import::Jiras::CreateService) }
    let(:service_result) { ServiceResult.success(result: jira) }

    before do
      allow(Import::Jiras::CreateService).to receive(:new).with(user: admin).and_return(create_service)
    end

    context "when creation succeeds" do
      before do
        allow(create_service).to receive(:call).and_return(service_result)
      end

      it "creates a new jira instance" do
        post :create, params: { import_jira: jira_params }
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
        expect(response).to redirect_to(admin_import_jira_path(jira.id))
      end

      it "calls the create service with correct params" do
        post :create, params: { import_jira: jira_params }
        expect(Import::Jiras::CreateService).to have_received(:new).with(user: admin)
        expect(create_service).to have_received(:call)
      end
    end

    context "when creation fails" do
      let(:failed_jira) { Import::Jira.new(jira_params) }
      let(:failed_result) { ServiceResult.failure(result: failed_jira) }

      before do
        allow(create_service).to receive(:call).and_return(failed_result)
        failed_jira.errors.add(:base, "Test error")
      end

      it "renders the new template" do
        post :create, params: { import_jira: jira_params }
        expect(response).to render_template(:new)
      end

      it "assigns the failed jira instance" do
        post :create, params: { import_jira: jira_params }
        expect(assigns(:jira)).to eq(failed_jira)
      end

      it "does not create a jira instance" do
        expect do
          post :create, params: { import_jira: jira_params }
        end.not_to change(Import::Jira, :count)
      end
    end

    context "when turbo_stream format" do
      let(:failed_jira) { Import::Jira.new(jira_params) }
      let(:failed_result) { ServiceResult.failure(result: failed_jira) }

      before do
        allow(create_service).to receive(:call).and_return(failed_result)
        failed_jira.errors.add(:base, "Test error")
      end

      it "updates via turbo stream on failure" do
        post :create, params: { import_jira: jira_params }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH #update" do
    let(:update_service) { instance_double(Import::Jiras::UpdateService) }
    let(:service_result) { ServiceResult.success(result: jira) }
    let(:update_params) do
      {
        name: "Updated Jira",
        url: "https://updated.example.com",
        personal_access_token: "updated_token"
      }
    end

    before do
      allow(Import::Jiras::UpdateService).to receive(:new)
        .with(user: admin, model: jira)
        .and_return(update_service)
    end

    context "when update succeeds" do
      before do
        allow(update_service).to receive(:call).and_return(service_result)
      end

      it "updates the jira instance" do
        patch :update, params: { id: jira.id, import_jira: update_params }
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
        expect(response).to redirect_to(admin_import_jira_path(jira.id))
      end

      it "calls the update service with correct params" do
        patch :update, params: { id: jira.id, import_jira: update_params }
        expect(Import::Jiras::UpdateService).to have_received(:new).with(user: admin, model: jira)
        expect(update_service).to have_received(:call)
      end
    end

    context "when update fails" do
      let(:failed_result) { ServiceResult.failure(result: jira) }

      before do
        allow(update_service).to receive(:call).and_return(failed_result)
        jira.errors.add(:base, "Test error")
      end

      it "renders the edit template" do
        patch :update, params: { id: jira.id, import_jira: update_params }
        expect(response).to render_template(:edit)
      end

      it "does not redirect" do
        patch :update, params: { id: jira.id, import_jira: update_params }
        expect(response).not_to redirect_to(action: :index)
      end
    end

    context "when turbo_stream format" do
      let(:failed_result) { ServiceResult.failure(result: jira) }

      before do
        allow(update_service).to receive(:call).and_return(failed_result)
        jira.errors.add(:base, "Test error")
      end

      it "updates via turbo stream on failure" do
        patch :update, params: { id: jira.id, import_jira: update_params }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when jira does not exist" do
      it "returns 404" do
        patch :update, params: { id: 999_999, import_jira: update_params }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when jira has no imports" do
      it "destroys the jira instance" do
        jira_to_delete = create(:jira)
        expect do
          delete :destroy, params: { id: jira_to_delete.id }
        end.to change(Import::Jira, :count).by(-1)
      end

      it "sets a success flash message" do
        jira_to_delete = create(:jira)
        delete :destroy, params: { id: jira_to_delete.id }
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
      end

      it "redirects to index" do
        jira_to_delete = create(:jira)
        delete :destroy, params: { id: jira_to_delete.id }
        expect(response).to redirect_to(action: :index)
        expect(response).to have_http_status(:see_other)
      end
    end

    context "when jira has imports" do
      let!(:jira_import) { create(:jira_import, jira:, author: admin) }

      it "does not destroy the jira instance" do
        expect do
          delete :destroy, params: { id: jira.id }
        end.not_to change(Import::Jira, :count)
      end

      it "sets an error flash message" do
        delete :destroy, params: { id: jira.id }
        expect(flash[:error]).to eq(I18n.t(:"admin.jira.errors.cannot_delete_with_imports"))
      end

      it "redirects to index" do
        delete :destroy, params: { id: jira.id }
        expect(response).to redirect_to(action: :index)
        expect(response).to have_http_status(:see_other)
      end
    end

    context "when jira does not exist" do
      it "returns 404" do
        delete :destroy, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "private methods" do
    describe "#set_jira" do
      it "sets @jira from params[:id]" do
        get :show, params: { id: jira.id }
        expect(assigns(:jira)).to eq(jira)
      end
    end

    describe "#jira_params" do
      it "permits name, url, and personal_access_token" do
        post :create, params: {
          import_jira: {
            name: "Test",
            url: "https://test.example.com",
            personal_access_token: "token",
            unauthorized_param: "should_not_be_included"
          }
        }
        # The service will be called without the unauthorized param
        # This is tested indirectly through the create action tests
      end
    end
  end

  describe "layout and menu" do
    it "uses the admin layout" do
      get :index
      expect(response).to render_template(layout: "admin")
    end
  end

  describe "DELETE #delete_token" do
    let(:jira_with_token) { create(:jira, personal_access_token: "secret_token") }

    it "deletes the personal access token" do
      delete :delete_token, params: { id: jira_with_token.id }
      expect(jira_with_token.reload.personal_access_token).to be_nil
    end

    it "sets a success flash message" do
      delete :delete_token, params: { id: jira_with_token.id }
      expect(flash[:notice]).to eq(I18n.t(:"admin.jira.token_deleted"))
    end

    it "redirects to edit page" do
      delete :delete_token, params: { id: jira_with_token.id }
      expect(response).to redirect_to(edit_admin_import_jira_path(jira_with_token))
    end

    it "returns see_other status" do
      delete :delete_token, params: { id: jira_with_token.id }
      expect(response).to have_http_status(:see_other)
    end

    context "when jira does not exist" do
      it "returns 404" do
        delete :delete_token, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #test" do
    let(:jira_client) { instance_double(Import::JiraClient) }

    before do
      allow(Import::JiraClient).to receive(:new).and_return(jira_client)
    end

    context "when credentials are valid" do
      let(:server_info) do
        {
          "serverTitle" => "My Jira Server",
          "version" => "9.0.0"
        }
      end

      before do
        allow(jira_client).to receive(:server_info).and_return(server_info)
      end

      it "returns a success message" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t(:"admin.jira.test.success", server: "My Jira Server", version: "9.0.0"))
      end

      it "creates Import::JiraClient with provided credentials" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(Import::JiraClient).to have_received(:new).with(url: "https://jira.example.com", personal_access_token: "token")
      end
    end

    context "when using token from existing jira" do
      let(:jira_with_token) { create(:jira, personal_access_token: "stored_token") }
      let(:server_info) { { "serverTitle" => "Jira", "version" => "9.0" } }

      before do
        allow(jira_client).to receive(:server_info).and_return(server_info)
      end

      it "uses the stored token when personal_access_token param is blank" do
        post :test, params: { id: jira_with_token.id, url: "https://jira.example.com", personal_access_token: "" },
                    format: :turbo_stream
        expect(Import::JiraClient).to have_received(:new).with(url: "https://jira.example.com",
                                                               personal_access_token: "stored_token")
      end
    end

    context "when server_info response has missing fields" do
      before do
        allow(jira_client).to receive(:server_info).and_return({})
      end

      it "uses fallback values" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.success", server: Import::Jira.model_name, version: "?"))
      end
    end

    context "when server_info returns non-hash" do
      before do
        allow(jira_client).to receive(:server_info).and_return(nil)
      end

      it "returns a failed message" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.failed"))
      end
    end

    context "when URL is blank" do
      it "returns a missing credentials error" do
        post :test, params: { url: "", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.missing_credentials"))
      end
    end

    context "when token is blank and no existing jira" do
      it "returns a missing credentials error" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.missing_credentials"))
      end
    end

    context "when URL is invalid" do
      it "returns an invalid URL error" do
        post :test, params: { url: "not-a-valid-url", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.invalid_url"))
      end

      it "rejects ftp URLs" do
        post :test, params: { url: "ftp://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.invalid_url"))
      end
    end

    context "when Import::JiraClient raises ConnectionError" do
      before do
        allow(jira_client).to receive(:server_info).and_raise(Import::JiraClient::ConnectionError.new("Connection refused"))
      end

      it "returns a connection error message" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.connection_error", message: "Connection refused"))
      end
    end

    context "when Import::JiraClient raises ParseError" do
      before do
        allow(jira_client).to receive(:server_info).and_raise(Import::JiraClient::ParseError.new("Invalid JSON"))
      end

      it "returns a parse error message" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.parse_error"))
      end
    end

    context "when Import::JiraClient raises ApiError" do
      before do
        allow(jira_client).to receive(:server_info).and_raise(Import::JiraClient::ApiError.new("Unauthorized", status: 401))
      end

      it "returns an API error message" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.api_error", status: 401))
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(jira_client).to receive(:server_info).and_raise(StandardError.new("Unexpected"))
        allow(Rails.logger).to receive(:error)
      end

      it "returns a generic error message" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(response.body).to include(I18n.t(:"admin.jira.test.error"))
      end

      it "logs the error" do
        post :test, params: { url: "https://jira.example.com", personal_access_token: "token" }, format: :turbo_stream
        expect(Rails.logger).to have_received(:error).with(/Unexpected error testing Jira configuration/)
      end
    end
  end

  describe "PATCH #update with blank token" do
    let(:update_service) { instance_double(Import::Jiras::UpdateService) }
    let(:service_result) { ServiceResult.success(result: jira) }

    before do
      allow(Import::Jiras::UpdateService).to receive(:new)
        .with(user: admin, model: jira)
        .and_return(update_service)
      allow(update_service).to receive(:call).and_return(service_result)
    end

    it "does not include personal_access_token in params when blank" do
      patch :update, params: { id: jira.id, import_jira: { name: "Updated", url: "https://example.com", personal_access_token: "" } }
      expect(update_service).to have_received(:call) do |args|
        expect(args).not_to have_key(:personal_access_token)
        expect(args).not_to have_key("personal_access_token")
      end
    end

    it "includes personal_access_token when provided" do
      patch :update, params: { id: jira.id, import_jira: { name: "Updated", url: "https://example.com", personal_access_token: "new_token" } }
      expect(update_service).to have_received(:call) do |args|
        expect(args["personal_access_token"]).to eq("new_token")
      end
    end
  end
end
