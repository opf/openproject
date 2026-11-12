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

RSpec.describe Llm::FinishSemanticIndexingJob do
  let(:semantic_index) { create(:semantic_index, state: "indexing") }
  let(:batch) { GoodJob::Batch.new(semantic_index_id: semantic_index.id).tap(&:save) }

  def embed_job(finished_at: Time.current, error: nil)
    GoodJob::Job.create!(id: SecureRandom.uuid, active_job_id: SecureRandom.uuid, batch_id: batch.id,
                         job_class: Llm::EmbedWorkPackagesJob.name, queue_name: "default",
                         serialized_params: {}, finished_at:, error:)
  end

  it "marks the Semantic Index ready when every request succeeded" do
    embed_job

    described_class.perform_now(batch, { event: :finish })

    expect(semantic_index.reload).to be_ready
  end

  it "marks the Semantic Index failed with the number of failed requests" do
    embed_job
    embed_job(error: "Llm::Errors::ApiError: boom")

    described_class.perform_now(batch, { event: :finish })

    expect(semantic_index.reload).to have_attributes(state: "failed", error_message: "1 request failed.")
  end

  it "leaves a Semantic Index alone that is no longer indexing" do
    semantic_index.update!(state: "ready")

    described_class.perform_now(batch, { event: :finish })

    expect(semantic_index.reload).to be_ready
  end
end
