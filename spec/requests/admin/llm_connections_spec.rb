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

RSpec.describe "Admin LLM connection", :llm_server_helpers, :skip_csrf, :webmock, type: :rails_request do
  let(:admin) { create(:admin) }
  let(:non_admin) { create(:user) }
  let(:base_url) { "https://example.com/v1" }

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

    context "with an unreachable server" do
      let!(:models_request) { mock_llm_models_response(base_url, timeout: true) }

      it "persists nothing" do
        patch llm_connection_path, params: { llm_connection: { base_url:, api_key: "sk-test" } }

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
end
