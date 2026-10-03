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

RSpec.describe Admin::CustomFields::Hierarchy::Item::ActionsComponent, type: :component, with_ee: [:custom_field_hierarchies] do
  let(:custom_field) { create(:hierarchy_wp_custom_field) }
  let(:item) do
    CustomFields::Hierarchy::HierarchicalItemService
      .new
      .insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract,
                   parent: custom_field.hierarchy_root,
                   label: "Only").value!
  end

  it "offers to set the default value when the item is not the default" do
    render_inline(described_class.new(item))

    expect(page).to have_link("Set as default value")
  end

  it "offers to clear the default value when the item is the default" do
    item.update!(default_value: true)

    render_inline(described_class.new(item))

    expect(page).to have_link("Clear default value")
  end

  describe "item action routes" do
    let(:custom_field_traits) { [:hierarchy] }
    let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
    let(:root) { custom_field.hierarchy_root }
    let(:item) do
      service
        .insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract, parent: root, label: "First")
        .value!
    end

    before do
      item
      service.insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract, parent: root, label: "Second")
      render_inline(described_class.new(item.reload))
    end

    for_each_context(*CustomFieldAdminAreas::CONTEXTS) do
      it "links every action into its own admin area" do
        expect(page).to have_link("Edit", href: "#{items_path}/#{item.id}/edit")
        expect(page).to have_link("Add item above", href: "#{items_path}/#{root.id}/new_child?position=0")
        expect(page).to have_link("Add item below", href: "#{items_path}/#{root.id}/new_child?position=1")
        expect(page).to have_link("Add sub-item", href: "#{items_path}/#{item.id}/new_child?position=0")
        expect(page).to have_link("Set as default value", href: "#{items_path}/#{item.id}/set_default")
        expect(page).to have_link("Change parent", href: "#{items_path}/#{item.id}/change_parent")
        expect(page).to have_css("form[action='#{items_path}/#{item.id}/move']", text: "Move down")
        expect(page).to have_link("Delete", href: "#{items_path}/#{item.id}/delete")
      end
    end
  end
end
