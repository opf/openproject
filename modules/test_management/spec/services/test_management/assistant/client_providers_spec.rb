# frozen_string_literal: true

require "spec_helper"

# Chat request shape per provider preset (WebMock; no provider is ever called).
RSpec.describe TestManagement::Assistant::Client, "provider presets", :disable_ssrf_filter, :webmock do
  let(:tools) { TestManagement::Assistant::Tools.schemas }
  let(:openai_reply) do
    { status: 200, headers: { "Content-Type" => "application/json" },
      body: { choices: [{ message: { role: "assistant", content: "Hello" }, finish_reason: "stop" }] }.to_json }
  end

  def use_provider(params)
    settings, errors = TestManagement::Assistant::ProviderConfig.apply({}, params)
    expect(errors).to be_empty
    allow(Setting).to receive(:plugin_openproject_test_management).and_return(settings)
  end

  def captured_body(url)
    body = nil
    stub_request(:post, url).to_return do |request|
      body = JSON.parse(request.body)
      yield if block_given?
      openai_reply
    end
    -> { body }
  end

  {
    "openai" => ["https://api.openai.com/v1/chat/completions", { "Authorization" => "Bearer k-openai" }, "max_completion_tokens",
                 true],
    "openrouter" => ["https://openrouter.ai/api/v1/chat/completions",
                     { "Authorization" => "Bearer k-openrouter", "X-Title" => "OpenProject Test Management" }, "max_tokens", true],
    "ollama" => ["http://localhost:11434/v1/chat/completions", {}, "max_tokens", false],
    "xai" => ["https://api.x.ai/v1/chat/completions", { "Authorization" => "Bearer k-xai" }, "max_tokens", true],
    "mistral" => ["https://api.mistral.ai/v1/chat/completions", { "Authorization" => "Bearer k-mistral" }, "max_tokens", true]
  }.each do |key, (url, headers, token_param, tool_choice)|
    it "#{key}: posts the OpenAI chat shape to #{url}" do
      use_provider("assistant_provider" => key, "assistant_model" => "m-#{key}",
                   "assistant_api_key" => (key == "ollama" ? "" : "k-#{key}"))
      body = captured_body(url)

      response = described_class.new.chat(messages: [{ role: "user", content: "Hi" }], tools:)

      expect(response.content).to eq("Hello")
      # WebMock treats `headers: {}` as "the request has no headers at all", so the keyless
      # case (Ollama) checks that no authentication header is sent instead.
      if headers.empty?
        expect(WebMock).to(have_requested(:post, url).with do |req|
          !req.headers.keys.map(&:downcase).intersect?(%w[authorization api-key x-api-key])
        end)
      else
        expect(WebMock).to have_requested(:post, url).with(headers:)
      end
      expect(body.call).to include("model" => "m-#{key}", token_param => be_a(Integer), "tools" => be_present)
      expect(body.call.key?("tool_choice")).to be(tool_choice)
    end
  end

  it "azure: api-key header, deployment as model" do
    use_provider("assistant_provider" => "azure", "assistant_base_url" => "https://r.openai.azure.com/openai/v1",
                 "assistant_model" => "my-deployment", "assistant_api_key" => "k-az")
    body = captured_body("https://r.openai.azure.com/openai/v1/chat/completions")

    described_class.new.chat(messages: [{ role: "user", content: "Hi" }])

    expect(WebMock).to have_requested(:post,
                                      "https://r.openai.azure.com/openai/v1/chat/completions").with(headers: { "api-key" => "k-az" })
    expect(body.call).to include("model" => "my-deployment", "max_completion_tokens" => be_a(Integer))
  end

  it "retries once without temperature when the model rejects it" do
    use_provider("assistant_provider" => "openai", "assistant_model" => "o-model", "assistant_api_key" => "k")
    bodies = []
    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return do |request|
      bodies << JSON.parse(request.body)
      if bodies.size == 1
        { status: 400, body: { error: { message: "Unsupported value: 'temperature' does not support 0.2" } }.to_json }
      else
        openai_reply
      end
    end

    expect(described_class.new.chat(messages: [{ role: "user", content: "Hi" }]).content).to eq("Hello")
    expect(bodies.first).to have_key("temperature")
    expect(bodies.last).not_to have_key("temperature")
  end

  describe "anthropic (native Messages API)" do
    let(:url) { "https://api.anthropic.com/v1/messages" }
    let(:conversation) do
      [{ role: "system", content: "Be brief." }, { role: "user", content: "Find login cases" },
       { role: "assistant", content: nil,
         tool_calls: [{ id: "call_1", type: "function", function: { name: "search_test_cases", arguments: '{"query":"login"}' } }] },
       { role: "tool", tool_call_id: "call_1", content: "[]" }]
    end

    before do
      use_provider("assistant_provider" => "anthropic", "assistant_model" => "claude-test",
                   "assistant_api_key" => "sk-ant-secret")
    end

    it "translates messages and tools and parses text + tool_use" do
      body = nil
      stub_request(:post, url).to_return do |request|
        body = JSON.parse(request.body)
        { status: 200, headers: { "Content-Type" => "application/json" },
          body: { content: [{ type: "text", text: "Checking" },
                            { type: "tool_use", id: "toolu_1", name: "summarize_failures", input: { run_id: 3 } }],
                  stop_reason: "tool_use",
                  usage: { input_tokens: 15, output_tokens: 9 } }.to_json }
      end

      response = described_class.new.chat(messages: conversation, tools:)

      expect(WebMock).to have_requested(:post, url)
        .with(headers: { "x-api-key" => "sk-ant-secret", "anthropic-version" => "2023-06-01" })
      expect(body).to include("model" => "claude-test", "system" => "Be brief.", "max_tokens" => be_a(Integer))
      expect(body).not_to have_key("temperature")
      expect(body["tools"].first).to include("name" => "search_test_cases", "input_schema" => be_a(Hash))
      expect(body["messages"].pluck("role")).to eq(%w[user assistant user])
      expect(body["messages"][1]["content"].first).to include("type" => "tool_use", "id" => "call_1",
                                                              "input" => { "query" => "login" })
      expect(body["messages"][2]["content"].first).to include("type" => "tool_result", "tool_use_id" => "call_1",
                                                              "content" => "[]")

      expect(response.content).to eq("Checking")
      expect(response.tool_calls.map do |call|
        [call.id, call.name, call.arguments]
      end).to eq([["toolu_1", "summarize_failures", { "run_id" => 3 }]])
      expect(response.usage).to eq("prompt_tokens" => 15, "completion_tokens" => 9, "total_tokens" => 24)
    end

    it "reports errors without the key" do
      stub_request(:post, url).to_return(status: 401, body: { type: "error", error: { type: "authentication_error",
                                                                                      message: "invalid x-api-key sk-ant-secret" } }.to_json)

      expect do
        described_class.new.chat(messages: [{ role: "user", content: "x" }])
      end.to raise_error(described_class::Error) { |error|
               expect(error.message).to include("HTTP 401")
               expect(error.message).not_to include("sk-ant-secret")
             }
    end
  end
end
