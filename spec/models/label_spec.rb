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

  describe "name normalization" do
    it "strips surrounding whitespace and collapses repeated internal whitespace" do
      label = build(:label, name: "  Machine   Learning ")

      expect(label.name).to eq("Machine Learning")
    end

    it "normalizes the name used in a query" do
      create(:label, name: "Machine Learning")

      expect(described_class.find_by(name: "  Machine   Learning ")).to be_present
    end
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

  describe "#destroy" do
    it "removes its labelings" do
      label = create(:label)
      labeling = create(:labeling, label:)

      label.destroy!

      expect(Labeling.where(id: labeling.id)).not_to exist
    end
  end
end
