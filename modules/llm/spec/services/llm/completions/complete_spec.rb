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

RSpec.describe Llm::Completions::Complete, :llm_server_helpers, :webmock,
               with_flag: { llm_connection: true, llm_completions_api: true },
               with_settings: { llm_features_enabled: true } do
  subject(:completion) { described_class.new(user:, request:).call }

  let(:user) { build_stubbed(:user) }
  let(:base_url) { "https://example.com/v1" }
  let(:completions_url) { "#{base_url}/chat/completions" }
  let(:tools) do
    [{ "name" => "search_work_packages", "description" => "Search work packages",
       "inputSchema" => { "type" => "object", "properties" => { "query" => { "type" => "string" } } } }]
  end
  let(:messages) { [{ "role" => "user", "content" => "How many open work packages?" }] }
  let(:request) do
    Llm::Completions::Request.from_params("system" => "You help.", "messages" => messages, "tools" => tools)
  end

  def answer(message, usage: { prompt_tokens: 12, completion_tokens: 3, total_tokens: 15 })
    { status: 200, headers: { "Content-Type" => "application/json" },
      body: { id: "chatcmpl-1", object: "chat.completion", model: "qwen3.6-27b",
              choices: [{ index: 0, message:, finish_reason: "stop" }], usage: }.to_json }
  end

  context "with a connection that serves the feature" do
    before { create(:llm_connection, :with_models, default_chat_model_identifier: "qwen3.6-27b") }

    it "returns the model's text and its token usage" do
      stub_request(:post, completions_url).to_return(answer({ role: "assistant", content: "There are 38." }))

      expect(completion).to have_attributes(content: "There are 38.", tool_calls: [], model_id: "qwen3.6-27b",
                                            input_tokens: 12, output_tokens: 3)
    end

    it "returns tool calls without running them and without a second model request" do
      tool_call = { id: "call_1", type: "function",
                    function: { name: "search_work_packages", arguments: { query: "open" }.to_json } }
      stub = stub_request(:post, completions_url)
               .to_return(answer({ role: "assistant", content: nil, tool_calls: [tool_call] }))

      expect(completion.tool_calls).to eq([{ id: "call_1", name: "search_work_packages", arguments: { "query" => "open" } }])
      expect(stub).to have_been_requested.once
    end

    context "with earlier tool calls and their results" do
      let(:messages) do
        [{ "role" => "user", "content" => "How many open work packages?" },
         { "role" => "assistant", "content" => "",
           "toolCalls" => [{ "id" => "call_1", "name" => "search_work_packages", "arguments" => { "query" => "open" } }] },
         { "role" => "tool", "toolCallId" => "call_1", "content" => '{"total":38}' }]
      end

      it "sends the system prompt, the conversation and the tools to the model" do
        stub_request(:post, completions_url).to_return(answer({ role: "assistant", content: "38" }))

        completion

        expect(WebMock).to(have_requested(:post, completions_url).with do |sent|
          body = JSON.parse(sent.body)
          roles = body["messages"].pluck("role")
          roles == %w[system user assistant tool] &&
            body["messages"][2]["tool_calls"].first.dig("function", "name") == "search_work_packages" &&
            body["messages"][3]["tool_call_id"] == "call_1" &&
            body["tools"].first.dig("function", "name") == "search_work_packages"
        end)
      end
    end
  end

  context "without a connection" do
    it "raises NotReady" do
      expect { completion }.to raise_error(Llm::Errors::NotReady)
    end
  end

  context "with the feature flag off", with_flag: { llm_completions_api: false } do
    before { create(:llm_connection, :with_models, default_chat_model_identifier: "qwen3.6-27b") }

    it "raises NotReady with the feature_disabled status" do
      expect { completion }.to raise_error(Llm::Errors::NotReady) { |error| expect(error.status).to eq(:feature_disabled) }
    end
  end
end
