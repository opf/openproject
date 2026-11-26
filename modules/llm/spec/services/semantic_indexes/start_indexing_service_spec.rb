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

RSpec.describe SemanticIndexes::StartIndexingService,
               with_flag: { llm_connection: true },
               with_good_job_batches: [Llm::IndexWorkPackagesJob],
               with_settings: { llm_features_enabled: true } do
  include_context "with an embedding model offered"

  let(:semantic_index) { create(:semantic_index) }
  let(:user) { build_stubbed(:admin) }

  subject(:result) { described_class.new(user:, model: semantic_index).call }

  def index_jobs = GoodJob::Job.where(job_class: Llm::IndexWorkPackagesJob.name)

  it "starts indexing" do
    expect(result).to be_success
    expect(semantic_index.reload.status).to eq("indexing")
    expect(index_jobs.map { it.serialized_params["arguments"] }).to eq([[semantic_index.id]])
  end

  it "clears the failed work packages so the run retries them" do
    failed = create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current)
    embedded = create(:work_package_embedding, semantic_index:)
    failed_elsewhere = create(:work_package_embedding, embedding: nil, failed_at: Time.current)

    expect(result).to be_success
    expect(WorkPackageEmbedding.where(id: [failed, embedded, failed_elsewhere])).to contain_exactly(embedded, failed_elsewhere)
  end

  context "when the Semantic Index is already indexing" do
    let(:semantic_index) { create(:semantic_index, :indexing) }

    it "fails without enqueuing" do
      expect(result).to be_failure
      expect(result.message).to eq(I18n.t("admin.semantic_indexes.start_indexing.not_indexable"))
      expect(semantic_index.reload.status).to eq("indexing")
      expect(index_jobs).to be_empty
    end

    it "keeps the failed work packages" do
      create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current)

      expect { result }.not_to change(WorkPackageEmbedding, :count)
    end
  end

  context "when pgvector is unavailable" do
    before { allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false) }

    it "fails without enqueuing" do
      expect(result).to be_failure
      expect(result.message).to eq(I18n.t("admin.semantic_indexes.indexing.not_ready.pgvector_missing"))
      expect(semantic_index.reload.status).to eq("not_indexed")
      expect(index_jobs).to be_empty
    end
  end

  context "without a connection" do
    before { allow(LlmConnection).to receive(:available?).and_return(false) }

    it "fails without enqueuing" do
      expect(result).to be_failure
      expect(result.message).to eq(I18n.t("admin.semantic_indexes.indexing.not_ready.no_connection"))
      expect(index_jobs).to be_empty
    end
  end

  context "when the connection no longer offers the model" do
    let(:semantic_index) { create(:semantic_index, model_id: "no-longer-offered") }

    it "fails without recording the error" do
      expect(result).to be_failure
      expect(result.message)
        .to eq(I18n.t("admin.semantic_indexes.indexing.not_ready.model_missing", model: "no-longer-offered"))
      expect(semantic_index.reload.error_message).to be_nil
      expect(index_jobs).to be_empty
    end
  end

  context "as a regular user" do
    let(:user) { build_stubbed(:user) }

    it "fails without changing the state" do
      expect(result).to be_failure
      expect(semantic_index.reload.status).to eq("not_indexed")
    end
  end
end
