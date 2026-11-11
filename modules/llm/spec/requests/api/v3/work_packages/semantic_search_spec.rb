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
require "rack/test"

RSpec.describe "API v3 work packages semantic search", content_type: :json,
                                                       with_flag: { llm_connection: true, semantic_search: true },
                                                       with_settings: { llm_features_enabled: true } do
  include API::V3::Utilities::PathHelper

  create_shared_association_defaults_for_work_package_factory

  current_user { create(:admin) }

  let(:project) { create(:project) }
  # No textual overlap with the query: only its embedding can match.
  let(:similar_wp) { create(:work_package, project:, subject: "Users cannot sign in") }
  let(:less_similar_wp) { create(:work_package, project:, subject: "Sign in trouble") }
  # Far away from the query vector: never within the semantic search distance.
  let(:unrelated_wp) { create(:work_package, project:, subject: "Quarterly roadmap planning") }

  let(:semantic_index) { create(:semantic_index, state: "ready") }

  before do
    create(:llm_feature_binding,
           llm_connection: create(:llm_connection, :with_models),
           feature_key: "semantic_search",
           semantic_index:)
    create(:work_package_embedding, work_package: similar_wp, semantic_index:, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, work_package: less_similar_wp, semantic_index:, embedding: [0.2, 0.2, 0.2])
    create(:work_package_embedding, work_package: unrelated_wp, semantic_index:, embedding: [-0.1, -0.2, -0.3])
  end

  def get_with_semantic_search_filter
    filters = [{ semanticSearch: { operator: "**", values: ["login problems"] } }].to_json
    sort_by = [["semanticSimilarity", "asc"]].to_json
    get "#{api_v3_paths.work_packages}?filters=#{CGI.escape(filters)}&sortBy=#{CGI.escape(sort_by)}"
  end

  def element_ids
    JSON.parse(last_response.body).dig("_embedded", "elements").pluck("id")
  end

  context "with semantic search available" do
    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector)
        .and_return(WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3]))
    end

    it "filters by semantic search and orders by similarity" do
      get_with_semantic_search_filter

      expect(last_response).to have_http_status 200
      expect(element_ids).to eq [similar_wp.id, less_similar_wp.id]
    end
  end

  context "with the feature flag off", with_flag: { semantic_search: false } do
    it "matches no work packages" do
      get_with_semantic_search_filter

      expect(last_response).to have_http_status 200
      expect(element_ids).to be_empty
    end
  end

  context "when pgvector is unavailable" do
    before do
      allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)
    end

    it "matches no work packages" do
      get_with_semantic_search_filter

      expect(last_response).to have_http_status 200
      expect(element_ids).to be_empty
    end
  end
end
