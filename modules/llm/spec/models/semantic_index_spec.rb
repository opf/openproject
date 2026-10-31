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
    expect(semantic_index.reload).to be_not_indexed
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

  describe "#start_indexing!" do
    %w[not_indexed failed ready].each do |state|
      it "starts indexing from #{state} and clears the previous error" do
        semantic_index = create(:semantic_index, state:, error_message: "Some Error")

        semantic_index.start_indexing!

        expect(semantic_index.reload).to have_attributes(state: "indexing", error_message: nil)
      end
    end

    it "refuses to start while indexing" do
      semantic_index = create(:semantic_index, state: "indexing")

      expect { semantic_index.start_indexing! }.to raise_error(SemanticIndex::InvalidTransitionError)
      expect(semantic_index.reload).to be_indexing
    end
  end

  describe "finishing indexing" do
    let(:semantic_index) { create(:semantic_index, state: "indexing") }

    it "becomes ready" do
      semantic_index.finish_indexing!

      expect(semantic_index.reload).to be_ready
    end

    it "fails with an error message" do
      semantic_index.fail_indexing!("Some Error")

      expect(semantic_index.reload).to have_attributes(state: "failed", error_message: "Some Error")
    end

    it "refuses unless indexing" do
      semantic_index.update!(state: "not_indexed")

      expect { semantic_index.finish_indexing! }.to raise_error(SemanticIndex::InvalidTransitionError)
      expect { semantic_index.fail_indexing!("Some Error") }.to raise_error(SemanticIndex::InvalidTransitionError)
    end
  end

  describe "#stop_indexing!" do
    let(:semantic_index) { create(:semantic_index, state: "indexing", error_message: "Some Error") }

    it "returns to not indexed and clears the error" do
      semantic_index.stop_indexing!

      expect(semantic_index.reload).to have_attributes(state: "not_indexed", error_message: nil)
    end

    it "refuses unless indexing" do
      semantic_index.update!(state: "ready")

      expect { semantic_index.stop_indexing! }.to raise_error(SemanticIndex::InvalidTransitionError)
      expect(semantic_index.reload).to be_ready
    end
  end

  describe "#active?" do
    let(:semantic_index) { create(:semantic_index, state: "ready") }

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
