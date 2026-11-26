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

RSpec.describe Llm::WorkPackages::IndexCandidates do
  let(:semantic_index) { create(:semantic_index) }
  let(:work_package) { create(:work_package) }

  subject(:candidates) { described_class.new(semantic_index) }

  def embed(work_package, **)
    create(:work_package_embedding, semantic_index:, work_package:, **)
  end

  def update_text = work_package.update!(description: "New description", updated_at: 1.minute.from_now)

  def update_other_attribute = work_package.update!(estimated_hours: 3, updated_at: 1.minute.from_now)

  describe "#work_packages" do
    it "contains work packages without an embedding" do
      expect(candidates.work_packages).to contain_exactly(work_package)
    end

    it "skips work packages whose embedding is up to date" do
      embed(work_package)

      expect(candidates.work_packages).to be_empty
    end

    it "contains work packages updated after they were embedded" do
      embed(work_package)
      update_other_attribute

      expect(candidates.work_packages).to contain_exactly(work_package)
    end

    it "ignores the embeddings of other Semantic Indexes" do
      create(:work_package_embedding, semantic_index: create(:semantic_index), work_package:)

      expect(candidates.work_packages).to contain_exactly(work_package)
    end
  end

  describe "#skip_unchanged_text!" do
    it "advances an embedding whose text did not change" do
      embedding = embed(work_package)
      update_other_attribute

      candidates.skip_unchanged_text!

      expect(candidates.work_packages).to be_empty
      expect(embedding.reload.work_package_updated_at).to eq(work_package.reload.updated_at)
    end

    it "keeps an embedding whose text changed" do
      embed(work_package)
      update_text

      candidates.skip_unchanged_text!

      expect(candidates.work_packages).to contain_exactly(work_package)
    end

    it "keeps an embedding without a text digest" do
      embed(work_package, text_digest: nil)
      update_other_attribute

      candidates.skip_unchanged_text!

      expect(candidates.work_packages).to contain_exactly(work_package)
    end

    it "leaves the embeddings of other Semantic Indexes alone" do
      other = create(:work_package_embedding, semantic_index: create(:semantic_index), work_package:)
      update_other_attribute

      expect { candidates.skip_unchanged_text! }.not_to change { other.reload.work_package_updated_at }
    end

    context "with a work package too large to be embedded" do
      before { embed(work_package, embedding: nil, failed_at: Time.current) }

      it "skips it while its text is unchanged" do
        update_other_attribute

        candidates.skip_unchanged_text!

        expect(candidates.work_packages).to be_empty
      end

      it "tries it again once its text changed" do
        update_text

        candidates.skip_unchanged_text!

        expect(candidates.work_packages).to contain_exactly(work_package)
      end
    end
  end
end
