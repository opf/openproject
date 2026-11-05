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
require "rack/test"

RSpec.describe "APIv3 test management assistant providers", :disable_ssrf_filter, :webmock do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:admin) { create(:admin) }
  shared_let(:member) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

  let!(:provider) do
    create(:tm_assistant_provider, :default, name: "Gateway", base_url: "https://openrouter.ai/api/v1", model: "small",
                                             user_models: %w[large], api_key: "sk-api-secret")
  end
  let(:collection_path) { api_v3_paths.test_management_assistant_providers }
  let(:provider_path) { api_v3_paths.test_management_assistant_provider(provider.id) }

  def json = JSON.parse(last_response.body)

  def send_json(method, path, body)
    public_send(method, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
  end

  describe "GET providers" do
    it "gives administrators every field but the key" do
      login_as(admin)
      get collection_path

      expect(last_response).to have_http_status(200)
      element = json.dig("_embedded", "elements").sole
      expect(element).to include("name" => "Gateway", "preset" => "openrouter", "baseUrl" => "https://openrouter.ai/api/v1",
                                 "model" => "small", "userModels" => %w[large], "models" => %w[small large],
                                 "default" => true, "apiKeySet" => true, "configured" => true)
      expect(last_response.body).not_to include("sk-api-secret", "ciphertext")
    end

    it "is forbidden for non-administrators" do
      login_as(member)

      get collection_path
      expect(last_response).to have_http_status(403)

      get provider_path
      expect(last_response).to have_http_status(403)
      expect(last_response.body).not_to include("openrouter.ai", "sk-api-secret")
    end
  end

  describe "writes" do
    before { login_as(admin) }

    it "creates a provider (201) with a write-only key" do
      send_json(:post, collection_path, { name: "Local", preset: "mistral", model: "mistral-small-latest",
                                          apiKey: "sk-m", userModels: %w[mistral-tiny] })

      expect(last_response).to have_http_status(201)
      expect(json).to include("name" => "Local", "preset" => "mistral",
                              "models" => %w[mistral-small-latest mistral-tiny], "default" => false, "apiKeySet" => true)
    end

    it "updates only the given fields and keeps the stored key" do
      send_json(:patch, provider_path, { model: "large", userModels: [] })

      expect(last_response).to have_http_status(200)
      expect(provider.reload).to have_attributes(name: "Gateway", model: "large", user_models: [])
      expect(provider.config.api_key).to eq("sk-api-secret")
      expect(last_response.body).not_to include("sk-api-secret")
    end

    it "422s on invalid values and on a failed model check" do
      send_json(:post, collection_path, { name: "gateway", preset: "mistral", model: "m" })
      expect(last_response).to have_http_status(422)

      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions").to_return(status: 404, body: "{}")
      send_json(:post, collection_path, { name: "OpenRouter", preset: "openrouter", model: "openai/gpt-x", apiKey: "sk-x", verifyModel: true })
      expect(last_response).to have_http_status(422)
      expect(last_response.body).not_to include("sk-x")
      expect(TestManagement::AssistantProvider.count).to eq(1)
    end

    it "tests the connection without exposing the key" do
      stub_request(:get, "https://openrouter.ai/api/v1/models/user").with(headers: { "Authorization" => "Bearer sk-api-secret" })
        .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { data: [{ id: "small" }] }.to_json)

      send_json(:post, api_v3_paths.test_management_assistant_provider_test_connection(provider.id), {})

      expect(last_response).to have_http_status(200)
      expect(json).to include("_type" => "TestManagementAssistantProviderTest", "ok" => true, "models" => %w[small])
      expect(last_response.body).not_to include("sk-api-secret")
    end

    it "reports a rejected key as a failed test" do
      stub_request(:get, "https://openrouter.ai/api/v1/models/user").to_return(status: 401, body: "{}")

      send_json(:post, api_v3_paths.test_management_assistant_provider_test_connection(provider.id), {})

      expect(json).to include("ok" => false, "errorKind" => "auth")
    end

    it "makes another provider the default and deletes one" do
      other = create(:tm_assistant_provider, name: "Other")

      send_json(:post, api_v3_paths.test_management_assistant_provider_default(other.id), {})
      expect(last_response).to have_http_status(200)
      expect(json["default"]).to be(true)
      expect(provider.reload.is_default).to be(false)

      delete api_v3_paths.test_management_assistant_provider(other.id)
      expect(last_response).to have_http_status(204)
      expect(provider.reload.is_default).to be(true)
    end

    it "is for administrators only" do
      login_as(member)

      send_json(:post, collection_path, { name: "X", preset: "mistral", model: "m" })
      expect(last_response).to have_http_status(403)
      send_json(:patch, provider_path, { model: "x" })
      expect(last_response).to have_http_status(403)
      delete provider_path
      expect(last_response).to have_http_status(403)
      expect(provider.reload.model).to eq("small")
    end
  end
end
