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

RSpec.describe Llm::Client, :llm_server_helpers, :webmock do
  subject(:client) { described_class.new(base_url:, api_key: "sk-test") }

  let(:base_url) { "https://example.com/v1" }

  describe "#models" do
    it "reads a catalogue served in the documented envelope" do
      mock_llm_models_response(base_url)

      expect(client.models["data"].pluck("id")).to contain_exactly("qwen3.6-27b", "bge-m3")
    end

    it "reads a catalogue served as a bare array" do
      mock_llm_models_response(base_url, body: LlmServerHelpers::DEFAULT_MODELS.to_json)

      expect(client.models["data"].pluck("id")).to contain_exactly("qwen3.6-27b", "bge-m3")
    end

    it "refuses a body that is not a catalogue at all" do
      mock_llm_models_response(base_url, body: { error: "no such route" }.to_json)

      expect { client.models }.to raise_error(Llm::Client::ParseError)
    end
  end

  describe "the credentials it sends" do
    it "sends the stored key as a bearer token" do
      mock_llm_models_response(base_url)

      client.models

      expect(WebMock).to have_requested(:get, "#{base_url}/models")
        .with(headers: { "Authorization" => "Bearer sk-test" })
    end

    # httpx's auth plugin appends rather than replaces, so building the request
    # the other way round sent both values and a gateway expecting only its own
    # token also received the stored key.
    it "lets a connection's own Authorization header replace the key" do
      mock_llm_models_response(base_url)

      described_class.new(base_url:, api_key: "sk-test", headers: { "Authorization" => "Bearer gw-token" }).models

      expect(WebMock).to have_requested(:get, "#{base_url}/models")
        .with(headers: { "Authorization" => "Bearer gw-token" })
      expect(WebMock).not_to(have_requested(:get, "#{base_url}/models")
        .with { |request| request.headers["Authorization"].to_s.include?("sk-test") })
    end

    it "sends a connection's other headers alongside the key" do
      mock_llm_models_response(base_url)

      described_class.new(base_url:, api_key: "sk-test", headers: { "api-version" => "2024-02-01" }).models

      expect(WebMock).to have_requested(:get, "#{base_url}/models")
        .with(headers: { "Authorization" => "Bearer sk-test", "api-version" => "2024-02-01" })
    end
  end
end
