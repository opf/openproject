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

RSpec.describe Llm::Probes::EmbeddingsProbe, :webmock do
  subject(:result) { described_class.new(connection).call("some-model") }

  let(:connection) { build(:llm_connection, base_url: "https://example.com/v1") }

  def stub_embeddings(status:, body:)
    stub_request(:post, "https://example.com/v1/embeddings")
      .to_return(status:, headers: { "Content-Type" => "application/json" }, body: body.to_json)
  end

  context "when the server returns a vector" do
    before { stub_embeddings(status: 200, body: { data: [{ embedding: [0.1, 0.2, 0.3] }] }) }

    it "is supported and captures the dimension count" do
      expect(result.state).to eq(:supported)
      expect(result.detail["dimensions"]).to eq(3)
    end
  end

  # vLLM, llama.cpp and Ollama all silently drop parameters they do not
  # understand, so a 200 on its own proves nothing about the model.
  context "when the server returns 200 with something that is not an embedding" do
    before { stub_embeddings(status: 200, body: { data: [{ message: "hello" }] }) }

    it "is unknown rather than supported" do
      expect(result.state).to eq(:unknown)
      expect(result.detail["reason"]).to eq("unexpected_body")
    end
  end

  context "when the server returns an empty data array" do
    before { stub_embeddings(status: 200, body: { data: [] }) }

    it { expect(result.state).to eq(:unknown) }
  end

  [400, 404, 501].each do |status|
    context "when the server refuses the request with #{status}" do
      before { stub_embeddings(status:, body: { error: "nope" }) }

      it "is unsupported" do
        expect(result.state).to eq(:unsupported)
        expect(result.detail["http_status"]).to eq(status)
      end
    end
  end

  # A 5xx says something about the server, not about the model.
  context "when the server errors" do
    before { stub_embeddings(status: 500, body: { error: "boom" }) }

    it { expect(result.state).to eq(:unknown) }
  end

  context "when the credentials are rejected" do
    before { stub_embeddings(status: 401, body: { error: "no" }) }

    it "is unknown, since this says nothing about the model" do
      expect(result.state).to eq(:unknown)
      expect(result.detail["reason"]).to eq("unauthorized")
    end
  end

  context "when the server cannot be reached" do
    before { stub_request(:post, "https://example.com/v1/embeddings").to_timeout }

    it { expect(result.state).to eq(:unknown) }
  end
end
