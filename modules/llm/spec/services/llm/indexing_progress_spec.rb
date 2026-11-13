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

RSpec.describe Llm::IndexingProgress do
  subject(:progress) { described_class.new(batch) }

  let(:semantic_index) { create(:semantic_index, state: "indexing") }
  let(:batch) { GoodJob::Batch.new(semantic_index_id: semantic_index.id).tap(&:save) }
  let(:work_package) { create(:work_package) }
  let(:other_work_package) { create(:work_package) }

  def embed_job(work_package_ids:, finished_at: nil, error: nil)
    GoodJob::Job.create!(id: SecureRandom.uuid, active_job_id: SecureRandom.uuid, batch_id: batch.id,
                         job_class: Llm::EmbedWorkPackagesJob.name, queue_name: "default",
                         serialized_params: { "arguments" => [semantic_index.id, work_package_ids] },
                         finished_at:, error:)
  end

  describe "#percentage" do
    it "is 0 without any embed jobs" do
      expect(progress.percentage).to eq(0)
    end

    it "reflects the share of indexed work packages" do
      embed_job(work_package_ids: [work_package.id], finished_at: Time.current)
      embed_job(work_package_ids: [other_work_package.id])
      embed_job(work_package_ids: [work_package.id])
      embed_job(work_package_ids: [other_work_package.id])

      expect(progress.percentage).to eq(25)
    end
  end

  describe "#failed_work_package_count" do
    it "is 0 when nothing failed" do
      embed_job(work_package_ids: [work_package.id], finished_at: Time.current)

      expect(progress.failed_work_package_count).to eq(0)
    end

    it "counts each failed embed job carrying a single work package id" do
      embed_job(work_package_ids: [work_package.id], finished_at: Time.current, error: "boom")
      embed_job(work_package_ids: [other_work_package.id], finished_at: Time.current, error: "boom")

      expect(progress.failed_work_package_count).to eq(2)
    end

    it "ignores unfinished jobs" do
      embed_job(work_package_ids: [work_package.id], error: "boom")

      expect(progress.failed_work_package_count).to eq(0)
    end

    it "ignores failed jobs carrying multiple work package ids" do
      embed_job(work_package_ids: [work_package.id, other_work_package.id],
                finished_at: Time.current, error: "boom")

      expect(progress.failed_work_package_count).to eq(0)
    end

    it "ignores jobs of other classes in the same batch" do
      GoodJob::Job.create!(id: SecureRandom.uuid, active_job_id: SecureRandom.uuid, batch_id: batch.id,
                           job_class: Llm::IndexWorkPackagesJob.name, queue_name: "default",
                           serialized_params: {}, finished_at: Time.current, error: "boom")

      expect(progress.failed_work_package_count).to eq(0)
    end
  end
end
