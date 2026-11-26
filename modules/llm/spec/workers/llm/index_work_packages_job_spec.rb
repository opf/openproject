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

RSpec.describe Llm::IndexWorkPackagesJob,
               with_flag: { llm_connection: true, semantic_search: true },
               with_good_job_batches: [Llm::IndexWorkPackagesJob, Llm::EmbedWorkPackagesJob],
               with_settings: { llm_features_enabled: true } do
  include_context "with an embedding model offered"

  let(:semantic_index) { create(:semantic_index, :ready) }

  let(:job) { described_class.new }

  def embed_job_arguments
    GoodJob::Job.where(batch_id: semantic_index.reload.indexing_batch_id, job_class: Llm::EmbedWorkPackagesJob.name)
                .map { it.serialized_params["arguments"].second }
  end

  def embedded_ids = embed_job_arguments.flatten

  def embed(work_package, **)
    create(:work_package_embedding, semantic_index:, work_package:, **)
  end

  it "claims a batch with the embed jobs of work packages without an embedding" do
    work_packages = create_list(:work_package, 2)

    job.perform(semantic_index.id)

    expect(semantic_index.reload.indexing_batch.properties).to include(semantic_index_id: semantic_index.id)
    expect(embedded_ids).to match_array(work_packages.map(&:id))
  end

  it "embeds the work packages in jobs of the batch size" do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    create_list(:work_package, 3)

    job.perform(semantic_index.id)

    expect(embed_job_arguments.map(&:size)).to contain_exactly(2, 1)
  end

  it "claims no batch when every embedding is up to date" do
    embed(create(:work_package))

    expect { job.perform(semantic_index.id) }.not_to change(GoodJob::BatchRecord, :count)
    expect(semantic_index.reload.indexing_batch_id).to be_nil
  end

  it "claims no batch when only other attributes than the text changed" do
    work_package = create(:work_package)
    embed(work_package)
    work_package.update!(estimated_hours: 3, updated_at: 1.minute.from_now)

    expect { job.perform(semantic_index.id) }.not_to change(GoodJob::BatchRecord, :count)
  end

  it "ignores the embeddings of other Semantic Indexes" do
    work_package = create(:work_package)
    create(:work_package_embedding, semantic_index: create(:semantic_index), work_package:)

    job.perform(semantic_index.id)

    expect(embedded_ids).to eq([work_package.id])
  end

  context "without a connection" do
    before do
      allow(LlmConnection).to receive(:available?).and_return(false)
      create(:work_package)
    end

    it "records the error and claims no batch" do
      expect { job.perform(semantic_index.id) }.not_to change(GoodJob::BatchRecord, :count)
      expect(semantic_index.reload.error_message).to eq(I18n.t("admin.semantic_indexes.indexing.not_ready.no_connection"))
    end
  end

  it "records the error when the connection no longer offers the model" do
    semantic_index.update!(model_id: "no-longer-offered")
    create(:work_package)

    expect { job.perform(semantic_index.id) }.not_to change(GoodJob::BatchRecord, :count)
    expect(semantic_index.reload.error_message)
      .to eq(I18n.t("admin.semantic_indexes.indexing.not_ready.model_missing", model: "no-longer-offered"))
  end

  it "clears a previous error once the prerequisites are met" do
    semantic_index.update!(error_message: "boom")

    job.perform(semantic_index.id)

    expect(semantic_index.reload.error_message).to be_nil
  end

  it "does nothing for an unknown semantic index" do
    create(:work_package)

    expect { job.perform(-1) }.not_to change(GoodJob::BatchRecord, :count)
  end

  it "is enqueued only once per Semantic Index at a time" do
    2.times { described_class.perform_later(semantic_index.id) }
    described_class.perform_later(create(:semantic_index).id)

    expect(GoodJob::Job.where(job_class: described_class.name).count).to eq(2)
  end

  it "skips the run while the claimed batch is still running" do
    indexing_index = create(:semantic_index, :indexing)
    create(:work_package)

    expect { job.perform(indexing_index.id) }.not_to change { indexing_index.reload.indexing_batch_id }
  end

  it "does nothing with the feature flag off", with_flag: { semantic_search: false } do
    create(:work_package)

    expect { job.perform(semantic_index.id) }.not_to change(GoodJob::BatchRecord, :count)
  end

  context "when run by cron without a Semantic Index" do
    let!(:active_index) do
      create(:semantic_index).tap do |index|
        create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search", semantic_index: index)
      end
    end

    it "syncs the active Semantic Index" do
      work_package = create(:work_package)

      job.perform

      expect(GoodJob::Job.where(batch_id: active_index.reload.indexing_batch_id)
                         .flat_map { it.serialized_params["arguments"].second }).to eq([work_package.id])
    end

    it "does nothing without an active Semantic Index" do
      active_index.llm_feature_bindings.destroy_all
      create(:work_package)

      expect { job.perform }.not_to change(GoodJob::BatchRecord, :count)
    end

    it "shares the concurrency key of a run started for the active Semantic Index" do
      described_class.perform_later(active_index.id)
      described_class.perform_later

      expect(GoodJob::Job.where(job_class: described_class.name).count).to eq(1)
    end

    context "with a work package that cannot be embedded" do
      let!(:failing) { create(:work_package, subject: "Rejected") }
      let!(:healthy) { create(:work_package, subject: "Accepted") }
      let(:session) { instance_double(Llm::Session) }
      let(:rejecting) { true }
      let(:rejection) { Llm::Errors.translate(RubyLLM::BadRequestError.new(instance_double(Faraday::Env, status: 400), "invalid input")) }

      before do
        allow(Llm::Session).to receive(:for).and_return(session)
        allow(session).to receive(:embed) do |texts, **|
          raise rejection if rejecting && texts.any? { it.include?("Rejected") }

          instance_double(RubyLLM::Embedding, vectors: texts.map { [0.1, 0.2, 0.3] })
        end
      end

      def tick
        described_class.perform_now
        GoodJob.perform_inline
        active_index.reload
      end

      def embedded_work_package_ids
        WorkPackageEmbedding.where(semantic_index: active_index).where.not(embedding: nil).pluck(:work_package_id)
      end

      shared_examples "records it until its text changes" do
        it "embeds the others and does not try it again until its text changes" do
          tick

          expect(embedded_work_package_ids).to eq([healthy.id])
          expect(active_index.status).to eq("ready")
          expect(Llm::IndexingProgress.new(active_index).failed_count).to eq(1)
          expect { tick }.not_to change(active_index, :indexing_batch_id)

          failing.update!(description: "Shorter", updated_at: 1.minute.from_now)
          allow(self).to receive(:rejecting).and_return(false)
          tick

          expect(embedded_work_package_ids).to contain_exactly(healthy.id, failing.id)
          expect(Llm::IndexingProgress.new(active_index).failed_count).to eq(0)
        end
      end

      it_behaves_like "records it until its text changes"

      context "when its text is too large" do
        let(:rejection) do
          Llm::Errors.translate(RubyLLM::ContextLengthExceededError.new(instance_double(Faraday::Env, status: 400),
                                                                        "maximum context length exceeded"))
        end

        it_behaves_like "records it until its text changes"
      end
    end

    context "when the server rejects the API key" do
      let!(:work_packages) { create_list(:work_package, 2) }
      let(:session) { instance_double(Llm::Session) }

      before do
        allow(Llm::Session).to receive(:for).and_return(session)
        allow(session).to receive(:embed).and_raise(Llm::Errors::AuthenticationError.new("rejected"))
      end

      it "fails the run and retries its work packages in the next one" do
        described_class.perform_now
        expect { GoodJob.perform_inline }.to raise_error(Llm::Errors::AuthenticationError)
        active_index.reload

        expect(active_index.error_message)
          .to eq(I18n.t("admin.semantic_indexes.indexing.run_failed", error: "rejected"))
        expect(Llm::IndexingProgress.new(active_index).failed_count).to eq(0)

        allow(session).to receive(:embed) do |texts, **|
          instance_double(RubyLLM::Embedding, vectors: texts.map { [0.1, 0.2, 0.3] })
        end
        described_class.perform_now
        GoodJob.perform_inline
        active_index.reload

        expect(WorkPackageEmbedding.where(semantic_index: active_index).pluck(:work_package_id))
          .to match_array(work_packages.map(&:id))
        expect(active_index.error_message).to be_nil
      end
    end
  end
end
