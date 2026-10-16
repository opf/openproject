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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Llm::IndexWorkPackagesJob,
               with_flag: { semantic_search: true },
               with_good_job_batches: [Llm::IndexWorkPackagesJob, Llm::EmbedWorkPackagesJob] do
  describe ".enqueue_batch" do
    it "enqueues the job inside a index batch" do
      batch = described_class.enqueue_batch

      expect(batch.description).to eq(described_class::BATCH_DESCRIPTION)
      expect(GoodJob::Job.where(batch_id: batch.id).pluck(:job_class)).to eq([described_class.name])
    end
  end

  describe ".running?" do
    it "is false without a batch" do
      expect(described_class).not_to be_running
    end

    it "is true while the latest batch is unfinished" do
      GoodJob::BatchRecord.create!(description: described_class::BATCH_DESCRIPTION, finished_at: 1.hour.ago)
      GoodJob::BatchRecord.create!(description: described_class::BATCH_DESCRIPTION)

      expect(described_class).to be_running
    end

    it "is false once the latest batch has finished" do
      GoodJob::BatchRecord.create!(description: described_class::BATCH_DESCRIPTION, finished_at: Time.current)

      expect(described_class).not_to be_running
    end
  end

  describe "#perform" do
    let!(:work_packages) { create_list(:work_package, 2) }
    let(:batch) { GoodJob::Batch.new(description: described_class::BATCH_DESCRIPTION) }
    let(:job) { described_class.new }

    before { allow(job).to receive(:batch).and_return(batch) }

    def embed_jobs
      GoodJob::Job.where(batch_id: batch.id, job_class: Llm::EmbedWorkPackagesJob.name)
    end

    it "adds an embedding job for the work packages to its batch" do
      job.perform

      expect(embed_jobs.map { it.serialized_params["arguments"].first })
        .to contain_exactly(match_array(work_packages.map(&:id)))
    end

    it "does nothing with the feature flag off", with_flag: { semantic_search: false } do
      job.perform

      expect(embed_jobs).to be_empty
    end
  end
end
