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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmServerHelpers
  DEFAULT_MODELS = [
    { id: "qwen3.6-27b", object: "model", owned_by: "vllm", max_model_len: 262_144 },
    { id: "bge-m3", object: "model", owned_by: "vllm", max_model_len: 8_192 }
  ].freeze

  # Stubs GET <base_url>/models. Returns the stub so specs can assert on how
  # often it was called -- which is how the changed-attributes guard is pinned.
  def mock_llm_models_response(base_url,
                               models: DEFAULT_MODELS,
                               response_code: 200,
                               body: nil,
                               timeout: false)
    stub = stub_request(:get, "#{base_url.chomp('/')}/models")

    return stub.to_timeout if timeout

    stub.to_return(
      status: response_code,
      headers: { "Content-Type" => "application/json" },
      body: body || { object: "list", data: models }.to_json
    )
  end

  DEFAULT_CHAT_BODY = {
    id: "chatcmpl-test",
    object: "chat.completion",
    model: "qwen3.6-27b",
    choices: [{ index: 0, message: { role: "assistant", content: "pong" }, finish_reason: "stop" }],
    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 }
  }.freeze

  # Stubs POST <base_url>/chat/completions.
  #
  # Note that RubyLLM retries POSTs up to max_retries times on 429 and 5xx, so a
  # spec stubbing one of those against a session built with the default
  # max_retries sees more than one request. Build the session with an explicit
  # max_retries when the request count matters.
  def mock_llm_chat_response(base_url,
                             content: "pong",
                             response_code: 200,
                             body: nil,
                             timeout: false)
    stub = stub_request(:post, "#{base_url.chomp('/')}/chat/completions")

    return stub.to_timeout if timeout

    payload = body || DEFAULT_CHAT_BODY.merge(
      choices: [{ index: 0, message: { role: "assistant", content: }, finish_reason: "stop" }]
    ).to_json

    stub.to_return(
      status: response_code,
      headers: { "Content-Type" => "application/json" },
      body: payload.is_a?(String) ? payload : payload.to_json
    )
  end

  # Stubs POST <base_url>/embeddings, returning a vector of the requested size.
  def mock_llm_embeddings_response(base_url,
                                   dimensions: 4,
                                   response_code: 200,
                                   body: nil,
                                   timeout: false)
    stub = stub_request(:post, "#{base_url.chomp('/')}/embeddings")

    return stub.to_timeout if timeout

    payload = body || {
      object: "list",
      model: "bge-m3",
      data: [{ object: "embedding", index: 0, embedding: Array.new(dimensions) { 0.1 } }],
      usage: { prompt_tokens: 1, total_tokens: 1 }
    }

    stub.to_return(
      status: response_code,
      headers: { "Content-Type" => "application/json" },
      body: payload.is_a?(String) ? payload : payload.to_json
    )
  end

  # example.com resolves publicly, but a spec that needs a literal or private
  # host has to say so explicitly rather than opening the allowlist to 0.0.0.0/0.
  def allow_llm_host(*hosts)
    allow(OpenProject::SsrfProtection).to receive(:safe_ip?) do |host|
      hosts.include?(host) ? IPAddr.new("93.184.216.34") : nil
    end
  end
end

RSpec.configure do |config|
  config.include LlmServerHelpers, :llm_server_helpers
end
