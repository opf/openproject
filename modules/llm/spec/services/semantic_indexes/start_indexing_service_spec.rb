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

RSpec.describe SemanticIndexes::StartIndexingService, with_good_job_batches: [Llm::IndexWorkPackagesJob] do
  include_context "with an embedding model offered"

  let(:semantic_index) { create(:semantic_index) }
  let(:user) { build_stubbed(:admin) }

  subject(:result) { described_class.new(user:, model: semantic_index).call }

  def index_jobs = GoodJob::Job.where(job_class: Llm::IndexWorkPackagesJob.name)

  it "starts indexing in a batch it remembers" do
    expect(result).to be_success
    expect(semantic_index.reload).to be_indexing
    expect(index_jobs.pluck(:batch_id)).to eq([semantic_index.indexing_batch_id])
  end

  context "when the Semantic Index is already indexing" do
    let(:semantic_index) { create(:semantic_index, state: "indexing") }

    it "fails without enqueuing" do
      expect(result).to be_failure
      expect(index_jobs).to be_empty
    end
  end

  context "as a regular user" do
    let(:user) { build_stubbed(:user) }

    it "fails without changing the state" do
      expect(result).to be_failure
      expect(semantic_index.reload).to be_not_indexed
    end
  end
end
