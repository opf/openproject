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

RSpec.describe CustomFields::Hierarchy::UpdateListItemContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let!(:vader) { create(:hierarchy_item) }
    let!(:luke) { create(:hierarchy_item, label: "luke", short: "ls", parent: vader) }
    let!(:leia) { create(:hierarchy_item, label: "leia", short: "lo", parent: vader) }
    let!(:starkiller) { create(:hierarchy_item, label: "starkiller", parent: vader) }

    context "when all required fields are valid" do
      it "is valid" do
        [
          { item: luke, label: "Luke Skywalker", short: "LS" },
          { item: luke, label: "Luke Skywalker", short: nil },
          { item: luke, label: "luke", short: "lu" }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when item is a root item" do
      let(:params) { { item: vader } }

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
      let(:item) { build(:hierarchy_item, parent: vader) }
      let(:params) { { item: } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors[:item]).to match_array("must be an already existing item.")
      end
    end

    context "when the label already exist in the same hierarchy level" do
      let(:params) { { item: luke, label: "leia" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure

        expect(result.errors[:label]).to match_array("must be unique within the same hierarchy level.")
      end
    end

    context "when the short already exist in the same hierarchy level" do
      let(:params) { { item: luke, short: "lo" } }

      it "is invalid" do
        result = subject.call(params)

        expect(result).to be_failure

        expect(result.errors[:short]).to match_array("must be unique within the same hierarchy level.")
      end
    end

    context "when fields are invalid" do
      it "is invalid" do
        [
          {},
          { item: nil },
          { item: luke, label: nil, short: "lu" },
          { item: luke, label: 42, short: "lu" },
          { item: luke, label: "LUKE", short: 42 },
          { item: luke, short: nil },
          { item: luke, label: "LUKE" },
          { item: luke, short: "lu" }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end

    context "when the custom field is a list" do
      let(:custom_field) { create(:list_wp_custom_field) }
      let(:root) { custom_field.hierarchy_root }
      let(:child) do
        CustomFields::Hierarchy::HierarchicalItemService
          .new
          .insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract, parent: root, label: "Top")
          .value!
      end
      let(:grandchild) { child.children.create!(label: "Nested") }

      it "accepts an item directly under the root" do
        result = subject.call(item: child, label: "Renamed", short: nil)

        expect(result).to be_success
      end

      it "rejects an item nested under another item" do
        result = subject.call(item: grandchild, label: "Renamed", short: nil)

        expect(result).to be_failure
        expect(result.errors.to_h[:item]).to include("cannot have sub-items for this custom field.")
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
