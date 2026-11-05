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

  it "openrouter: lists the models of the key (/models/user) and keeps text models" do
    stub_request(:get, "https://openrouter.ai/api/v1/models/user").with(headers: { "Authorization" => "Bearer sk-or" })
      .to_return(json(data: [
                        { id: "vendor/chat", architecture: { output_modalities: %w[text] } },
                        { id: "vendor/image", architecture: { output_modalities: %w[image] } }
                      ]))

    result = run("assistant_provider" => "openrouter", "assistant_api_key" => "sk-or")
    expect(result.models).to eq(%w[vendor/chat])
    expect(result.scope).to eq("key")
    expect(result).not_to be_catalogue
  end

  it "openrouter: a gateway without /models/user checks the key and lists the catalogue" do
    stub_request(:get, "https://or-proxy.example.test/api/v1/models/user").to_return(status: 404)
    stub_request(:get, "https://or-proxy.example.test/api/v1/key").to_return(json(data: { label: "x" }))
    stub_request(:get, "https://or-proxy.example.test/api/v1/models").to_return(json(data: [{ id: "vendor/chat" }]))

    result = run("assistant_provider" => "openrouter", "assistant_base_url" => "https://or-proxy.example.test/api/v1",
                 "assistant_api_key" => "sk-or")
    expect(result.models).to eq(%w[vendor/chat])
    expect(result).to be_catalogue
  end

  it "mistral: completion_chat and not archived" do
    models = [{ id: "mistral-small-latest", capabilities: { completion_chat: true } },
              { id: "mistral-embed", capabilities: { completion_chat: false } },
              { id: "retired", capabilities: { completion_chat: true }, archived: true }]
    stub_request(:get, "https://api.mistral.ai/v1/models").to_return(json(data: models))

    expect(run("assistant_provider" => "mistral", "assistant_api_key" => "k").models).to eq(%w[mistral-small-latest])
  end

  it "uses the stored key when the field is blank" do
    stored, = TestManagement::Assistant::ProviderConfig.apply({}, "assistant_provider" => "openrouter",
                                                                  "assistant_api_key" => "sk-stored")
    stub_request(:get, "https://openrouter.ai/api/v1/models/user")
      .with(headers: { "Authorization" => "Bearer sk-stored" }).to_return(json(data: []))

    expect(run({ "assistant_provider" => "openrouter", "assistant_api_key" => "" }, stored)).to be_ok
  end

  describe "#verify_model" do
    def verify(params)
      merged, errors = TestManagement::Assistant::ProviderConfig.apply({}, params)
      expect(errors).to be_empty
      described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).verify_model
    end

    it "sends one tiny chat request to the chosen model" do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(json(choices: [{ message: { role: "assistant", content: "OK" }, finish_reason: "stop" }]))

      result = verify("assistant_provider" => "openrouter", "assistant_api_key" => "sk-v",
                      "assistant_model" => "openai/gpt-4o-mini")

      expect(result).to be_ok
      expect(WebMock).to(have_requested(:post, "https://openrouter.ai/api/v1/chat/completions").with do |request|
        body = JSON.parse(request.body)
        body["model"] == "openai/gpt-4o-mini" && body["max_tokens"] == 16
      end)
    end

    it "needs a model" do
      result = verify("assistant_provider" => "openrouter", "assistant_api_key" => "sk-v")
      expect(result.error_kind).to eq(:incomplete)
    end
  end

  describe "errors" do
    it "needs a key before calling the provider" do
      expect(run("assistant_provider" => "openrouter").error_kind).to eq(:auth)
    end

    it "classifies 401 as auth and never echoes the key" do
      stub_request(:get, "https://openrouter.ai/api/v1/models/user")
        .to_return(status: 401, body: { error: { message: "Incorrect API key provided: sk-leak" } }.to_json)

      result = run("assistant_provider" => "openrouter", "assistant_api_key" => "sk-leak")
      expect(result.error_kind).to eq(:auth)
      expect(result.message).not_to include("sk-leak")
    end

    it "classifies connection errors as network errors" do
      stub_request(:get, "https://api.mistral.ai/v1/models").to_raise(Errno::ECONNREFUSED)

      expect(run("assistant_provider" => "mistral", "assistant_api_key" => "k").error_kind).to eq(:network)
    end
  end
end
