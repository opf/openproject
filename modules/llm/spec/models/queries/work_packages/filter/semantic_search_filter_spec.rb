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

RSpec.describe Queries::WorkPackages::Filter::SemanticSearchFilter do
  let(:instance) { described_class.create!(name: :semantic_search, operator: "**", values: ["login problems"]) }

  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:similar_open) { create(:work_package, status: open_status) }
  shared_let(:similar_closed) { create(:work_package, status: closed_status) }
  shared_let(:unrelated) { create(:work_package, status: open_status) }
  shared_let(:not_embedded) { create(:work_package, status: open_status) }

  shared_let(:semantic_index) { create(:semantic_index, state: "ready") }

  shared_let(:active_semantic_index) do
    create(:llm_feature_binding, llm_connection: create(:llm_connection), feature_key: "semantic_search",
                                 semantic_index:)
  end

  shared_let(:embeddings) do
    active_semantic_index
    create(:work_package_embedding, work_package: similar_open, semantic_index:, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, work_package: similar_closed, semantic_index:, embedding: [0.2, 0.2, 0.2])
    create(:work_package_embedding, work_package: unrelated, semantic_index:, embedding: [-0.1, -0.2, -0.3])
    # A stale embedding from another index must neither match nor leak in.
    create(:work_package_embedding, work_package: not_embedded, embedding: [0.1, 0.2, 0.3])
  end

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector)
      .with("login problems")
      .and_return(WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3]))
  end

  describe "#available?" do
    it "follows the availability of semantic search" do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(false)
      expect(instance).not_to be_available

      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(true)
      expect(instance).to be_available
    end
  end

  describe "#where" do
    it "restricts to the work packages within the semantic distance" do
      expect(WorkPackage.where(instance.where)).to contain_exactly(similar_open, similar_closed)
    end

    it "matches nothing when the query cannot be embedded" do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_return(nil)

      expect(WorkPackage.where(instance.where)).to be_empty
    end
  end

  describe "#valid?" do
    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(true)
    end

    it "is valid when the query embeds" do
      expect(instance).to be_valid
    end

    it "is invalid when the query cannot be embedded" do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector).and_return(nil)

      expect(instance).not_to be_valid
      expect(instance.errors[:values]).to include(I18n.t("activerecord.errors.messages.semantic_search_unavailable"))
    end
  end

  describe "in a query" do
    let(:admin) { create(:admin) }
    let(:query) do
      build(:query, project: nil, user: admin).tap do |query|
        query.add_filter("semantic_search", "**", ["login problems"])
        query.add_filter("status_id", "o", [])
        query.sort_criteria = [%w[semantic_similarity asc]]
      end
    end

    before do
      allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(true)
      login_as(admin)
    end

    it "combines with other filters" do
      expect(query.results.work_packages).to contain_exactly(similar_open)
    end

    it "only finds work packages visible to the user" do
      invisible_similar = create(:work_package, status: open_status)
      create(:work_package_embedding, work_package: invisible_similar, semantic_index:, embedding: [0.1, 0.2, 0.3])

      query.user = create(:user, member_with_permissions: { similar_open.project => %i[view_work_packages] })
      login_as(query.user)

      expect(query.results.work_packages).to contain_exactly(similar_open)
    end
  end
end
