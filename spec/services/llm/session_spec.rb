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

require "spec_helper"

RSpec.describe Llm::Session, :llm_server_helpers, :webmock do
  let(:base_url) { "https://example.com/v1" }
  let(:connection) { create(:llm_connection, base_url:, api_key: "sk-test-key") }

  describe ".supports?" do
    it "rejects the formats a connection cannot supply credentials for" do
      expect(described_class.supports?("bedrock")).to be(false)
      expect(described_class.supports?("vertexai")).to be(false)
    end

    it "accepts the rest" do
      expect(described_class.supports?("openai")).to be(true)
      expect(described_class.supports?("anthropic")).to be(true)
    end
  end

  describe "#initialize" do
    it "refuses a format whose credentials cannot be stored" do
      connection.update_column(:api_format, "bedrock")

      expect { described_class.for(connection) }
        .to raise_error(Llm::Errors::ConfigurationError, /bedrock/)
    end
  end

  describe "#chat" do
    it "sends the completion to the configured base URL with the stored key" do
      stub = mock_llm_chat_response(base_url, content: "pong")

      answer = described_class.for(connection, max_retries: 0).chat("qwen3.6-27b").ask("ping")

      expect(answer.content).to eq("pong")
      expect(stub).to have_been_requested.once
      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with(headers: { "Authorization" => "Bearer sk-test-key" })
    end

    it "sends the connection's custom headers" do
      connection.update!(custom_headers: { "apikey" => "gateway-secret" })
      mock_llm_chat_response(base_url)

      described_class.for(connection, max_retries: 0).chat("qwen3.6-27b").ask("ping")

      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with(headers: { "apikey" => "gateway-secret" })
    end

    it "translates a rejected key into an authentication error" do
      mock_llm_chat_response(base_url, response_code: 401)

      expect { described_class.for(connection, max_retries: 0).chat("qwen3.6-27b").ask("ping") }
        .to raise_error(Llm::Errors::AuthenticationError)
    end

    # RubyLLM retries POSTs three times by default, so an unbounded retry would
    # bill four completions for one call.
    it "does not retry when told not to" do
      stub = mock_llm_chat_response(base_url, response_code: 500)

      expect { described_class.for(connection, max_retries: 0).chat("qwen3.6-27b").ask("ping") }
        .to raise_error(Llm::Errors::ApiError)
      expect(stub).to have_been_requested.once
    end

    # A self-hosted OpenAI-compatible server commonly needs no credential, but
    # RubyLLM's ensure_configured! raises unless one is set.
    it "reaches a server that needs no API key" do
      connection.update!(api_key: nil)
      mock_llm_chat_response(base_url)

      expect { described_class.for(connection, max_retries: 0).chat("qwen3.6-27b").ask("ping") }
        .not_to raise_error
    end
  end

  describe "#embed" do
    it "requests a vector and carries the custom headers" do
      connection.update!(custom_headers: { "apikey" => "gateway-secret" })
      mock_llm_embeddings_response(base_url, dimensions: 8)

      embedding = described_class.for(connection, max_retries: 0).embed("hello", model: "bge-m3")

      expect(embedding.vectors.length).to eq(8)
      expect(WebMock).to have_requested(:post, "#{base_url}/embeddings")
        .with(headers: { "apikey" => "gateway-secret" })
    end
  end

  describe "global configuration" do
    it "never writes the connection's settings into RubyLLM's global config" do
      mock_llm_chat_response(base_url)

      described_class.for(connection, max_retries: 0).chat("qwen3.6-27b").ask("ping")

      expect(RubyLLM.config.openai_api_base).to be_nil
      expect(RubyLLM.config.openai_api_key).to be_nil
      expect(RubyLLM.config.openproject_custom_headers).to be_nil
    end
  end
end
