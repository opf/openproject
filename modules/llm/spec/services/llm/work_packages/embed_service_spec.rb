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

RSpec.describe Llm::WorkPackages::EmbedService,
               with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  include_context "with an embedding model offered"

  let(:work_package) { create(:work_package, subject: "Fix bug") }
  let(:semantic_index) do
    create(:semantic_index, model_id: "bge-m3", embedding_vector_dimensions: 3, context_token_length: 512)
  end
  let(:session_double) { instance_double(Llm::Session) }
  let(:embedding_double) { instance_double(RubyLLM::Embedding, vectors: [[1.0, 2.0, 3.0]]) }

  subject(:service) { described_class.new(semantic_index, [work_package.id]) }

  def expected_vector(*values)
    padding = Array.new(WorkPackageEmbedding::DIMENSIONS - values.size, "0")
    "[#{values.map(&:to_s).concat(padding).join(',')}]"
  end

  before do
    allow(Llm::Session).to receive(:for).with(connection).and_return(session_double)
    allow(session_double).to receive(:embed).and_return(embedding_double)
  end

  context "when no connection is configured" do
    before do
      connection.destroy!
    end

    it "raises NotReady" do
      expect { service.call }.to raise_error(Llm::Errors::NotReady, /no_connection/)
    end
  end

  it "embeds with the parameters of the Semantic Index" do
    allow(Llm::WorkPackages::EmbeddableText).to receive(:for).and_call_original

    service.call

    expect(session_double).to have_received(:embed).with(anything, model: "bge-m3", dimensions: 3)
    expect(Llm::WorkPackages::EmbeddableText).to have_received(:for).with(work_package, context_window: 512)
  end

  it "stores the embedding in the Semantic Index" do
    service.call

    record = WorkPackageEmbedding.find_by!(semantic_index:, work_package:)
    expect(record.embedding).to eq(expected_vector(1, 2, 3))
  end

  it "remembers the update and the text it embedded" do
    service.call

    record = WorkPackageEmbedding.find_by!(semantic_index:, work_package:)
    expect(record.work_package_updated_at).to eq(work_package.updated_at)
    expect(record.text_digest).to eq(Digest::MD5.hexdigest("Fix bug\n#{work_package.description}"))
  end

  it "replaces an earlier embedding of the same work package" do
    service.call
    allow(session_double).to receive(:embed)
      .and_return(instance_double(RubyLLM::Embedding, vectors: [[4.0, 5.0, 6.0]]))

    described_class.new(semantic_index, [work_package.id]).call

    record = WorkPackageEmbedding.find_by!(semantic_index:, work_package:)
    expect(record.embedding).to eq(expected_vector(4, 5, 6))
  end

  it "returns without embedding when there is nothing to index" do
    expect(described_class.new(semantic_index, []).call).to be_nil
    expect(session_double).not_to have_received(:embed)
  end

  it "leaves the embeddings of other Semantic Indexes alone" do
    other_index = create(:semantic_index)
    create(:work_package_embedding, semantic_index: other_index, work_package:)

    service.call

    expect(WorkPackageEmbedding.where(work_package:).count).to eq(2)
  end

  it "stores embeddings for work packages that still exist when one is deleted during the call" do
    to_be_deleted_work_package = create(:work_package, subject: "Delete Me!")
    embeddings = instance_double(RubyLLM::Embedding, vectors: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    allow(session_double).to receive(:embed) do
      to_be_deleted_work_package.destroy!
      embeddings
    end

    expect { described_class.new(semantic_index, [work_package.id, to_be_deleted_work_package.id]).call }.not_to raise_error

    expect(WorkPackageEmbedding.exists?(work_package_id: to_be_deleted_work_package.id)).to be(false)
    expect(WorkPackageEmbedding.exists?(work_package_id: work_package.id)).to be(true)
  end

  context "when the server refuses the text" do
    let(:refusal) { Llm::Errors::ContextLengthError.new("too large", status: 400) }

    before { allow(session_double).to receive(:embed).and_raise(refusal) }

    it "remembers the failed text without an embedding" do
      service.call

      record = WorkPackageEmbedding.find_by!(semantic_index:, work_package:)
      expect(record.embedding).to be_nil
      expect(record.failed_at).to be_present
      expect(record.work_package_updated_at).to eq(work_package.updated_at)
      expect(record.text_digest).to eq(Digest::MD5.hexdigest("Fix bug\n#{work_package.description}"))
    end

    it "clears an earlier embedding of the previous text" do
      create(:work_package_embedding, semantic_index:, work_package:, embedding: [1.0, 2.0, 3.0])

      service.call

      record = WorkPackageEmbedding.find_by!(semantic_index:, work_package:)
      expect(record.embedding).to be_nil
      expect(record.failed_at).to be_present
    end

    it "is cleared by a later embedding" do
      service.call
      allow(session_double).to receive(:embed).and_return(embedding_double)

      described_class.new(semantic_index, [work_package.id]).call

      expect(WorkPackageEmbedding.find_by!(semantic_index:, work_package:).failed_at).to be_nil
    end

    [400, 413, 422].each do |status|
      context "with a #{status}" do
        let(:refusal) { Llm::Errors::InvalidInputError.new("invalid input", status:) }

        it "remembers the failed text" do
          service.call

          expect(WorkPackageEmbedding.find_by!(semantic_index:, work_package:).failed_at).to be_present
        end
      end
    end

    it "raises for several work packages, as any of them may be the cause" do
      other_work_package = create(:work_package)

      expect { described_class.new(semantic_index, [work_package.id, other_work_package.id]).call }
        .to raise_error(Llm::Errors::ContextLengthError)
      expect(WorkPackageEmbedding.count).to eq(0)
    end
  end

  [Llm::Errors::ApiError.new("down", status: 503), Llm::Errors::ApiError.new("missing", status: 404),
   Llm::Errors::AuthenticationError.new("rejected")].each do |error|
    it "raises a #{error.class.name.demodulize} #{error.try(:status)} without remembering the text" do
      allow(session_double).to receive(:embed).and_raise(error)

      expect { service.call }.to raise_error(error)
      expect(WorkPackageEmbedding.count).to eq(0)
    end
  end
end
