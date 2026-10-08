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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Label do
  describe "validations" do
    subject { build(:label) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to belong_to(:author).class_name("User") }

    it "is backed by a case-insensitive unique index" do
      existing = create(:label, name: "hello")
      duplicate = { name: "HELLO", author_id: existing.author_id, created_at: Time.current, updated_at: Time.current }

      expect { described_class.insert_all!([duplicate]) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "normalizations" do
    subject { build(:label) }

    it { is_expected.to normalize(:name).from("  Machine   Learning ").to("Machine Learning") }
  end

  describe ".with_usage_count" do
    it "counts the labelings of each label, including unused ones" do
      used = create(:label)
      unused = create(:label)
      create_list(:labeling, 2, label: used)

      counts = described_class.with_usage_count.index_by(&:id).transform_values(&:usage_count)

      expect(counts).to eq(used.id => 2, unused.id => 0)
    end

    it "keeps a scalar total when paginated" do
      create_list(:label, 2)
      create(:labeling, label: described_class.first)

      expect(described_class.with_usage_count.paginate(page: 1, per_page: 1).total_entries)
        .to eq(described_class.count)
    end
  end

  describe ".ordered_by_relevance_for" do
    let(:project) { create(:project) }
    let(:other_project) { create(:project) }

    let!(:popular_elsewhere) { create(:label, name: "popular elsewhere") }
    let!(:local_rare) { create(:label, name: "local rare") }
    let!(:local_common) { create(:label, name: "local common") }
    let!(:unused_a) { create(:label, name: "Unused A") }
    let!(:unused_b) { create(:label, name: "unused b") }

    before do
      label_work_packages(popular_elsewhere, other_project, count: 3)
      label_work_packages(local_rare, project, count: 1)
      label_work_packages(local_common, project, count: 2)
    end

    def label_work_packages(label, project, count:)
      create_list(:work_package, count, project:).each { create(:labeling, label:, labelable: it) }
    end

    it "lists labels used in the project first, then by usage, then case-insensitively by name" do
      expect(described_class.ordered_by_relevance_for(project).to_a)
        .to eq([local_common, local_rare, popular_elsewhere, unused_a, unused_b])
    end

    it "keeps a scalar total when paginated" do
      expect(described_class.ordered_by_relevance_for(project).paginate(page: 1, per_page: 2).total_entries)
        .to eq(5)
    end
  end

  describe ".page_of" do
    let!(:alpha) { create(:label, name: "Alpha") }
    let!(:bravo) { create(:label, name: "bravo") }
    let!(:charlie) { create(:label, name: "Charlie") }
    let!(:zulu) { create(:label, name: "Zulu") }

    it "returns the 1-based page the label falls on when ordered case-insensitively by name" do
      expect(described_class.page_of(alpha, per_page: 2)).to eq(1)
      expect(described_class.page_of(charlie, per_page: 2)).to eq(2)
      expect(described_class.page_of(zulu, per_page: 2)).to eq(2)
    end

    it "sorts case-insensitively, placing bravo between alpha and charlie" do
      expect(described_class.page_of(bravo, per_page: 1)).to eq(2)
    end
  end

  describe "#destroy" do
    it "removes its labelings" do
      label = create(:label)
      labeling = create(:labeling, label:)

      label.destroy!

      expect(Labeling.where(id: labeling.id)).not_to exist
    end
  end
end
