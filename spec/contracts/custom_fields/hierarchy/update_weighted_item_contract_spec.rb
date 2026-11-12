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

RSpec.describe CustomFields::Hierarchy::UpdateWeightedItemContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let!(:impact) { create(:hierarchy_item) }
    let!(:high) { create(:hierarchy_item, label: "HIGH", weight: 1.17e-12, parent: impact) }
    let!(:middle) { create(:hierarchy_item, label: "Middle", weight: 1, parent: impact) }
    let!(:low) { create(:hierarchy_item, label: "low", weight: 9.81e6, parent: impact) }

    context "when all required fields are valid" do
      it "is valid" do
        [
          { item: high, label: "VERY HIGH", weight: 1.17e-12 },
          { item: high, label: "HIGH", weight: 1.17e-11 }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when item is a root item" do
      let(:params) { { item: impact } }

      it("is invalid") do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(item: ["cannot be a root item."])
      end
    end

    context "when item is not of type 'Item'" do
      let(:invalid_item) { create(:custom_field) }
      let(:params) { { item: invalid_item } }

      it("is invalid") do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(item: ["must be CustomField::Hierarchy::Item."])
      end
    end

    context "when item is not persisted" do
      let(:item) { build(:hierarchy_item, parent: impact) }
      let(:params) { { item: } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors[:item]).to match_array("must be an already existing item.")
      end
    end

    context "when the label already exist in the same hierarchy level" do
      let(:params) { { item: high, label: "Middle" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure

        expect(result.errors[:label]).to match_array("must be unique within the same hierarchy level.")
      end
    end

    context "when fields are invalid" do
      it "is invalid" do
        [
          {},
          { item: nil },
          { item: high, label: 42 },
          { item: high, weight: "pi" },
          { item: high, label: nil, weight: 4 },
          { item: high, label: "pi", weight: nil },
          { item: high, label: "pi", weight: "threepointonefour" },
          { item: high, label: 42, weight: 4 },
          { item: high, label: "", weight: 4 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
