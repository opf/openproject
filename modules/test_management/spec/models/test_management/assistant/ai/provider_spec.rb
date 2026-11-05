# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Assistant::AI::Provider do
  it "exposes openai, anthropic and custom" do
    expect(described_class::KEYS).to eq(%w[openai anthropic custom])
  end

  it "falls back to custom for unknown keys" do
    expect(described_class.find("nope").key).to eq("custom")
  end

  def config(attrs)
    TestManagement::Assistant::ProviderConfig.new(
      TestManagement::Assistant::ProviderConfig.apply({}, attrs).first
    )
  end

  it "builds openai and anthropic chat URLs and headers" do
    openai = config("assistant_provider" => "openai", "assistant_model" => "gpt-4o-mini", "assistant_api_key" => "k")
    expect(openai.chat_url).to eq("https://api.openai.com/v1/chat/completions")
    expect(openai.headers).to include("Authorization" => "Bearer k")

    anthropic = config("assistant_provider" => "anthropic", "assistant_model" => "claude-sonnet-4-5",
                       "assistant_api_key" => "k")
    expect(anthropic.chat_url).to eq("https://api.anthropic.com/v1/messages")
    expect(anthropic.headers).to include("x-api-key" => "k", "anthropic-version" => described_class::ANTHROPIC_VERSION)
  end

  it "lets custom keep a free base URL and auth style" do
    c = config("assistant_provider" => "custom", "assistant_base_url" => "https://llm.example.com/v1",
               "assistant_model" => "m", "assistant_auth_style" => "bearer", "assistant_api_key" => "k")
    expect(c).to be_configured
    expect(c.chat_url).to eq("https://llm.example.com/v1/chat/completions")
  end
end
