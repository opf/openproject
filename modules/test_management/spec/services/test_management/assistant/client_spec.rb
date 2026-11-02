# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_assistant"

RSpec.describe TestManagement::Assistant::Client, :disable_ssrf_filter, :webmock do
  include_context "with test assistant provider"

  subject(:client) { described_class.new }

  it "posts model, messages and the bearer key to the completions endpoint" do
    stub_llm(llm_reply(content: "Hello",
                       usage: { prompt_tokens: 5, completion_tokens: 7, total_tokens: 12 }))

    response = client.chat(messages: [{ role: "user", content: "Hi" }])

    expect(response.content).to eq("Hello")
    expect(response.usage).to eq("prompt_tokens" => 5, "completion_tokens" => 7, "total_tokens" => 12)
    expect(WebMock).to have_requested(:post, assistant_completions_url)
      .with(headers: { "Authorization" => "Bearer #{assistant_api_key}" })
    expect(llm_request_bodies.first).to include("model" => "test-model", "messages" => [{ "role" => "user", "content" => "Hi" }])
  end

  describe ".normalize_usage" do
    it "maps OpenAI and Anthropic shapes and fills total when missing" do
      expect(described_class.normalize_usage("prompt_tokens" => 1, "completion_tokens" => 2, "total_tokens" => 3))
        .to eq("prompt_tokens" => 1, "completion_tokens" => 2, "total_tokens" => 3)
      expect(described_class.normalize_usage("input_tokens" => 4, "output_tokens" => 6))
        .to eq("prompt_tokens" => 4, "completion_tokens" => 6, "total_tokens" => 10)
      expect(described_class.normalize_usage("completion_tokens" => 9,
                                             "completion_tokens_details" => { "reasoning_tokens" => 8 }))
        .to eq("completion_tokens" => 9, "total_tokens" => 9, "reasoning_tokens" => 8)
      expect(described_class.normalize_usage(nil)).to be_nil
      expect(described_class.normalize_usage({})).to be_nil
    end
  end

  it "parses tool calls" do
    stub_llm(llm_reply(tool_calls: [["search_test_cases", { query: "login" }]]))

    response = client.chat(messages: [], tools: TestManagement::Assistant::Tools.schemas)

    expect(response.tool_calls.map(&:name)).to eq(["search_test_cases"])
    expect(response.tool_calls.first.arguments).to eq("query" => "login")
    expect(llm_request_bodies.first["tools"].size).to eq(6)
  end

  it "names provider and model in errors and never leaks the key" do
    stub_request(:post, assistant_completions_url)
      .to_return(status: 401, body: { error: { message: "Incorrect API key #{assistant_api_key}" } }.to_json)

    expect { client.chat(messages: []) }.to raise_error(described_class::Error) { |error|
      expect(error.message).to start_with("llm.example.com / test-model: HTTP 401")
      expect(error.message).not_to include(assistant_api_key)
    }
  end

  it "explains rate limits" do
    stub_request(:post, assistant_completions_url).to_return(status: 429, body: "{}")

    expect { client.chat(messages: []) }.to raise_error(described_class::Error, /HTTP 429/)
  end

  it "refuses oversized and unparsable responses" do
    stub_request(:post, assistant_completions_url).to_return(status: 200, body: "x" * (described_class::MAX_RESPONSE_BYTES + 1))
    expect { client.chat(messages: []) }.to raise_error(described_class::Error, /too large/i)

    stub_request(:post, assistant_completions_url).to_return(status: 200, body: "<html>")
    expect { client.chat(messages: []) }.to raise_error(described_class::Error)
  end

  it "explains when a reasoning model spends all tokens without content" do
    stub_request(:post, assistant_completions_url).to_return(
      status: 200,
      body: {
        choices: [{ message: { role: "assistant", content: nil, reasoning: "…" }, finish_reason: "length" }],
        usage: { completion_tokens: 4096, completion_tokens_details: { reasoning_tokens: 4096 } }
      }.to_json
    )

    expect { client.chat(messages: []) }.to raise_error(described_class::Error, /4096.*reasoning/i)
  end

  it "drops a rejected reasoning parameter and retries" do
    stub_llm(
      { status: 400, body: { error: { message: "Unknown parameter: reasoning" } }.to_json },
      llm_reply(content: "ok")
    )

    expect(client.chat(messages: [], reasoning: { effort: "low" }).content).to eq("ok")
    expect(llm_request_bodies.size).to eq(2)
    expect(llm_request_bodies.first).to include("reasoning")
    expect(llm_request_bodies.last).not_to include("reasoning")
  end

  it "raises NotConfigured without a provider" do
    allow(Setting).to receive(:plugin_openproject_test_management).and_return({})

    expect { described_class.new.chat(messages: []) }.to raise_error(described_class::NotConfigured)
  end
end

# WebMock replaces the HTTPX connection, so the SSRF filter (which checks the resolved
# addresses on the connection) never runs under :webmock. This example uses the real client
# without WebMock; the filter refuses the private address before any connection is made.
RSpec.describe TestManagement::Assistant::Client, "SSRF protection" do
  include_context "with test assistant provider"

  let(:assistant_base_url) { "http://127.0.0.1:9/v1" }

  before { allow(OpenProject::Configuration).to receive(:ssrf_protection_ip_allowlist).and_return([]) }

  it "refuses private addresses unless they are allowed" do
    expect { described_class.new.chat(messages: []) }
      .to raise_error(described_class::Error, /127\.0\.0\.1 \/ test-model: ServerSideRequestForgeryError/)
  end
end
