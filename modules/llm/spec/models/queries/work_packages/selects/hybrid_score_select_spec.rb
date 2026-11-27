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

RSpec.describe Queries::WorkPackages::Selects::HybridScoreSelect do
  shared_let(:admin) { create(:admin) }
  # Text match (most recent), no semantic match: text rank 1, RRF 1/61.
  shared_let(:text_recent) do
    create(:work_package, subject: "Login problems guide", updated_at: 1.day.ago)
  end
  # Text match (older) and semantic match (closest): text rank 2 + semantic rank 1,
  # RRF 1/62 + 1/61 — the highest score.
  shared_let(:both) do
    create(:work_package, subject: "Login problems handbook", updated_at: 3.days.ago)
  end
  # Semantic match only: semantic rank 2, RRF 1/62.
  shared_let(:semantic_only) { create(:work_package, subject: "Users cannot sign in") }
  shared_let(:unrelated) { create(:work_package, subject: "Quarterly roadmap planning") }

  shared_let(:semantic_index) { create(:semantic_index, state: "ready") }

  shared_let(:active_semantic_index) do
    create(:llm_feature_binding, llm_connection: create(:llm_connection), feature_key: "semantic_search",
                                 semantic_index:)
  end

  shared_let(:embeddings) do
    active_semantic_index
    create(:work_package_embedding, work_package: both, semantic_index:, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, work_package: semantic_only, semantic_index:, embedding: [0.2, 0.2, 0.2])
    create(:work_package_embedding, work_package: text_recent, semantic_index:, embedding: [-0.1, -0.2, -0.3])
  end

  let(:query) do
    build(:query, project: nil, user: admin).tap do |query|
      query.sort_criteria = [%w[hybrid_score desc]]
    end
  end

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive_messages(
      available?: true,
      query_vector: WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3])
    )
    login_as(admin)
  end

  it "orders the union of text and semantic results by RRF score" do
    query.add_filter("hybrid_search", "**", ["login problems"])

    expect(query.results.work_packages.to_a).to eq([both, text_recent, semantic_only])
  end

  it "uses a constant order when no hybrid search filter is present" do
    expect(described_class.rrf_order_sql(query)).to eq described_class::NO_SCORE_SQL
  end

  context "when semantic search is unavailable" do
    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_call_original
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_call_original
    end

    context "with the feature flag off", with_flag: { semantic_search: false } do
      it "degrades to the text-based results ordered by recency" do
        query.add_filter("hybrid_search", "**", ["login problems"])

        expect(query.results.work_packages.to_a).to eq([text_recent, both])
      end
    end

    context "when the query cannot be embedded" do
      before do
        allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_return(nil)
      end

      it "degrades to the text-based results ordered by recency" do
        query.add_filter("hybrid_search", "**", ["login problems"])

        expect(query.results.work_packages.to_a).to eq([text_recent, both])
      end
    end
  end
end
