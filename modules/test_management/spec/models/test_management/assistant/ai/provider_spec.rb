# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Assistant::AI::Provider do
  def config(params, stored = {})
    merged, errors = TestManagement::Assistant::ProviderConfig.apply(stored, params)
    expect(errors).to be_empty
    TestManagement::Assistant::ProviderConfig.new(merged)
  end

  it "lists the presets with labels (Custom last)" do
    expect(described_class::KEYS).to eq(%w[openai anthropic openrouter ollama xai mistral azure custom])
    expect(described_class.all.map(&:label)).to all(be_present)
  end

  it "treats settings stored before presets as Custom" do
    legacy = TestManagement::Assistant::ProviderConfig.new("assistant_base_url" => "https://gw.example.test/v1")
    expect(legacy.provider).to be_custom
    expect(legacy.base_url).to eq("https://gw.example.test/v1")
    braced = TestManagement::Assistant::ProviderConfig.new({ "assistant_provider" => "ollama" }, name: "Local", provider_id: 7)
    expect([braced.provider.key, braced.name, braced.provider_id]).to eq(["ollama", "Local", 7])
    expect(described_class.find("unknown")).to be_custom
  end

  it "rejects unknown providers" do
    _, errors = TestManagement::Assistant::ProviderConfig.apply({}, "assistant_provider" => "nope")
    expect(errors).to be_present
  end

  {
    "openai" => ["https://api.openai.com/v1/chat/completions", { "Authorization" => "Bearer k" }],
    "anthropic" => ["https://api.anthropic.com/v1/messages", { "x-api-key" => "k", "anthropic-version" => "2023-06-01" }],
    "openrouter" => ["https://openrouter.ai/api/v1/chat/completions",
                     { "Authorization" => "Bearer k", "X-Title" => "OpenProject Test Management" }],
    "ollama" => ["http://localhost:11434/v1/chat/completions", { "Authorization" => "Bearer k" }],
    "xai" => ["https://api.x.ai/v1/chat/completions", { "Authorization" => "Bearer k" }],
    "mistral" => ["https://api.mistral.ai/v1/chat/completions", { "Authorization" => "Bearer k" }]
  }.each do |key, (chat_url, headers)|
    it "#{key}: default base URL, chat endpoint and auth headers" do
      c = config("assistant_provider" => key, "assistant_model" => "m", "assistant_api_key" => "k")

      expect(c.chat_url).to eq(chat_url)
      expect(c.headers).to include(headers)
      expect(c).to be_configured
    end
  end

  it "azure: api-key header, needs the resource URL" do
    expect(config("assistant_provider" => "azure", "assistant_model" => "dep", "assistant_api_key" => "k")).not_to be_configured

    c = config("assistant_provider" => "azure", "assistant_base_url" => "https://r.openai.azure.com/openai/v1",
               "assistant_model" => "dep", "assistant_api_key" => "k")
    expect(c.chat_url).to eq("https://r.openai.azure.com/openai/v1/chat/completions")
    expect(c.headers).to include("api-key" => "k")
    expect(c.headers).not_to include("Authorization")
  end

  it "ollama: no key needed, /v1 appended to a bare host" do
    c = config("assistant_provider" => "ollama", "assistant_base_url" => "http://ollama.ai.svc:11434",
               "assistant_model" => "llama3.1:8b")

    expect(c.base_url).to eq("http://ollama.ai.svc:11434/v1")
    expect(c).to be_configured
    expect(c.headers).not_to include("Authorization")
  end

  it "presets ignore a posted auth style; Custom honors it" do
    expect(config("assistant_provider" => "xai", "assistant_auth_style" => "none", "assistant_model" => "g")).not_to be_configured
    expect(config("assistant_provider" => "custom", "assistant_base_url" => "https://gw.example.test/v1",
                  "assistant_auth_style" => "none", "assistant_model" => "g")).to be_configured
  end

  it "replaces another preset's default URL left in the field, but keeps a proxy URL" do
    expect(config("assistant_provider" => "mistral", "assistant_base_url" => "https://api.openai.com/v1").base_url)
      .to eq("https://api.mistral.ai/v1")
    expect(config("assistant_provider" => "openai", "assistant_base_url" => "https://proxy.example.test/v1").base_url)
      .to eq("https://proxy.example.test/v1")
    expect(config("assistant_provider" => "custom", "assistant_base_url" => "https://api.openai.com/v1").base_url)
      .to eq("https://api.openai.com/v1")
  end

  it "builds the models URL next to the chat endpoint" do
    expect(config("assistant_provider" => "anthropic").models_url("limit=1000")).to eq("https://api.anthropic.com/v1/models?limit=1000")
    expect(config("assistant_provider" => "custom", "assistant_base_url" => "https://gw.example.test/v1/chat/completions").models_url)
      .to eq("https://gw.example.test/v1/models")
  end
end
