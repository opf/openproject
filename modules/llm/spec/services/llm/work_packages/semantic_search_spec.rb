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

RSpec.describe Llm::WorkPackages::SemanticSearch,
               with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  let(:connection) { create(:llm_connection, :with_models) }
  let(:session_double) { instance_double(Llm::Session) }
  let(:embedding_double) { instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3]) }

  # A binding may only point at a ready index, so later state changes have to
  # happen behind the model's back.
  def activate_semantic_index
    semantic_index = create(:semantic_index, state: "ready", model_id: "bge-m3",
                                             embedding_vector_dimensions: 3)
    create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                 semantic_index:)
    semantic_index
  end

  describe ".available?" do
    it "is false without an active Semantic Index" do
      expect(described_class).not_to be_available
    end

    context "when no index is bound although a default embedding model would resolve" do
      let(:connection) { create(:llm_connection, :with_models, default_embedding_model_identifier: "bge-m3") }

      it "is false" do
        expect(described_class).not_to be_available
      end
    end

    it "is false while the active Semantic Index is not ready" do
      semantic_index = activate_semantic_index

      %w[not_indexed indexing failed].each do |state|
        semantic_index.update_columns(state:)

        expect(described_class).not_to be_available, "expected to be unavailable while #{state}"
      end
    end

    it "is true with a ready active Semantic Index" do
      activate_semantic_index

      expect(described_class).to be_available
    end

    it "is false when the index model is no longer offered by the server" do
      activate_semantic_index
      connection.models.find_by(external_id: "bge-m3").update!(active: false)

      expect(described_class).not_to be_available
    end

    it "is false with the feature flag off", with_flag: { semantic_search: false } do
      activate_semantic_index

      expect(described_class).not_to be_available
    end

    it "is false when pgvector is unavailable" do
      allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)
      activate_semantic_index

      expect(described_class).not_to be_available
    end
  end

  describe ".query_vector" do
    before do
      allow(Llm::Session).to receive(:for).with(connection).and_return(session_double)
      allow(session_double).to receive(:embed).and_return(embedding_double)
    end

    it "returns nothing without an active Semantic Index" do
      expect(described_class.query_vector("some query")).to be_nil
      expect(session_double).not_to have_received(:embed)
    end

    it "returns nothing while the active Semantic Index is not ready" do
      semantic_index = activate_semantic_index
      semantic_index.update_columns(state: "indexing")

      expect(described_class.query_vector("some query")).to be_nil
      expect(session_double).not_to have_received(:embed)
    end

    context "with a ready active Semantic Index" do
      before { activate_semantic_index }

      it "embeds the query with the index's model and dimensions" do
        expect(described_class.query_vector("some query")).to eq(WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3]))
        expect(session_double).to have_received(:embed).with("some query", model: "bge-m3", dimensions: 3)
      end

      it "embeds the same query only once per request" do
        2.times { described_class.query_vector("some query") }

        expect(session_double).to have_received(:embed).once
      end

      it "returns nothing for a blank query" do
        expect(described_class.query_vector("")).to be_nil
        expect(session_double).not_to have_received(:embed)
      end

      it "returns nothing without making a request when the feature flag is off", with_flag: { semantic_search: false } do
        expect(described_class.query_vector("some query")).to be_nil
        expect(session_double).not_to have_received(:embed)
      end

      it "returns nothing when the LLM call fails" do
        allow(session_double).to receive(:embed).and_raise(Llm::Errors::ConnectionError, "timeout")

        expect(described_class.query_vector("some query")).to be_nil
      end
    end
  end
end
