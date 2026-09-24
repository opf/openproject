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

RSpec.describe CustomFields::LegacyOptionIdResolver, with_ee: [:custom_field_hierarchies] do
  let(:custom_field) { create(:list_wp_custom_field) }
  let(:root) { custom_field.hierarchy_root }
  let(:item) do
    CustomFields::Hierarchy::HierarchicalItemService
      .new
      .insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract, parent: root, label: "Kept").value!
  end

  before do
    CustomField::LegacyOptionMapping.create!(custom_option_id: 7, hierarchical_item_id: item.id, custom_field_id: custom_field.id)
  end

  it "translates a mapped legacy id" do
    expect(described_class.resolve(custom_field:, id: "7")).to eq(item.id.to_s)
  end

  it "leaves an unmapped id alone" do
    expect(described_class.resolve(custom_field:, id: "999")).to eq("999")
  end

  it "leaves an id alone when it is mapped for a different custom field" do
    other = create(:list_wp_custom_field)

    expect(described_class.resolve(custom_field: other, id: "7")).to eq("7")
  end

  it "leaves ids alone for a field that is not a list" do
    hierarchy_field = create(:hierarchy_wp_custom_field)

    expect(described_class.resolve(custom_field: hierarchy_field, id: "7")).to eq("7")
  end

  it "translates a batch in one query, preserving order and unmapped entries" do
    expect(described_class.resolve_all(custom_field:, ids: %w[999 7])).to eq(["999", item.id.to_s])
  end
end
