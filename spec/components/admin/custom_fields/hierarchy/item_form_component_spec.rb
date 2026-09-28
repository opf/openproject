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

RSpec.describe Admin::CustomFields::Hierarchy::ItemFormComponent, type: :component do
  describe "form action" do
    let(:custom_field_traits) { [:list, { possible_values: %w[Only Other] }] }
    let(:root) { custom_field.hierarchy_root }

    subject(:form_action) { render_inline(described_class.new(item)).at_css("form")["action"] }

    for_each_context(*CustomFieldAdminAreas::CONTEXTS) do
      context "for a new item" do
        let(:item) { root.children.build(label: "Stormtroopers", sort_order: 2) }

        it("creates it within its own admin area") { is_expected.to eq("#{items_path}/#{root.id}/new_child?position=2") }
      end

      context "for an existing item" do
        let(:item) { root.children.first }

        it("updates it within its own admin area") { is_expected.to eq("#{items_path}/#{item.id}") }
      end
    end
  end

  describe "cancel link" do
    let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Only Other]) }

    it "replaces the whole items frame, which the items page response contains" do
      render_inline(described_class.new(custom_field.hierarchy_root.children.build(label: "Stormtroopers")))

      expect(page).to have_css("a[data-turbo-frame='admin-custom-fields-hierarchy-items-component']", text: "Cancel")
    end
  end

  describe "secondary input" do
    let(:item) { custom_field.hierarchy_root.children.build(label: "Stormtroopers") }

    subject(:rendered_component) { render_inline(described_class.new(item)) }

    context "for a hierarchy field", with_ee: [:custom_field_hierarchies] do
      let(:custom_field) { create(:hierarchy_wp_custom_field) }

      it("asks for a short name") { is_expected.to have_field("Short name") }
      it("does not ask for a weight") { is_expected.to have_no_field("Weight") }
    end

    context "for a weighted item list field", with_ee: [:weighted_item_lists] do
      let(:custom_field) { create(:weighted_item_list_wp_custom_field) }

      it("asks for a weight") { is_expected.to have_field("Weight") }
      it("does not ask for a short name") { is_expected.to have_no_field("Short name") }
    end

    context "for a list field" do
      let(:custom_field) { create(:list_wp_custom_field) }

      it("asks for the label only") do
        expect(rendered_component).to have_field("Item label")
        expect(rendered_component).to have_no_field("Short name")
        expect(rendered_component).to have_no_field("Weight")
      end
    end
  end
end
