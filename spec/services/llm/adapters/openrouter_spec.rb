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

RSpec.describe Llm::Adapters::Openrouter, :llm_server_helpers, :webmock do
  subject(:adapter) { described_class.new(connection) }

  let(:base_url) { "https://openrouter.ai/api/v1" }
  let(:connection) { build(:llm_connection, base_url:, api_format: "openrouter", api_key: "sk-test") }

  before { mock_llm_models_response(base_url) }

  it "adds the embedding models the unfiltered catalogue leaves out" do
    mock_llm_embedding_models_response(base_url)

    expect(adapter.models.pluck(:id)).to contain_exactly("qwen3.6-27b", "bge-m3", "voyageai/voyage-4")
  end

  it "keeps the declared output modality on the card" do
    mock_llm_embedding_models_response(base_url)

    card = adapter.models.find { |listed| listed[:id] == "voyageai/voyage-4" }

    expect(card[:raw].dig("architecture", "output_modalities")).to eq(["embeddings"])
  end

  it "lists a model once when the server ignores the filter" do
    mock_llm_embedding_models_response(base_url, models: LlmServerHelpers::DEFAULT_MODELS)

    expect(adapter.models.pluck(:id)).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  it "keeps the catalogue it did get when the filtered request is refused" do
    mock_llm_embedding_models_response(base_url, response_code: 404)

    expect(adapter.models.pluck(:id)).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  it "fails the sync when the unfiltered catalogue is refused" do
    mock_llm_models_response(base_url, response_code: 500)
    mock_llm_embedding_models_response(base_url)

    expect { adapter.models }.to raise_error(Llm::Client::ApiError)
  end

  it "names the server it is talking to" do
    mock_llm_embedding_models_response(base_url)

    expect(adapter.server_flavour).to eq("openrouter")
  end
end
