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

RSpec.describe SemanticIndexes::StopIndexingService, with_good_job_batches: [Llm::IndexWorkPackagesJob] do
  include_context "with an embedding model offered"

  let(:semantic_index) { create(:semantic_index, state: "indexing") }
  let(:user) { build_stubbed(:admin) }

  subject(:result) { described_class.new(user:, model: semantic_index).call }

  context "with queued jobs in the indexing batch" do
    let(:batch) { Llm::IndexWorkPackagesJob.enqueue_for(semantic_index) }

    before { semantic_index.update!(indexing_batch_id: batch.id) }

    def batch_jobs = GoodJob::Job.where(batch_id: batch.id)

    it "stops indexing and discards the queued jobs" do
      expect(batch_jobs).not_to be_empty

      expect(result).to be_success
      expect(semantic_index.reload).to be_not_indexed
      expect(batch_jobs.reload.map(&:status)).to all(eq(:discarded))
    end
  end

  context "when the Semantic Index is not indexing" do
    let(:semantic_index) { create(:semantic_index, state: "ready") }

    it "fails without changing the state" do
      expect(result).to be_failure
      expect(result.message).to eq(I18n.t("admin.semantic_indexes.stop_indexing.not_indexing"))
      expect(semantic_index.reload).to be_ready
    end
  end

  context "as a regular user" do
    let(:user) { build_stubbed(:user) }

    it "fails without changing the state" do
      expect(result).to be_failure
      expect(semantic_index.reload).to be_indexing
    end
  end
end
