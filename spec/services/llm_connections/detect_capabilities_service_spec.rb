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

RSpec.describe LlmConnections::DetectCapabilitiesService, :llm_server_helpers, :webmock do
  subject(:service) { described_class.new(connection) }

  let(:base_url) { "https://example.com/v1" }
  let(:connection) { create(:llm_connection, :with_models, :enabled, base_url:, api_key: "sk-test") }

  it "wraps the verdict in a ServiceResult" do
    mock_llm_embeddings_response(base_url)

    result = service.detect("bge-m3")

    expect(result).to be_success
    expect(result.result).to be_supported
  end

  # Only :unsupported blocks, so downgrading a definite verdict to :unknown on
  # a transient failure would quietly make a rejected model usable again.
  it "does not overwrite a definite verdict with an inconclusive probe" do
    connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                           state: "unsupported", source: "probe", checked_at: 1.day.ago)
    mock_llm_embeddings_response(base_url, response_code: 500)

    service.detect("bge-m3")

    expect(connection.capability_verdicts.find_by(model_id: "bge-m3")).to be_unsupported
  end

  it "never overwrites an administrator's assertion" do
    connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                           state: "supported", source: "admin", checked_at: 1.day.ago)
    mock_llm_embeddings_response(base_url, response_code: 404)

    verdict = service.detect("bge-m3").result

    expect(verdict).to be_source_admin
    expect(verdict).to be_supported
  end

  it "adopts a verdict that appeared while its own probe was in flight" do
    probe = instance_double(Llm::Probes::EmbeddingsProbe)
    allow(Llm::Probes::EmbeddingsProbe).to receive(:new).and_return(probe)
    allow(probe).to receive(:call) do
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "unknown", source: "probe", checked_at: Time.current)
      Llm::Probes::EmbeddingsProbe::Result.new(state: :supported, detail: { "dimensions" => 4 })
    end

    service.detect("bge-m3")

    expect(connection.capability_verdicts.for_model("bge-m3").count).to eq(1)
    expect(connection.capability_verdicts.find_by(model_id: "bge-m3")).to be_supported
  end

  describe "#detect_likely_embedding_models" do
    before { mock_llm_embeddings_response(base_url) }

    it "probes only the models whose names suggest they embed" do
      create(:llm_model, llm_connection: connection, external_id: "nomic-embed-text")
      create(:llm_model, llm_connection: connection, external_id: "solar-10.7b-v1.0-4e5f9c")

      service.detect_likely_embedding_models

      expect(connection.capability_verdicts.pluck(:model_id)).to contain_exactly("bge-m3", "nomic-embed-text")
    end

    it "leaves out a model an administrator switched off" do
      create(:llm_model, :deactivated, llm_connection: connection, external_id: "nomic-embed-text")

      service.detect_likely_embedding_models

      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["bge-m3"])
    end

    it "stops the batch when the server has no embeddings route at all" do
      create(:llm_model, llm_connection: connection, external_id: "nomic-embed-text")
      request = mock_llm_embeddings_response(base_url, response_code: 404)

      service.detect_likely_embedding_models

      expect(request).to have_been_made.once
    end

    it "stops the batch even where an earlier verdict survives the 404" do
      create(:llm_model, llm_connection: connection, external_id: "nomic-embed-text")
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: 1.day.ago)
      request = mock_llm_embeddings_response(base_url, response_code: 404)

      service.detect_likely_embedding_models

      expect(request).to have_been_made.once
      expect(connection.capability_verdicts.find_by(model_id: "bge-m3")).to be_supported
    end

    it "spends no more than BACKGROUND_LIMIT requests" do
      (described_class::BACKGROUND_LIMIT + 5).times do |index|
        create(:llm_model, llm_connection: connection, external_id: "embed-#{index}")
      end

      service.detect_likely_embedding_models

      expect(connection.capability_verdicts.count).to eq(described_class::BACKGROUND_LIMIT)
    end
  end
end
