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
  let(:semantic_index) { create(:semantic_index, state: "indexing") }

  describe ".enqueue_for" do
    it "enqueues the job inside a batch that finishes the Semantic Index" do
      batch = described_class.enqueue_for(semantic_index)

      expect(batch.properties).to include(semantic_index_id: semantic_index.id)
      expect(batch.on_finish).to eq(Llm::FinishSemanticIndexingJob.name)
      expect(GoodJob::Job.where(batch_id: batch.id).pluck(:job_class)).to eq([described_class.name])
    end
  end

  describe "#perform" do
    include_context "with an embedding model offered"

    let!(:work_packages) { create_list(:work_package, 2) }
    let(:batch) { GoodJob::Batch.new }
    let(:job) { described_class.new }

    before { allow(job).to receive(:batch).and_return(batch) }

    def embed_jobs
      GoodJob::Job.where(batch_id: batch.id, job_class: Llm::EmbedWorkPackagesJob.name)
    end

    it "adds an embedding job for the work packages of the Semantic Index to its batch" do
      job.perform(semantic_index.id)

      expect(embed_jobs.map { it.serialized_params["arguments"] })
        .to contain_exactly([semantic_index.id, match_array(work_packages.map(&:id))])
    end

    it "fails the Semantic Index and enqueues nothing without a connection" do
      connection.destroy!

      job.perform(semantic_index.id)

      expect(embed_jobs).to be_empty
      expect(semantic_index.reload)
        .to have_attributes(state: "failed",
                            error_message: I18n.t("admin.semantic_indexes.indexing.not_ready.no_connection"))
    end

    it "fails the Semantic Index when the connection no longer offers its model" do
      semantic_index.update!(model_id: "no-longer-offered")

      job.perform(semantic_index.id)

      expect(embed_jobs).to be_empty
      expect(semantic_index.reload)
        .to have_attributes(state: "failed",
                            error_message: I18n.t("admin.semantic_indexes.indexing.not_ready.model_missing",
                                                  model: "no-longer-offered"))
    end

    it "does nothing with the feature flag off", with_flag: { semantic_search: false } do
      job.perform(semantic_index.id)

      expect(embed_jobs).to be_empty
      expect(semantic_index.reload).to be_indexing
    end
  end
end
