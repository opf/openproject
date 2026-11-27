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
  subject(:progress) { described_class.new(semantic_index) }

  let(:semantic_index) { create(:semantic_index, :indexing) }

  it "splits the work packages into indexed, pending and failed ones" do
    create(:work_package_embedding, semantic_index:)
    create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current)
    create(:work_package_embedding, semantic_index:, work_package_updated_at: 1.day.ago)
    create(:work_package)

    expect(progress).to have_attributes(total_count: 4, indexed_count: 1, failed_count: 1, pending_count: 2)
  end

  it "counts a failed work package as failed although its text changed since" do
    create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current,
                                    work_package_updated_at: 1.day.ago)

    expect(progress).to have_attributes(failed_count: 1, pending_count: 0)
  end

  it "ignores embeddings of other indexes" do
    create(:work_package_embedding)
    create(:work_package_embedding, embedding: nil, failed_at: Time.current)

    expect(progress).to have_attributes(total_count: 2, indexed_count: 0, pending_count: 2, failed_count: 0)
  end

  it "counts indexed and failed work packages as done" do
    create(:work_package_embedding, semantic_index:)
    create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current)
    create(:work_package)

    expect(progress.done_count).to eq(2)
  end

  describe "#percentage" do
    it "is the share of all work packages, rounded down" do
      create_list(:work_package, 3)

      expect(progress.percentage(2)).to eq(66)
    end

    it "is 0 without work packages" do
      expect(progress.percentage(0)).to eq(0)
    end
  end
end
