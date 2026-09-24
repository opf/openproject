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

RSpec.describe CustomFields::Hierarchy::HierarchicalItemFormatter,
               with_ee: %i[custom_field_hierarchies weighted_item_lists] do
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }

  # rubocop:disable Layout/LineLength
  let(:hierarchy_custom_field) { create(:custom_field, :hierarchy, name: "Galactic Location") }
  let(:hierarchy_contract) { CustomFields::Hierarchy::InsertHierarchyItemContract }
  let(:hierarchy_root) { hierarchy_custom_field.hierarchy_root }
  let(:milky_way) { service.insert_item(contract_class: hierarchy_contract, parent: hierarchy_root, label: "Milky Way").value! }
  let(:sol) { service.insert_item(contract_class: hierarchy_contract, parent: milky_way, label: "Sol").value! }
  let(:earth) { service.insert_item(contract_class: hierarchy_contract, parent: sol, label: "Earth", short: "T").value! }
  let(:mars) { service.insert_item(contract_class: hierarchy_contract, parent: sol, label: "Mars", short: "M").value! }
  let(:saturn) { service.insert_item(contract_class: hierarchy_contract, parent: sol, label: "Saturn", short: "Sn").value! }
  let(:luna) { service.insert_item(contract_class: hierarchy_contract, parent: earth, label: "Luna", short: "Ln").value! }

  let(:wil_custom_field) { create(:custom_field, :weighted_item_list, name: "Wave length (m)") }
  let(:wil_contract) { CustomFields::Hierarchy::InsertWeightedItemContract }
  let(:wil_root) { wil_custom_field.hierarchy_root }
  let(:light) { service.insert_item(contract_class: wil_contract, parent: wil_root, label: "Light", weight: 5e-7).value! }
  let(:red) { service.insert_item(contract_class: wil_contract, parent: light, label: "Red", weight: 7e-7).value! }
  let(:violet) { service.insert_item(contract_class: wil_contract, parent: light, label: "Violet", weight: 4e-7).value! }
  let(:x_ray) { service.insert_item(contract_class: wil_contract, parent: wil_root, label: "X-Ray", weight: 1e-11).value! }
  let(:microwave) { service.insert_item(contract_class: wil_contract, parent: wil_root, label: "Micro waves", weight: 0.01).value! }
  let(:radio) { service.insert_item(contract_class: wil_contract, parent: wil_root, label: "Radio waves", weight: 10).value! }
  let(:vlf) { service.insert_item(contract_class: wil_contract, parent: radio, label: "VLF", weight: 100000).value! }
  # rubocop:enable Layout/LineLength

  context "with default formatting options" do
    subject(:formatter) { described_class.default }

    it "renders an item without ancestors, but with label and suffix" do
      expect(formatter.format(item: earth)).to eq("Earth (T)")
      expect(formatter.format(item: sol)).to eq("Sol")
      expect(formatter.format(item: x_ray)).to eq("X-Ray (1.0e-11)")
    end
  end

  context "with formatting the path" do
    subject(:formatter) { described_class.new(path: true, suffix: false) }

    it "renders an item with ancestor path" do
      expect(formatter.format(item: luna)).to eq("Milky Way / Sol / Earth / Luna")
      expect(formatter.format(item: vlf)).to eq("Radio waves / VLF")
    end
  end

  context "with specific number formatting" do
    subject(:formatter) { described_class.new(number_length_limit: 12, number_precision: 12) }

    it "renders an item with weight with custom precision" do
      expect(formatter.format(item: x_ray)).to eq("X-Ray (0.00000000001)")
    end
  end

  context "with only the suffix without parentheses" do
    subject(:formatter) { described_class.new(label: false, suffix_parentheses: false) }

    it "renders an item with weight without parentheses" do
      expect(formatter.format(item: x_ray)).to eq("1.0e-11")
      expect(formatter.format(item: luna)).to eq("Ln")
    end
  end
end
