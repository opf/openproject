# frozen_string_literal: true

require "spec_helper"

# "Test connection": model listing per provider preset and error classes (WebMock).
RSpec.describe TestManagement::Assistant::AI::ConnectionTest, :disable_ssrf_filter, :webmock do
  def run(params, stored = {})
    merged, errors = TestManagement::Assistant::ProviderConfig.apply(stored, params)
    expect(errors).to be_empty
    described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).call
  end

  def json(body) = { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }

  it "openai: lists chat models only, sorted and de-duplicated" do
    stub_request(:get, "https://api.openai.com/v1/models").with(headers: { "Authorization" => "Bearer sk-o" })
      .to_return(json(data: %w[gpt-4o text-embedding-3-small whisper-1 gpt-4o-mini dall-e-3 tts-1 gpt-4o].map { { id: it } }))

    result = run("assistant_provider" => "openai", "assistant_api_key" => "sk-o")

    expect(result).to be_ok
    expect(result.models).to eq(%w[gpt-4o gpt-4o-mini])
  end

  it "anthropic: native models endpoint with x-api-key" do
    stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000")
      .with(headers: { "x-api-key" => "sk-a", "anthropic-version" => "2023-06-01" })
      .to_return(json(data: [{ id: "claude-b", type: "model" }, { id: "claude-a", type: "model" }], has_more: false))

    expect(run("assistant_provider" => "anthropic", "assistant_api_key" => "sk-a").models).to eq(%w[claude-a claude-b])
  end

  it "openrouter: lists the models of the key (/models/user) and keeps text models (0021)" do
    stub_request(:get, "https://openrouter.ai/api/v1/models/user").with(headers: { "Authorization" => "Bearer sk-or" })
      .to_return(json(data: [
                        { id: "vendor/chat", architecture: { output_modalities: %w[text] } },
                        { id: "vendor/image", architecture: { output_modalities: %w[image] } }
                      ]))

    result = run("assistant_provider" => "openrouter", "assistant_api_key" => "sk-or")
    expect(result.models).to eq(%w[vendor/chat])
    expect(result.scope).to eq("key")
    expect(result).not_to be_catalogue
    expect(WebMock).not_to have_requested(:get, "https://openrouter.ai/api/v1/models")
  end

  it "openrouter: a wrong key fails as auth" do
    stub_request(:get, "https://openrouter.ai/api/v1/models/user").to_return(status: 401,
                                                                             body: { error: { message: "No auth" } }.to_json)

    result = run("assistant_provider" => "openrouter", "assistant_api_key" => "bad")
    expect(result.error_kind).to eq(:auth)
    expect(WebMock).not_to have_requested(:get, "https://openrouter.ai/api/v1/models")
  end

  it "openrouter: a gateway without /models/user checks the key and lists the catalogue" do
    stub_request(:get, "https://or-proxy.example.test/api/v1/models/user").to_return(status: 404)
    stub_request(:get, "https://or-proxy.example.test/api/v1/key").to_return(json(data: { label: "x" }))
    stub_request(:get, "https://or-proxy.example.test/api/v1/models").to_return(json(data: [{ id: "vendor/chat" }]))

    result = run("assistant_provider" => "openrouter", "assistant_base_url" => "https://or-proxy.example.test/api/v1",
                 "assistant_api_key" => "sk-or")
    expect(result.models).to eq(%w[vendor/chat])
    expect(result).to be_catalogue
  end

  it "mistral: completion_chat and not archived" do
    stub_request(:get, "https://api.mistral.ai/v1/models").to_return(json(data: [
                                                                            { id: "mistral-small-latest",
                                                                              capabilities: { completion_chat: true,
                                                                                              function_calling: true } },
                                                                            { id: "mistral-embed",
                                                                              capabilities: { completion_chat: false } },
                                                                            { id: "retired",
                                                                              capabilities: { completion_chat: true }, archived: true }
                                                                          ]))

    expect(run("assistant_provider" => "mistral", "assistant_api_key" => "k").models).to eq(%w[mistral-small-latest])
  end

  it "xai: language models available to the key, text output only (0021)" do
    stub_request(:get, "https://api.x.ai/v1/language-models").with(headers: { "Authorization" => "Bearer k" })
      .to_return(json(models: [
                        { id: "grok-4", input_modalities: %w[text image], output_modalities: %w[text] },
                        { id: "grok-3-mini", output_modalities: %w[text] },
                        { id: "grok-vision-out", output_modalities: %w[image] }
                      ]))

    result = run("assistant_provider" => "xai", "assistant_api_key" => "k")
    expect(result.models).to eq(%w[grok-3-mini grok-4])
    expect(result.scope).to eq("key")
    expect(WebMock).not_to have_requested(:get, "https://api.x.ai/v1/models")
  end

  it "xai: falls back to /models and drops image and video models" do
    stub_request(:get, "https://api.x.ai/v1/language-models").to_return(status: 404)
    stub_request(:get, "https://api.x.ai/v1/models").to_return(json(data: %w[grok-4 grok-2-image grok-imagine-video].map do |model|
      { id: model }
    end))

    expect(run("assistant_provider" => "xai", "assistant_api_key" => "k").models).to eq(%w[grok-4])
  end

  it "scope per preset: catalogue for OpenAI and Anthropic, key for Mistral (0021)" do
    stub_request(:get, "https://api.openai.com/v1/models").to_return(json(data: [{ id: "gpt-4o" }]))
    stub_request(:get,
                 "https://api.mistral.ai/v1/models").to_return(json(data: [{ id: "m", capabilities: { completion_chat: true } }]))
    stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000").to_return(json(data: [{ id: "claude-a" }]))

    expect(run("assistant_provider" => "openai", "assistant_api_key" => "k")).to be_catalogue
    expect(run("assistant_provider" => "anthropic", "assistant_api_key" => "k")).to be_catalogue
    expect(run("assistant_provider" => "mistral", "assistant_api_key" => "k")).not_to be_catalogue
  end

  it "ollama: no key, /v1/models with /api/tags fallback" do
    stub_request(:get, "http://ollama.test:11434/v1/models").to_return(status: 404, body: "404 page not found")
    stub_request(:get,
                 "http://ollama.test:11434/api/tags").to_return(json(models: [{ name: "qwen2.5:7b" },
                                                                              { name: "nomic-embed-text" }]))

    result = run("assistant_provider" => "ollama", "assistant_base_url" => "http://ollama.test:11434")
    expect(result.models).to eq(%w[qwen2.5:7b])
    expect(WebMock).to(have_requested(:get, "http://ollama.test:11434/v1/models").with { !it.headers.key?("Authorization") })
  end

  it "azure: verifies the key but keeps the model as free text (deployment names)" do
    stub_request(:get, "https://r.openai.azure.com/openai/v1/models").with(headers: { "api-key" => "az" })
      .to_return(json(data: [{ id: "gpt-4o" }]))

    result = run("assistant_provider" => "azure", "assistant_base_url" => "https://r.openai.azure.com/openai/v1",
                 "assistant_api_key" => "az")
    expect(result).to be_ok
    expect(result).not_to be_listed
  end

  it "custom: generic listing" do
    stub_request(:get, "https://gw.example.test/v1/models").to_return(json(data: [{ id: "local-model" }, { id: "bge-embed" }]))

    result = run("assistant_provider" => "custom", "assistant_base_url" => "https://gw.example.test/v1",
                 "assistant_auth_style" => "none")
    expect(result.models).to eq(%w[local-model])
  end

  it "uses the stored key when the field is blank" do
    stored, = TestManagement::Assistant::ProviderConfig.apply({}, "assistant_provider" => "openai",
                                                                  "assistant_api_key" => "sk-stored")
    stub_request(:get,
                 "https://api.openai.com/v1/models").with(headers: { "Authorization" => "Bearer sk-stored" }).to_return(json(data: []))

    expect(run({ "assistant_provider" => "openai", "assistant_api_key" => "" }, stored)).to be_ok
  end

  describe "#verify_model (0021)" do
    def verify(params)
      merged, errors = TestManagement::Assistant::ProviderConfig.apply({}, params)
      expect(errors).to be_empty
      described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).verify_model
    end

    it "sends one tiny chat request to the chosen model" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(json(choices: [{ message: { role: "assistant", content: "OK" }, finish_reason: "stop" }]))

      result = verify("assistant_provider" => "openai", "assistant_api_key" => "sk-v", "assistant_model" => "gpt-4o-mini")

      expect(result).to be_ok
      expect(WebMock).to(have_requested(:post, "https://api.openai.com/v1/chat/completions").with do |request|
        body = JSON.parse(request.body)
        body["model"] == "gpt-4o-mini" && body["max_completion_tokens"] == 16 && body["messages"].size == 1
      end)
    end

    it "reports a model the key may not use, without the key" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 403, body: { error: { message: "Project does not have access to model gpt-x (key sk-v)" } }.to_json)

      result = verify("assistant_provider" => "openai", "assistant_api_key" => "sk-v", "assistant_model" => "gpt-x")

      expect(result).not_to be_ok
      expect(result.error_kind).to eq(:model)
      expect(result.message).to include("gpt-x")
      expect(result.message).not_to include("sk-v")
    end

    it "needs a model" do
      result = verify("assistant_provider" => "openai", "assistant_api_key" => "sk-v")
      expect(result.error_kind).to eq(:incomplete)
      expect(WebMock).not_to have_requested(:any, /.*/)
    end
  end

  describe "errors" do
    it "needs a key before calling the provider" do
      expect(run("assistant_provider" => "openai").error_kind).to eq(:auth)
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it "classifies 401 as auth and never echoes the key" do
      stub_request(:get, "https://api.openai.com/v1/models")
        .to_return(status: 401, body: { error: { message: "Incorrect API key provided: sk-leak" } }.to_json)

      result = run("assistant_provider" => "openai", "assistant_api_key" => "sk-leak")
      expect(result.error_kind).to eq(:auth)
      expect(result.message).not_to include("sk-leak")
    end

    it "classifies 404, timeouts and network errors" do
      stub_request(:get, "https://gw.example.test/v1/models").to_return(status: 404)
      expect(run("assistant_provider" => "custom", "assistant_base_url" => "https://gw.example.test/v1",
                 "assistant_auth_style" => "none").error_kind).to eq(:not_found)

      stub_request(:get, "https://api.openai.com/v1/models").to_timeout
      expect(run("assistant_provider" => "openai", "assistant_api_key" => "k").error_kind).to eq(:timeout)

      stub_request(:get, "https://api.x.ai/v1/language-models").to_raise(Errno::ECONNREFUSED)
      expect(run("assistant_provider" => "xai", "assistant_api_key" => "k").error_kind).to eq(:network)
    end
  end
end

# The SSRF filter only runs without WebMock (see client_spec.rb).
RSpec.describe TestManagement::Assistant::AI::ConnectionTest, "SSRF protection" do
  before { allow(OpenProject::Configuration).to receive(:ssrf_protection_ip_allowlist).and_return([]) }

  it "explains the allowlist for a private address" do
    merged, = TestManagement::Assistant::ProviderConfig.apply({}, "assistant_provider" => "ollama",
                                                                  "assistant_base_url" => "http://127.0.0.1:9/v1")
    result = described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).call

    expect(result.error_kind).to eq(:ssrf)
    expect(result.message).to include("OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST", "127.0.0.1")
  end
end
