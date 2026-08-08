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

require "rails_helper"

RSpec.describe OpPrimer::SortableLists do
  describe "#{described_class}::List" do
    it "emits the list controller and values" do
      list = described_class::List.new(type: "custom_field", id: 42, name: "General")

      expect(list.to_data).to eq(
        controller: "sortable-lists--list",
        sortable_lists__list_type_value: "custom_field",
        sortable_lists__list_accepted_type_value: "custom_field",
        sortable_lists__list_id_value: 42,
        sortable_lists__list_name_value: "General"
      )
    end

    it "omits nil-valued fields so Stimulus defaults stay in charge" do
      list = described_class::List.new(type: "work_package", drop_position: "start")

      expect(list.to_data).to eq(
        controller: "sortable-lists--list",
        sortable_lists__list_type_value: "work_package",
        sortable_lists__list_accepted_type_value: "work_package",
        sortable_lists__list_drop_position_value: "start"
      )
    end

    it "keeps an explicit accepted_type" do
      list = described_class::List.new(type: "custom_field", accepted_type: "attribute")

      expect(list.to_data[:sortable_lists__list_accepted_type_value]).to eq("attribute")
    end

    it "derives id and name from a record but never the type" do
      section = Struct.new(:id, :name).new(7, "Marketing")
      list = described_class::List.for(section, type: "section")

      expect(list.id).to eq(7)
      expect(list.name).to eq("Marketing")
      expect(list.type).to eq("section")
      expect { described_class::List.for(section) }.to raise_error(ArgumentError)
    end

    it "rejects unknown keys" do
      expect { described_class::List.new(type: "x", externalHref: "nope") }
        .to raise_error(ArgumentError, /externalHref/)
    end

    it "returns frozen instances" do
      expect(described_class::List.new(type: "x")).to be_frozen
      expect(described_class::Item.new(id: 1, type: "x")).to be_frozen
    end
  end

  describe "#{described_class}::Item" do
    it "emits the item controller, values, and token-joined targets" do
      item = described_class::Item.new(id: 5, type: "custom_field", label: "Phone", targets: %w[moveMenu preview])

      expect(item.to_data).to eq(
        controller: "sortable-lists--item",
        sortable_lists__item_id_value: 5,
        sortable_lists__item_type_value: "custom_field",
        sortable_lists__item_label_value: "Phone",
        sortable_lists__item_target: "moveMenu preview"
      )
    end

    it "merges and deduplicates role-added targets" do
      item = described_class::Item.new(id: 1, type: "section", targets: %w[moveMenu preview])

      expect(item.with_targets("preview").to_data[:sortable_lists__item_target]).to eq("moveMenu preview")
    end

    it "emits a meaningful false for hide_unavailable" do
      item = described_class::Item.new(id: 1, type: "x", hide_unavailable: false)

      expect(item.to_data[:sortable_lists__item_hide_unavailable_value]).to be(false)
    end

    it "requires id and type" do
      expect { described_class::Item.new(type: "x") }.to raise_error(ArgumentError)
      expect { described_class::Item.new(id: 1) }.to raise_error(ArgumentError)
    end

    it "derives id and label from a record but never the type" do
      cf = Struct.new(:id, :name).new(3, "Phone")
      item = described_class::Item.for(cf, type: "custom_field")

      expect(item.id).to eq(3)
      expect(item.label).to eq("Phone")
      expect { described_class::Item.for(cf) }.to raise_error(ArgumentError)
    end

    it "exposes targets as an insertion-ordered set" do
      item = described_class::Item.new(id: 1, type: "x", targets: %w[moveMenu preview moveMenu])

      expect(item.targets).to be_a(Set)
      expect(item.targets.to_a).to eq(%w[moveMenu preview])
    end
  end
end
