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

RSpec.describe Queries::WorkPackages::Filter::HybridSearchFilter do
  let(:instance) { described_class.create!(name: :hybrid_search, operator: "**", values: ["login problems"]) }

  shared_let(:open_status) { create(:status) }
  shared_let(:closed_status) { create(:closed_status) }
  # Matches textually and semantically.
  shared_let(:both) { create(:work_package, status: open_status, subject: "Login problems handbook") }
  # Matches only textually.
  shared_let(:text_only) { create(:work_package, status: open_status, subject: "Login problems guide") }
  # Matches only semantically: no textual overlap with the query.
  shared_let(:semantic_only) { create(:work_package, status: closed_status, subject: "Users cannot sign in") }
  shared_let(:unrelated) { create(:work_package, status: open_status, subject: "Quarterly roadmap planning") }

  shared_let(:semantic_index) { create(:semantic_index, state: "ready") }

  shared_let(:active_semantic_index) do
    create(:llm_feature_binding, llm_connection: create(:llm_connection), feature_key: "semantic_search",
                                 semantic_index:)
  end

  shared_let(:embeddings) do
    active_semantic_index
    create(:work_package_embedding, work_package: both, semantic_index:, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, work_package: semantic_only, semantic_index:, embedding: [0.2, 0.2, 0.2])
    create(:work_package_embedding, work_package: text_only, semantic_index:, embedding: [-0.1, -0.2, -0.3])
    # A similar embedding from another index must neither match nor leak in.
    create(:work_package_embedding, work_package: unrelated, embedding: [0.1, 0.2, 0.3])
  end

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector)
      .with("login problems")
      .and_return(WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3]))
  end

  describe "#where" do
    it "matches the union of text-based and semantic results" do
      expect(WorkPackage.where(instance.where)).to contain_exactly(both, text_only, semantic_only)
    end

    it "degrades to text-based results when the query cannot be embedded" do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_return(nil)

      expect(WorkPackage.where(instance.where)).to contain_exactly(both, text_only)
    end

    it "matches nothing when the value is blank" do
      instance.values = [""]

      expect(WorkPackage.where(instance.where)).to be_empty
    end
  end

  describe "when semantic search is unavailable" do
    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_call_original
    end

    context "with the feature flag off", with_flag: { semantic_search: false } do
      it "stays available and degrades to text-based results" do
        expect(instance).to be_available
        expect(WorkPackage.where(instance.where)).to contain_exactly(both, text_only)
      end
    end

    context "when pgvector is unavailable", with_flag: { semantic_search: true } do
      before do
        allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)
      end

      it "stays available and degrades to text-based results" do
        expect(instance).to be_available
        expect(WorkPackage.where(instance.where)).to contain_exactly(both, text_only)
      end
    end
  end

  describe "#valid?" do
    it "is valid when the query embeds" do
      expect(instance).to be_valid
    end

    it "is still valid when the query cannot be embedded, degrading silently to text search" do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_return(nil)

      expect(instance).to be_valid
    end

    it "is invalid without a value" do
      instance.values = []

      expect(instance).not_to be_valid
    end
  end

  describe "in a query" do
    let(:admin) { create(:admin) }
    let(:query) do
      build(:query, project: nil, user: admin).tap do |query|
        query.add_filter("hybrid_search", "**", ["login problems"])
        query.add_filter("status_id", "o", [])
        query.sort_criteria = [%w[hybrid_score desc]]
      end
    end

    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(true)
      login_as(admin)
    end

    it "combines with other filters" do
      expect(query.results.work_packages).to contain_exactly(both, text_only)
    end

    it "only finds work packages visible to the user" do
      invisible_semantic = create(:work_package, status: closed_status, subject: "Cannot sign in at all")
      create(:work_package_embedding, work_package: invisible_semantic, semantic_index:, embedding: [0.1, 0.2, 0.3])

      query.user = create(:user, member_with_permissions: { both.project => %i[view_work_packages] })
      login_as(query.user)

      expect(query.results.work_packages).to contain_exactly(both)
    end
  end
end
