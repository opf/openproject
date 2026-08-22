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

RSpec.describe "Admin LLM connection", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true } do
  let(:admin) { create(:admin) }
  let(:non_admin) { create(:user) }
  let(:base_url) { "https://example.com/v1" }
  let(:api_key_field) { "#llm_connection_api_key" }

  describe "with the feature flag off", with_flag: { llm_connection: false } do
    before { login_as admin }

    it "does not expose the endpoints" do
      get llm_connection_path
      expect(response).to have_http_status(:not_found)

      patch llm_connection_path, params: { llm_connection: { base_url: } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/llm_connection" do
    it "is not reachable for non-admins" do
      login_as non_admin
      get llm_connection_path

      expect(response).not_to have_http_status(:ok)
    end

    context "when logged in as admin" do
      before { login_as admin }

      it "renders without a connection configured" do
        get llm_connection_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Host URL")
      end

      it "does not claim that a key is stored before one is saved" do
        get llm_connection_path

        expect(response.body).not_to include("A key is stored")
        expect(page).to have_no_css("#{api_key_field}[placeholder]", visible: :all)
      end

      context "when an API key is stored" do
        let!(:connection) { create(:llm_connection, base_url:, api_key: "sk-original") }

        it "says that a key is stored and keeps the field blank" do
          get llm_connection_path

          expect(response.body).to include("A key is stored")
          expect(response.body).not_to include("sk-original")
        end

        it "marks the stored key in the field itself" do
          get llm_connection_path

          expect(page).to have_css("#{api_key_field}[placeholder='API key stored']", visible: :all)
          expect(page).to have_no_css("#{api_key_field}[value]", visible: :all)
        end
      end
    end
  end

  describe "PATCH /admin/llm_connection" do
    before { login_as admin }

    context "with a reachable server" do
      let!(:models_request) { mock_llm_models_response(base_url) }

      it "stores the connection" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

        expect(response).to have_http_status(:see_other)
        connection = LlmConnection.first
        expect(connection.base_url).to eq(base_url)
        expect(connection.api_key).to eq("sk-test")
      end

      it "confirms the connection once LLMs are switched on" do
        patch llm_connection_path,
              params: { llm_connection: { llm_features_enabled: "1", base_url:, api_key: "sk-test" } }

        expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.update.success"))
      end
    end

    context "when the administrator switches LLMs off" do
      let!(:connection) { create(:llm_connection, base_url:, api_key: "sk-test") }

      # Not with_settings:, which stubs Setting.[] and would hide the write.
      before { Setting.llm_features_enabled = true }

      it "confirms that the features are off instead of claiming a connection" do
        patch llm_connection_path, params: { llm_connection: { llm_features_enabled: "0" } }

        expect(Setting.llm_features_enabled?).to be(false)
        expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.update.disabled"))
        expect(flash[:warning]).to be_blank
      end
    end

    context "with an unreachable server" do
      let!(:models_request) { mock_llm_models_response(base_url, timeout: true) }

      it "persists nothing" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

        expect(LlmConnection.count).to eq(0)
      end

      it "renders the typed API key back into the form" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-typed" } }

        expect(response.body).to include('value="sk-typed"')
        expect(response.body).not_to include("A key is stored")
      end
    end

    # Reachability and credentials still gate the save; only the model list is
    # treated as optional.
    context "with rejected credentials" do
      let!(:models_request) { mock_llm_models_response(base_url, response_code: 401) }

      it "persists nothing" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-wrong" } }

        expect(LlmConnection.count).to eq(0)
      end
    end

    context "when an API key is already stored" do
      let!(:connection) { create(:llm_connection, base_url:, api_key: "sk-original") }
      let!(:models_request) { mock_llm_models_response(base_url) }

      it "keeps the stored key when the field is submitted blank" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "" } }

        expect(connection.reload.api_key).to eq("sk-original")
      end

      it "replaces the stored key when a new one is submitted" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-rotated" } }

        expect(connection.reload.api_key).to eq("sk-rotated")
      end
    end
  end

  describe "DELETE /admin/llm_connection/api_key" do
    before { login_as admin }

    it "removes the key but keeps the connection" do
      connection = create(:llm_connection, base_url:, api_key: "sk-original")

      delete api_key_llm_connection_path

      expect(response).to have_http_status(:see_other)
      expect(connection.reload.api_key).to be_nil
      expect(connection.base_url).to eq(base_url)
    end
  end

  describe "disconnecting" do
    let!(:connection) do
      create(:llm_connection, :enabled,
             base_url: "https://example.com/v1", api_key: "sk-test")
    end

    before { login_as admin }

    it "offers the confirmation, naming what is kept" do
      get disconnect_dialog_llm_connection_path,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Disconnect from the LLM server?")
    end

    # Disconnecting is reversible on purpose: destroying the connection would
    it "clears the credential and switches the connection off, keeping everything else" do
      post disconnect_llm_connection_path

      connection.reload
      expect(connection.api_key).to be_blank
      expect(connection).not_to be_enabled
      expect(connection.base_url).to eq("https://example.com/v1")
    end

    it "is refused to a non-admin" do
      login_as create(:user)

      post disconnect_llm_connection_path

      expect(connection.reload.api_key).to eq("sk-test")
    end
  end
end
