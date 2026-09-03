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

RSpec.describe "Admin LLM models", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true } do
  let(:admin) { create(:admin) }
  let(:base_url) { "https://example.com/v1" }

  describe "with the feature flag off", with_flag: { llm_connection: false } do
    before { login_as admin }

    it "does not expose the endpoints" do
      get llm_models_path
      expect(response).to have_http_status(:not_found)

      post refresh_llm_models_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/llm_models" do
    it "is not reachable for non-admins" do
      login_as create(:user)
      get llm_models_path

      expect(response).not_to have_http_status(:ok)
    end

    context "when logged in as admin" do
      before { login_as admin }

      it "lists the cached models without contacting the server" do
        create(:llm_connection, :with_models, :enabled, base_url:)

        get llm_models_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("qwen3.6-27b")
        expect(a_request(:get, "#{base_url}/models")).not_to have_been_made
      end

      it "warns that the list predates the current settings" do
        connection = create(:llm_connection, :with_models, :enabled, base_url:)
        connection.update!(connection_fingerprint: connection.settings_fingerprint)
        connection.update!(api_key: "rotated")

        get llm_models_path

        expect(response.body).to include("llm-models--stale")
      end

      it "does not warn while the list matches the settings" do
        connection = create(:llm_connection, :with_models, :enabled, base_url:)
        connection.update!(connection_fingerprint: connection.settings_fingerprint)

        get llm_models_path

        expect(response.body).not_to include("llm-models--stale")
      end

      it "shows every model as either a chat or an embedding model" do
        connection = create(:llm_connection, :enabled, base_url:)
        create(:llm_model, llm_connection: connection, external_id: "bge-m3")
        create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b")
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "probe", checked_at: Time.current)

        get llm_models_path

        expect(response.body).to include("Embedding")
        expect(response.body).to include("Chat")
        expect(response.body).not_to include("Unknown")
      end

      it "keeps a long model name readable through the truncation" do
        connection = create(:llm_connection, :enabled, base_url:)
        long_name = "publisher/a-very-long-model-name-that-does-not-fit-the-column-32b-instruct-2026-05"
        create(:llm_model, llm_connection: connection, external_id: long_name)

        get llm_models_path

        expect(response.body).to include("Truncate-text--expandable")
        expect(response.body).to include("title=\"#{long_name}\"")
      end

      it "keeps the source label short and spells it out on hover" do
        connection = create(:llm_connection, :enabled, base_url:)
        create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b")

        get llm_models_path

        cell = page.find(".op-border-box-grid__row-item.source")
        expect(cell[:class]).to include("-no-ellipsis")
        expect(cell.find(".Label").text).to eq("Server")
        expect(cell.find(".Label")[:title]).to eq("Reported by the server")
      end

      it "sends the administrator to the settings while the connection is disabled" do
        create(:llm_connection, :with_models, base_url:)

        get llm_models_path

        expect(response).to redirect_to(llm_connection_path)
        expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.disabled_notice"))
      end

      it "sends the administrator to the settings while no connection is stored" do
        get llm_models_path

        expect(response).to redirect_to(llm_connection_path)
      end
    end
  end

  describe "POST /admin/llm_models/refresh" do
    let!(:connection) { create(:llm_connection, :enabled, base_url:) }

    before { login_as admin }

    it "fetches the model list again" do
      mock_llm_models_response(base_url)

      post refresh_llm_models_path

      expect(response).to redirect_to(llm_models_path)
      expect(connection.reload.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
      expect(flash[:notice]).to eq("The model list has been refreshed.")
    end

    it "says so when the server cannot be reached" do
      mock_llm_models_response(base_url, timeout: true)

      post refresh_llm_models_path

      expect(response).to redirect_to(llm_models_path)
      expect(flash[:error]).to be_present
    end
  end

  describe "paginating the model list" do
    let!(:connection) { create(:llm_connection, :enabled, base_url: "https://example.com/v1") }

    before do
      login_as admin
      # A gateway can report hundreds; OpenRouter returns 341.
      25.times { |n| create(:llm_model, llm_connection: connection, external_id: format("model-%03d", n)) }
    end

    def rendered_rows(body) = body.scan(/model-\d{3}/).uniq.size

    it "shows one page of rows at a time rather than every model" do
      get llm_models_path, params: { per_page: 20 }

      expect(rendered_rows(response.body)).to eq(20)
      expect(response.body).to include("op-pagination")
    end

    it "serves the remainder on the next page" do
      get llm_models_path, params: { per_page: 20, page: 2 }

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

    def rendered_rows(body) = ["qwen3.6-27b", "bge-m3", "BGE compatible"].count { |name| body.include?(name) }

    it "narrows the table to matching models" do
      get search_llm_models_path, params: { filters: }

      expect(response).to have_http_status(:ok)
      # The identifier and the friendly name both match, since either is what
      # somebody would type.
      expect(rendered_rows(response.body)).to eq(2)
      expect(response.body).to include("bge-m3")
    end

    it "answers with a turbo stream so only the table is replaced" do
      get search_llm_models_path, params: { filters: }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "applies the filter to the full page too, so a shared link works" do
      get llm_models_path, params: { filters: }

      expect(rendered_rows(response.body)).to eq(2)
    end

    it "shows everything without a filter" do
      get llm_models_path

      expect(rendered_rows(response.body)).to eq(3)
    end
  end
end
