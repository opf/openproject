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
  let(:remove_api_key) { "[data-test-selector='llm-connection--remove-api-key']" }

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
        expect(page).to have_no_css(remove_api_key, visible: :all)
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

        it "offers to remove the key beside the field" do
          get llm_connection_path

          expect(page).to have_css(remove_api_key, text: "Remove key", visible: :all)
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

      it "fills the catalogue once when none is stored" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

        expect(LlmConnection.first.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
      end

      it "confirms the connection once LLMs are switched on" do
        patch llm_connection_path,
              params: { llm_connection: { llm_features_enabled: "1", base_url:, api_key: "sk-test" } }

        expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.update.success"))
      end

      context "when models are already stored" do
        let!(:connection) { create(:llm_connection, :with_models, base_url:, api_key: "sk-test") }

        before do
          connection.update!(connection_fingerprint: connection.settings_fingerprint)
          connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                                 state: "supported", source: "admin", checked_at: Time.current)
        end

        it "leaves the stored catalogue alone when the host URL changes" do
          elsewhere = "https://elsewhere.example/v1"
          mock_llm_models_response(elsewhere, models: [{ id: "llama4-8b", object: "model", owned_by: "vllm" }])

          patch llm_connection_path, params: { llm_connection: { base_url: elsewhere } }

          connection.reload
          expect(connection.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
          expect(connection.capability_verdicts.pluck(:source)).to eq(["admin"])
          expect(connection).to be_models_stale
        end
      end
    end

    # The case that matters for OpenProject's own gateway: chat completions are
    # routed, the model list is not.
    context "with a server that exposes no model list" do
      let!(:models_request) { mock_llm_models_response(base_url, response_code: 404) }

      it "still saves the connection and says models must be added by hand" do
        patch llm_connection_path,
              params: { llm_connection: { llm_features_enabled: "1", base_url:, api_key: "sk-test" } }

        expect(response).to have_http_status(:see_other)
        expect(LlmConnection.first.base_url).to eq(base_url)
        expect(flash[:warning]).to be_present
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

      context "when the stored connection has no key" do
        let!(:connection) { create(:llm_connection, base_url:, api_key: nil) }

        it "does not offer to remove a key that was only typed" do
          patch llm_connection_path,
                params: { llm_connection: { base_url:, api_key: "sk-typed" } },
                headers: { "Accept" => "text/html" }

          expect(response.body).to include('value="sk-typed"')
          expect(response.body).not_to include("llm-connection--delete-api-key")
          expect(page).to have_no_css(remove_api_key, visible: :all)
        end
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

    it "renders the page after removal exactly as on first load" do
      create(:llm_connection, base_url:, api_key: "sk-original")

      delete api_key_llm_connection_path
      get llm_connection_path

      expect(response.body).not_to include("A key is stored")
      expect(response.body).not_to include("llm-connection--delete-api-key")
      expect(page).to have_no_css(remove_api_key, visible: :all)
    end
  end

  describe "GET /admin/llm_connection/delete_api_key_dialog" do
    let!(:connection) { create(:llm_connection, base_url: "https://example.com/v1", api_key: "sk-test") }

    before { login_as admin }

    it "offers the confirmation" do
      # Requested by the async-dialog Stimulus controller, which asks for a
      # turbo stream rather than HTML.
      get delete_api_key_dialog_llm_connection_path,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Remove the stored API key?")
    end

    # The catalogue sync fingerprints base_url and api_key together, so changing
    # the key discards every verdict -- including hand-made ones, which nothing
    # else throws away.
    it "warns when hand-made capability assertions would be lost" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                             state: "supported", source: "admin",
                                             checked_at: Time.current)

      get delete_api_key_dialog_llm_connection_path,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("assertions you made yourself")
    end
  end

  describe "disconnecting" do
    let!(:connection) do
      create(:llm_connection, :with_models,
             base_url: "https://example.com/v1", api_key: "sk-test")
    end

    before do
      login_as admin
      # Not with_settings:, which stubs Setting.[] and would hide the write.
      Setting.llm_features_enabled = true
    end

    it "offers the confirmation, naming what is kept" do
      get disconnect_dialog_llm_connection_path,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Disconnect from the LLM server?")
    end

    it "clears the credential and switches the connection off, keeping everything else" do
      post disconnect_llm_connection_path

      connection.reload
      expect(connection.api_key).to be_blank
      expect(Setting.llm_features_enabled?).to be(false)
      expect(connection.base_url).to eq("https://example.com/v1")
      expect(connection.models.count).to eq(2)
    end

    it "is refused to a non-admin" do
      login_as create(:user)

      post disconnect_llm_connection_path

      expect(connection.reload.api_key).to eq("sk-test")
    end
  end
end
