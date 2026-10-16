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

RSpec.describe Queries::WorkPackages::Selects::SemanticSimilaritySelect do
  shared_let(:admin) { create(:admin) }
  shared_let(:first) { create(:work_package) }
  shared_let(:second) { create(:work_package) }
  shared_let(:third) { create(:work_package) }

  shared_let(:semantic_index) { create(:semantic_index, state: "ready") }

  shared_let(:active_semantic_index) do
    create(:llm_feature_binding, llm_connection: create(:llm_connection), feature_key: "semantic_search",
                                 semantic_index:)
  end

  shared_let(:embeddings) do
    active_semantic_index
    create(:work_package_embedding, work_package: third, semantic_index:, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, work_package: first, semantic_index:, embedding: [0.2, 0.2, 0.2])
    create(:work_package_embedding, work_package: second, semantic_index:, embedding: [0.3, 0.2, 0.1])
    # second also has a stale embedding in another index: the ranking must use
    # only the active one, not fail on the extra row.
    create(:work_package_embedding, work_package: second, embedding: [0.9, 0.9, 0.9])
  end

  let(:query) do
    build(:query, project: nil, user: admin).tap do |query|
      query.sort_criteria = [%w[semantic_similarity asc], %w[id asc]]
    end
  end

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive_messages(
      available?: true,
      query_vector: WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3])
    )
    login_as(admin)
  end

  it "has a caption, which the API needs to render the sort criteria" do
    expect(described_class.instances.caption).to eq("Similarity")
  end

  it "orders by vector distance when the semantic search filter is active" do
    query.add_filter("semantic_search", "**", ["login problems"])

    expect(query.results.work_packages.to_a).to eq([third, first, second])
  end
end
