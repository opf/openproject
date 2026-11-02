# frozen_string_literal: true

# Test Assistant (0014) spec helpers: a configured OpenAI-compatible provider and WebMock
# stubs for its chat completions endpoint. No real provider is ever called.
RSpec.shared_context "with test assistant provider" do
  let(:assistant_base_url) { "https://llm.example.com/v1" }
  let(:assistant_completions_url) { "#{assistant_base_url}/chat/completions" }
  let(:assistant_api_key) { "sk-test-assistant-secret" }
  let(:assistant_settings) do
    TestManagement::Assistant::ProviderConfig.apply(
      {}, "assistant_base_url" => assistant_base_url, "assistant_model" => "test-model",
          "assistant_api_key" => assistant_api_key
    ).first
  end

  before do
    allow(Setting).to receive(:plugin_openproject_test_management).and_return(assistant_settings)
  end

  def llm_reply(content: nil, tool_calls: nil, usage: nil)
    message = { role: "assistant", content: }
    if tool_calls
      message[:tool_calls] = tool_calls.map.with_index do |(name, arguments), index|
        { id: "call_#{index}", type: "function", function: { name:, arguments: arguments.to_json } }
      end
    end
    body = { choices: [{ message:, finish_reason: "stop" }] }
    body[:usage] = usage if usage
    { status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" } }
  end

  # Answers the given responses in order (the last one repeats) and records the request bodies.
  def stub_llm(*responses)
    queue = responses.dup
    stub_request(:post, assistant_completions_url).to_return do |request|
      llm_request_bodies << JSON.parse(request.body)
      queue.size > 1 ? queue.shift : queue.first
    end
  end

  def llm_request_bodies
    @llm_request_bodies ||= []
  end
end
