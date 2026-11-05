# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Assistant::AI::Provider do
  it "exposes openrouter and mistral" do
    expect(described_class::KEYS).to eq(%w[openrouter mistral])
  end

  it "falls back to openrouter for unknown keys" do
    expect(described_class.find("nope").key).to eq("openrouter")
  end

  def config(attrs)
    TestManagement::Assistant::ProviderConfig.new(
      TestManagement::Assistant::ProviderConfig.apply({}, attrs).first
    )
  end

  it "builds openrouter and mistral chat URLs and headers" do
    openrouter = config("assistant_provider" => "openrouter", "assistant_model" => "openai/gpt-4o-mini",
                        "assistant_api_key" => "k")
    expect(openrouter.chat_url).to eq("https://openrouter.ai/api/v1/chat/completions")
    expect(openrouter.headers).to include("Authorization" => "Bearer k", "X-Title" => "OpenProject Test Management")

    mistral = config("assistant_provider" => "mistral", "assistant_model" => "mistral-small-latest",
                     "assistant_api_key" => "k")
    expect(mistral.chat_url).to eq("https://api.mistral.ai/v1/chat/completions")
    expect(mistral.headers).to include("Authorization" => "Bearer k")
  end
end
