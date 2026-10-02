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

require "spec_helper"
require_module_spec_helper

RSpec.describe Llm::TextTransformGateway, :llm_server_helpers, :webmock,
               with_flag: { llm_connection: true },
               with_settings: { llm_features_enabled: true } do
  subject(:gateway) { described_class.new }

  let(:base_url) { "https://example.com/v1" }
  let(:completions) { "#{base_url}/chat/completions" }

  def stub_stream(*chunks)
    events = chunks.map do |content|
      { id: "chatcmpl-1", object: "chat.completion.chunk", model: "qwen3.6-27b",
        choices: [{ index: 0, delta: { content: }, finish_reason: nil }] }
    end
    body = "#{events.map { |event| "data: #{event.to_json}\n\n" }.join}data: [DONE]\n\n"
    stub_request(:post, completions)
      .to_return(status: 200, headers: { "Content-Type" => "text/event-stream" }, body:)
  end

  def stream(&)
    gateway.stream(system: "Fix the grammar.", user: "Teh text", timeout: 30, &)
  end

  describe "#readiness" do
    it "is not ready while the description assistant cannot resolve a model" do
      expect(gateway.readiness).not_to be_ready
      expect(gateway.readiness.reason).to eq(:no_connection)
    end

    it "is ready once the description assistant resolves to a model" do
      create(:llm_connection, :with_models, default_chat_model_identifier: "qwen3.6-27b")

      expect(gateway.readiness).to be_ready
    end
  end

  describe "#stream" do
    let!(:connection) { create(:llm_connection, :with_models, default_chat_model_identifier: "qwen3.6-27b") }

    it "streams the completion for the resolved model and returns the full text" do
      stub_stream("Hello", " world")
      deltas = []

      text = stream { |delta| deltas << delta }

      expect(deltas).to eq(["Hello", " world"])
      expect(text).to eq("Hello world")
    end

    it "ignores chunks that carry no content" do
      stub_stream(nil, "Hello", nil, " world")
      deltas = []

      text = stream { |delta| deltas << delta }

      expect(deltas).to eq(["Hello", " world"])
      expect(text).to eq("Hello world")
    end

    it "reports an upstream error when the model answers without any text" do
      stub_stream(nil, "")

      expect { stream { nil } }.to raise_error(AI::TextTransforms::Errors::Upstream)
    end

    it "sends the instructions ahead of the content as a streamed chat completion" do
      stub_stream("ok")

      stream { nil }

      expect(WebMock).to(have_requested(:post, completions).with do |request|
        body = JSON.parse(request.body)
        body["model"] == "qwen3.6-27b" &&
          body["stream"] == true &&
          body["messages"].pluck("content") == ["Fix the grammar.", "Teh text"] &&
          body["messages"].last["role"] == "user"
      end)
    end

    it "lets a cancellation raised by the consumer through untranslated" do
      stub_stream("Hello", " world")

      expect { stream { raise AI::TextTransforms::Cancelled } }
        .to raise_error(AI::TextTransforms::Cancelled)
    end

    it "reports a read timeout as a timed out transform" do
      stub_request(:post, completions).to_raise(Net::ReadTimeout)

      expect { stream { nil } }.to raise_error(AI::TextTransforms::Errors::TimedOut)
    end

    it "reports an unreachable server as a failed connection" do
      stub_request(:post, completions).to_raise(Errno::ECONNREFUSED)

      expect { stream { nil } }.to raise_error(AI::TextTransforms::Errors::ConnectionFailed)
    end

    it "reports a server error as an upstream error without leaking its body" do
      stub_request(:post, completions).to_return(status: 500, body: '{"error":"secret details"}')

      expect { stream { nil } }.to raise_error(AI::TextTransforms::Errors::Upstream) do |error|
        expect(error.message).not_to include("secret details")
      end
    end

    it "reports the assistant as not available when no model resolves" do
      connection.update!(default_chat_model: nil)

      expect { stream { nil } }.to raise_error(AI::TextTransforms::Errors::NotAvailable)
    end
  end

  describe "registration with the text transform port" do
    it "is the gateway the port builds by default" do
      expect(AI::TextTransforms::Gateway.build).to be_a(described_class)
    end
  end
end
