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

RSpec.describe Queries::WorkPackages::Filter::HybridTypeaheadFilter do
  let(:instance) { described_class.create!(name: :hybrid_typeahead, operator: "**", values: ["login problems"]) }

  shared_let(:open_status) { create(:status) }
  # Matches the typeahead tokens textually and semantically.
  shared_let(:both) do
    create(:work_package, status: open_status, subject: "Login problems handbook", updated_at: 3.days.ago)
  end
  # Matches only textually.
  shared_let(:text_only) do
    create(:work_package, status: open_status, subject: "Problems with login page", updated_at: 1.day.ago)
  end
  # Matches only semantically: no textual overlap with the query tokens.
  shared_let(:semantic_only) { create(:work_package, status: open_status, subject: "Users cannot sign in") }
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
  end

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector)
      .with("login problems")
      .and_return(WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3]))
  end

  # The typeahead arm references the projects/types/statuses tables, so the raw
  # where clause needs the same joins the filter declares for queries.
  def matching_work_packages
    WorkPackage.joins(:project, :type, :status).where(instance.where)
  end

  describe "#where" do
    it "matches the union of typeahead and semantic results" do
      expect(matching_work_packages).to contain_exactly(both, text_only, semantic_only)
    end

    it "keeps the typeahead behavior of matching project names" do
      named_project = create(:project, name: "Login problems rollout")
      project_wp = create(:work_package, status: open_status, project: named_project, subject: "Some task")

      expect(matching_work_packages).to include(project_wp)
    end

    it "degrades to typeahead results when the query cannot be embedded" do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_return(nil)

      expect(matching_work_packages).to contain_exactly(both, text_only)
    end
  end

  describe "when semantic search is unavailable" do
    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_call_original
    end

    context "with the feature flag off", with_flag: { semantic_search: false } do
      it "degrades to typeahead results" do
        expect(matching_work_packages).to contain_exactly(both, text_only)
      end
    end
  end

  describe "in a query" do
    let(:admin) { create(:admin) }
    let(:query) do
      build(:query, project: nil, user: admin).tap do |query|
        query.add_filter("hybrid_typeahead", "**", ["login problems"])
        query.sort_criteria = [%w[hybrid_score desc]]
      end
    end

    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(true)
      login_as(admin)
    end

    it "finds the union ordered by RRF score, with type/status joins applied" do
      expect(query.results.work_packages.to_a).to eq([both, text_only, semantic_only])
    end

    it "only finds work packages visible to the user" do
      invisible_semantic = create(:work_package, status: open_status, subject: "Cannot sign in at all")
      create(:work_package_embedding, work_package: invisible_semantic, semantic_index:, embedding: [0.1, 0.2, 0.3])

      query.user = create(:user, member_with_permissions: { both.project => %i[view_work_packages] })
      login_as(query.user)

      expect(query.results.work_packages).to contain_exactly(both)
    end
  end
end
