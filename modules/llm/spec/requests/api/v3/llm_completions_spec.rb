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
require_module_spec_helper
require "rack/test"

RSpec.describe "API v3 AI completions", :webmock, content_type: :json,
                                                  with_flag: { llm_connection: true, llm_completions_api: true },
                                                  with_settings: { llm_features_enabled: true } do
  let(:path) { "/api/v3/ai/completions" }
  let(:completions_url) { "https://example.com/v1/chat/completions" }
  let(:body) do
    { system: "You help.",
      messages: [{ role: "user", content: "How many open work packages?" }],
      tools: [{ name: "search_work_packages", description: "Search", inputSchema: { type: "object", properties: {} } }] }
  end

  current_user { create(:user, global_permissions: [:use_llm_completions]) }

  def json = JSON.parse(last_response.body)

  def stub_answer(message)
    stub_request(:post, completions_url).to_return(
      status: 200, headers: { "Content-Type" => "application/json" },
      body: { id: "chatcmpl-1", object: "chat.completion", model: "qwen3.6-27b",
              choices: [{ index: 0, message:, finish_reason: "stop" }],
              usage: { prompt_tokens: 20, completion_tokens: 5, total_tokens: 25 } }.to_json
    )
  end

  context "with a connection that serves the feature" do
    before { create(:llm_connection, :with_models, default_chat_model_identifier: "qwen3.6-27b") }

    it "reports that completions are available" do
      get path

      expect(last_response).to have_http_status(:ok)
      expect(json).to include("_type" => "LlmCompletionsAvailability", "available" => true,
                              "status" => "ready", "model" => "qwen3.6-27b")
    end

    it "answers one turn with the text, the tool calls and the usage" do
      stub_answer(role: "assistant", content: "Let me search.",
                  tool_calls: [{ id: "call_1", type: "function",
                                 function: { name: "search_work_packages", arguments: '{"query":"open"}' } }])

      post path, body.to_json

      expect(last_response).to have_http_status(:ok)
      expect(json).to include(
        "_type" => "LlmCompletion",
        "content" => "Let me search.",
        "toolCalls" => [{ "id" => "call_1", "name" => "search_work_packages", "arguments" => { "query" => "open" } }],
        "model" => "qwen3.6-27b",
        "usage" => { "inputTokens" => 20, "outputTokens" => 5 }
      )
    end

    it "rejects an invalid conversation" do
      post path, body.merge(messages: []).to_json

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(json["message"]).to eq("Messages must not be empty")
    end

    it "answers 429 when the user exceeds the rate limit" do
      allow(Llm::Completions::RateLimit).to receive(:new).and_return(instance_double(Llm::Completions::RateLimit, allow?: false))

      post path, body.to_json

      expect(last_response).to have_http_status(:too_many_requests)
    end

    it "answers 502 without the server's response when the LLM server fails" do
      stub_request(:post, completions_url).to_return(status: 500, body: { error: { message: "secret sk-test-key" } }.to_json)

      post path, body.to_json

      expect(last_response).to have_http_status(:bad_gateway)
      expect(last_response.body).not_to include("sk-test-key")
    end
  end

  context "without a connection" do
    it "reports the reason as unavailable" do
      get path

      expect(json).to include("available" => false, "status" => "no_connection", "model" => nil)
    end

    it "answers 422 with the reason on a completion" do
      post path, body.to_json

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(json.dig("_embedded", "details", "reason")).to eq("no_connection")
    end
  end

  context "without the permission" do
    current_user { create(:user) }

    it "is forbidden" do
      post path, body.to_json

      expect(last_response).to have_http_status(:forbidden)
    end
  end

  context "with the feature flag off", with_flag: { llm_completions_api: false } do
    it "is not found" do
      get path

      expect(last_response).to have_http_status(:not_found)
    end
  end
end
