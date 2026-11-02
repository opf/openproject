# frozen_string_literal: true

require "spec_helper"
require "rack/test"

# 0021: saved AI providers over APIv3. Administrators manage them; users with "Use test assistant"
# see names and models only; keys are write-only.
RSpec.describe "APIv3 test management assistant providers", :disable_ssrf_filter, :webmock do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:admin) { create(:admin) }
  shared_let(:assistant_user) { create(:user, member_with_permissions: { project => %i[view_test_cases use_test_assistant] }) }
  shared_let(:other_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

  let!(:provider) do
    create(:tm_assistant_provider, :default, name: "Gateway", base_url: "https://gw.example.test/v1", model: "small",
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
      expect(element).to include("name" => "Gateway", "preset" => "custom", "baseUrl" => "https://gw.example.test/v1",
                                 "model" => "small", "userModels" => %w[large], "models" => %w[small large],
                                 "default" => true, "apiKeySet" => true, "configured" => true)
      expect(last_response.body).not_to include("sk-api-secret", "ciphertext")
    end

    it "gives assistant users names and models only" do
      login_as(assistant_user)
      get collection_path

      expect(last_response).to have_http_status(200)
      element = json.dig("_embedded", "elements").sole
      expect(element.keys).to contain_exactly("_type", "id", "name", "model", "models", "default", "selected", "selectedModel",
                                              "_links")
      expect(element).to include("selected" => true, "selectedModel" => "small")
      expect(last_response.body).not_to include("gw.example.test", "sk-api-secret")

      get provider_path
      expect(json).not_to have_key("baseUrl")
    end

    it "is forbidden without the assistant permission" do
      login_as(other_user)
      get collection_path

      expect(last_response).to have_http_status(403)
    end
  end

  describe "writes" do
    before { login_as(admin) }

    it "creates a provider (201) with a write-only key" do
      send_json(:post, collection_path, { name: "Local", preset: "ollama", baseUrl: "http://ollama.test:11434",
                                          model: "llama3.1:8b", userModels: %w[qwen2.5:7b] })

      expect(last_response).to have_http_status(201)
      expect(json).to include("name" => "Local", "preset" => "ollama", "baseUrl" => "http://ollama.test:11434/v1",
                              "models" => %w[llama3.1:8b qwen2.5:7b], "default" => false, "apiKeySet" => false)
    end

    it "updates only the given fields and keeps the stored key" do
      send_json(:patch, provider_path, { model: "large", userModels: [] })

      expect(last_response).to have_http_status(200)
      expect(provider.reload).to have_attributes(name: "Gateway", model: "large", user_models: [])
      expect(provider.config.api_key).to eq("sk-api-secret")
      expect(last_response.body).not_to include("sk-api-secret")
    end

    it "422s on invalid values and on a failed model check" do
      send_json(:post, collection_path, { name: "gateway", preset: "ollama", model: "m" })
      expect(last_response).to have_http_status(422)

      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(status: 404, body: "{}")
      send_json(:post, collection_path, { name: "OpenAI", preset: "openai", model: "gpt-x", apiKey: "sk-x", verifyModel: true })
      expect(last_response).to have_http_status(422)
      expect(last_response.body).not_to include("sk-x")
      expect(TestManagement::AssistantProvider.count).to eq(1)
    end

    it "makes another provider the default and deletes one" do
      other = create(:tm_assistant_provider, name: "Other")

      # Like every APIv3 POST, also without a body it needs Content-Type: application/json (else 415).
      send_json(:post, api_v3_paths.test_management_assistant_provider_default(other.id), {})
      expect(last_response).to have_http_status(200)
      expect(json["default"]).to be(true)
      expect(provider.reload.is_default).to be(false)

      delete api_v3_paths.test_management_assistant_provider(other.id)
      expect(last_response).to have_http_status(204)
      expect(provider.reload.is_default).to be(true)
    end

    it "is for administrators only" do
      login_as(assistant_user)

      send_json(:post, collection_path, { name: "X", preset: "ollama", model: "m" })
      expect(last_response).to have_http_status(403)
      send_json(:patch, provider_path, { model: "x" })
      expect(last_response).to have_http_status(403)
      delete provider_path
      expect(last_response).to have_http_status(403)
      expect(provider.reload.model).to eq("small")
    end
  end
end
