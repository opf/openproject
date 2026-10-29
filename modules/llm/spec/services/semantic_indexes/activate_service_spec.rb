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

RSpec.describe SemanticIndexes::ActivateService do
  include_context "with an embedding model offered"

  let(:semantic_index) { create(:semantic_index, state: "ready") }
  let(:user) { build_stubbed(:admin) }

  subject(:result) { described_class.new(user:, model: semantic_index).call }

  def active_semantic_index = SemanticIndex.semantic_search_binding.semantic_index

  it "makes the Semantic Index the active one" do
    expect(result).to be_success
    expect(active_semantic_index).to eq(semantic_index)
  end

  it "replaces the previously active Semantic Index" do
    previous = create(:semantic_index, state: "ready")
    connection.feature_bindings.create!(feature_key: "semantic_search", semantic_index: previous)

    expect(result).to be_success
    expect(active_semantic_index).to eq(semantic_index)
    expect(previous).not_to be_active
  end

  context "when the Semantic Index is not ready" do
    let(:semantic_index) { create(:semantic_index, state: "failed") }

    it "fails" do
      expect(result).to be_failure
      expect(result.message).to eq("Semantic Index must be ready before it can be activated.")
      expect(active_semantic_index).to be_nil
    end
  end

  context "when pgvector is unavailable" do
    before { allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false) }

    it "fails" do
      expect(result).to be_failure
      expect(result.message).to eq("The pgvector extension is not installed. " \
                                   "Install it and run the migrations again to start indexing.")
      expect(active_semantic_index).to be_nil
    end
  end

  context "as a regular user" do
    let(:user) { build_stubbed(:user) }

    it "fails" do
      expect(result).to be_failure
      expect(active_semantic_index).to be_nil
    end
  end
end
