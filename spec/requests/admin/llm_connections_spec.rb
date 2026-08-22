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

      it "lists the cached models without contacting the server" do
        create(:llm_connection, :with_models, base_url:)

        get llm_connection_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("qwen3.6-27b")
        expect(a_request(:get, "#{base_url}/models")).not_to have_been_made
      end
    end
  end

  describe "PATCH /admin/llm_connection" do
    before { login_as admin }

    context "with a reachable server" do
      let!(:models_request) { mock_llm_models_response(base_url) }

      it "stores the connection and caches the catalogue" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

        expect(response).to have_http_status(:see_other)
        connection = LlmConnection.first
        expect(connection.base_url).to eq(base_url)
        expect(connection.api_key).to eq("sk-test")
        expect(connection.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
      end
    end

    # The case that matters for OpenProject's own gateway: chat completions are
    # routed, the model list is not.
    context "with a server that exposes no model list" do
      let!(:models_request) { mock_llm_models_response(base_url, response_code: 404) }

      it "still saves the connection and says models must be added by hand" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

        expect(response).to have_http_status(:see_other)
        expect(LlmConnection.first.base_url).to eq(base_url)
        expect(flash[:warning]).to be_present
      end
    end

    context "with an unreachable server" do
      let!(:models_request) { mock_llm_models_response(base_url, timeout: true) }

      it "persists nothing" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

        expect(LlmConnection.count).to eq(0)
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

  describe "POST /admin/llm_connection/refresh_models" do
    before { login_as admin }

    it "refetches the catalogue" do
      create(:llm_connection, base_url:)
      request = mock_llm_models_response(base_url)

      post refresh_models_llm_connection_path

      expect(request).to have_been_made.once
      expect(LlmConnection.first.available_model_ids).to include("bge-m3")
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
      create(:llm_connection, :with_models, :enabled,
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
      expect(connection.models.count).to eq(2)
    end

    it "is refused to a non-admin" do
      login_as create(:user)

      post disconnect_llm_connection_path

      expect(connection.reload.api_key).to eq("sk-test")
    end
  end

  describe "paginating the model list" do
    let!(:connection) { create(:llm_connection, :enabled, base_url: "https://example.com/v1") }

    before do
      login_as admin
      # A gateway can report hundreds; OpenRouter returns 341.
      25.times { |n| create(:llm_model, llm_connection: connection, external_id: format("model-%03d", n)) }
    end

    # Counted by row, not by model id: the default-model select still lists
    # every model, so the ids appear in the body regardless of the table.
    def rendered_rows(body) = body.scan("llm-model--toggle-").size

    it "shows one page of rows at a time rather than every model" do
      get llm_connection_path, params: { per_page: 20 }

      expect(rendered_rows(response.body)).to eq(20)
      expect(response.body).to include("op-pagination")
    end

    it "serves the remainder on the next page" do
      get llm_connection_path, params: { per_page: 20, page: 2 }

      expect(rendered_rows(response.body)).to eq(5)
    end
  end

  describe "filtering the model list" do
    let!(:connection) { create(:llm_connection, :enabled, base_url: "https://example.com/v1") }
    let(:filters) { [{ name: { operator: "~", values: ["bge"] } }].to_json }

    before do
      login_as admin
      create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b")
      create(:llm_model, llm_connection: connection, external_id: "bge-m3")
      create(:llm_model, llm_connection: connection, external_id: "e5-large", display_name: "BGE compatible")
    end

    def rendered_rows(body) = body.scan("llm-model--toggle-").size

    it "narrows the table to matching models" do
      get search_models_llm_connection_path, params: { filters: }

      expect(response).to have_http_status(:ok)
      # The identifier and the friendly name both match, since either is what
      # somebody would type.
      expect(rendered_rows(response.body)).to eq(2)
      expect(response.body).to include("bge-m3")
    end

    it "answers with a turbo stream so only the table is replaced" do
      get search_models_llm_connection_path, params: { filters: }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "applies the filter to the full page too, so a shared link works" do
      get llm_connection_path, params: { filters: }

      expect(rendered_rows(response.body)).to eq(2)
    end

    it "shows everything without a filter" do
      get llm_connection_path

      expect(rendered_rows(response.body)).to eq(3)
    end
  end
end
