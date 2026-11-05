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

RSpec.describe TestManagement::Assistant::AI::ConnectionTest, :disable_ssrf_filter, :webmock do
  def run(params, stored = {})
    merged, errors = TestManagement::Assistant::ProviderConfig.apply(stored, params)
    expect(errors).to be_empty
    described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).call
  end

  def json(body) = { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }

  it "openai: lists chat models only, sorted and de-duplicated" do
    stub_request(:get, "https://api.openai.com/v1/models").with(headers: { "Authorization" => "Bearer sk-o" })
      .to_return(json(data: %w[gpt-4o text-embedding-3-small whisper-1 gpt-4o-mini dall-e-3 tts-1 gpt-4o].map { { id: it } }))

    result = run("assistant_provider" => "openai", "assistant_api_key" => "sk-o")

    expect(result).to be_ok
    expect(result.models).to eq(%w[gpt-4o gpt-4o-mini])
    expect(result).to be_catalogue
  end

  it "anthropic: native models endpoint with x-api-key" do
    stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000")
      .with(headers: { "x-api-key" => "sk-a", "anthropic-version" => "2023-06-01" })
      .to_return(json(data: [{ id: "claude-b", type: "model" }, { id: "claude-a", type: "model" }], has_more: false))

    result = run("assistant_provider" => "anthropic", "assistant_api_key" => "sk-a")
    expect(result.models).to eq(%w[claude-a claude-b])
    expect(result).to be_catalogue
  end

  it "custom: generic listing" do
    stub_request(:get, "https://gw.example.test/v1/models").to_return(json(data: [{ id: "local-model" }, { id: "bge-embed" }]))

    result = run("assistant_provider" => "custom", "assistant_base_url" => "https://gw.example.test/v1",
                 "assistant_auth_style" => "none")
    expect(result.models).to eq(%w[local-model])
  end

  it "uses the stored key when the field is blank" do
    stored, = TestManagement::Assistant::ProviderConfig.apply({}, "assistant_provider" => "openai",
                                                                  "assistant_api_key" => "sk-stored")
    stub_request(:get, "https://api.openai.com/v1/models")
      .with(headers: { "Authorization" => "Bearer sk-stored" }).to_return(json(data: []))

    expect(run({ "assistant_provider" => "openai", "assistant_api_key" => "" }, stored)).to be_ok
  end

  describe "#verify_model" do
    def verify(params)
      merged, errors = TestManagement::Assistant::ProviderConfig.apply({}, params)
      expect(errors).to be_empty
      described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).verify_model
    end

    it "sends one tiny chat request to the chosen model" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(json(choices: [{ message: { role: "assistant", content: "OK" }, finish_reason: "stop" }]))

      result = verify("assistant_provider" => "openai", "assistant_api_key" => "sk-v", "assistant_model" => "gpt-4o-mini")

      expect(result).to be_ok
      expect(WebMock).to(have_requested(:post, "https://api.openai.com/v1/chat/completions").with do |request|
        body = JSON.parse(request.body)
        body["model"] == "gpt-4o-mini" && body["max_completion_tokens"] == 16 && body["messages"].size == 1
      end)
    end

    it "reports a model the key may not use, without the key" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 403, body: { error: { message: "Project does not have access to model gpt-x (key sk-v)" } }.to_json)

      result = verify("assistant_provider" => "openai", "assistant_api_key" => "sk-v", "assistant_model" => "gpt-x")

      expect(result).not_to be_ok
      expect(result.error_kind).to eq(:model)
      expect(result.message).not_to include("sk-v")
    end

    it "needs a model" do
      result = verify("assistant_provider" => "openai", "assistant_api_key" => "sk-v")
      expect(result.error_kind).to eq(:incomplete)
      expect(WebMock).not_to have_requested(:any, /.*/)
    end
  end

  describe "errors" do
    it "needs a key before calling the provider" do
      expect(run("assistant_provider" => "openai").error_kind).to eq(:auth)
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it "classifies 401 as auth and never echoes the key" do
      stub_request(:get, "https://api.openai.com/v1/models")
        .to_return(status: 401, body: { error: { message: "Incorrect API key provided: sk-leak" } }.to_json)

      result = run("assistant_provider" => "openai", "assistant_api_key" => "sk-leak")
      expect(result.error_kind).to eq(:auth)
      expect(result.message).not_to include("sk-leak")
    end

    it "classifies 404 and timeouts" do
      stub_request(:get, "https://gw.example.test/v1/models").to_return(status: 404)
      expect(run("assistant_provider" => "custom", "assistant_base_url" => "https://gw.example.test/v1",
                 "assistant_auth_style" => "none").error_kind).to eq(:not_found)

      stub_request(:get, "https://api.openai.com/v1/models").to_timeout
      expect(run("assistant_provider" => "openai", "assistant_api_key" => "k").error_kind).to eq(:timeout)
    end

    it "classifies connection errors as network errors" do
      stub_request(:get, "https://api.openai.com/v1/models").to_raise(Errno::ECONNREFUSED)

      expect(run("assistant_provider" => "openai", "assistant_api_key" => "k").error_kind).to eq(:network)
    end
  end
end
