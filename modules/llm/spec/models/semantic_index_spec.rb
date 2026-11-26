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

RSpec.describe SemanticIndex do
  include_context "with an embedding model offered"

  subject(:semantic_index) { build(:semantic_index) }

  it "starts out as not indexed" do
    expect(semantic_index.save).to be(true)
    expect(semantic_index.reload.status).to eq("not_indexed")
  end

  it "requires a title" do
    semantic_index.title = ""

    expect(semantic_index).not_to be_valid
    expect(semantic_index.errors.details[:title]).to include(error: :blank)
  end

  %i[embedding_vector_dimensions context_token_length].each do |attribute|
    it "requires a positive integer #{attribute}" do
      semantic_index.public_send(:"#{attribute}=", 0)

      expect(semantic_index).not_to be_valid
      expect(semantic_index.errors.details[attribute]).to include(a_hash_including(error: :greater_than))
    end
  end

  it "rejects embedding vector dimensions above the supported maximum" do
    semantic_index.embedding_vector_dimensions = WorkPackageEmbedding::DIMENSIONS + 1

    expect(semantic_index).not_to be_valid
    expect(semantic_index.errors.details[:embedding_vector_dimensions])
      .to include(a_hash_including(error: :less_than_or_equal_to, value: WorkPackageEmbedding::DIMENSIONS + 1))
  end

  describe "#status" do
    it "is derived from the claimed batch, the embeddings and the error message" do
      expect(create(:semantic_index).status).to eq("not_indexed")
      expect(create(:semantic_index, :ready).status).to eq("ready")
      expect(create(:semantic_index, :indexing).status).to eq("indexing")
      expect(create(:semantic_index, :indexing, :ready).status).to eq("indexing")
      expect(create(:semantic_index, error_message: "Some Error").status).to eq("failed")
    end

    it "stays ready with an error message while the index is searchable" do
      expect(create(:semantic_index, :ready, error_message: "Some Error").status).to eq("ready")
    end

    it "is no longer indexing once the claimed batch finished" do
      semantic_index = create(:semantic_index, :ready, :indexing)
      GoodJob::Job.where(batch_id: semantic_index.indexing_batch_id).update_all(finished_at: Time.current)

      expect(semantic_index.status).to eq("ready")
    end
  end

  describe "#searchable?" do
    it "is true once a work package is embedded, also while re-indexing" do
      expect(create(:semantic_index, :ready)).to be_searchable
      expect(create(:semantic_index, :ready, :indexing)).to be_searchable
    end

    it "is false without embedded work packages" do
      expect(create(:semantic_index)).not_to be_searchable
      expect(create(:semantic_index, :indexing)).not_to be_searchable
    end

    it "is false when no work package could be embedded" do
      semantic_index = create(:semantic_index)
      create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current)

      expect(semantic_index).not_to be_searchable
    end
  end

  describe "#active?" do
    let(:semantic_index) { create(:semantic_index, :ready) }

    it "is active once the semantic search binding references it" do
      expect { connection.feature_bindings.create!(feature_key: "semantic_search", semantic_index:) }
        .to change(semantic_index, :active?).from(false).to(true)
    end

    it "cannot be destroyed while active" do
      connection.feature_bindings.create!(feature_key: "semantic_search", semantic_index:)

      expect(semantic_index.destroy).to be(false)
      expect(described_class.exists?(semantic_index.id)).to be(true)
    end
  end
end
