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

RSpec.describe API::V3::CustomFields::Hierarchy::HierarchyItemRepresenter, "rendering", with_ee: [:custom_field_hierarchies] do
  include API::V3::Utilities::PathHelper

  let(:custom_field) { create(:custom_field, field_format: "hierarchy") }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let(:root) { custom_field.hierarchy_root }
  let(:contract_class) { CustomFields::Hierarchy::InsertHierarchyItemContract }
  let!(:luke) { service.insert_item(contract_class:, parent: root, label: "Luke", short: "LS").value! }
  let!(:r2d2) { service.insert_item(contract_class:, parent: luke, label: "R2-D2", short: "R2").value! }
  let!(:mouse) { service.insert_item(contract_class:, parent: r2d2, label: "Mouse Droid", short: "MD").value! }
  let!(:c3po) { service.insert_item(contract_class:, parent: luke, label: "C-3PO", short: "3PO").value! }
  let!(:mara) { service.insert_item(contract_class:, parent: root, label: "Mara", short: "MJ").value! }
  let(:user) { build_stubbed(:user) }
  let(:representer) { described_class.new(item, current_user: user) }

  subject(:generated) { representer.to_json }

  context "if item is root" do
    let(:item) { build_aggregate(item: root, depth: 0) }

    describe "_links" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.custom_field_item(item.id) }
      end

      it_behaves_like "has no link" do
        let(:link) { "parent" }
      end

      it_behaves_like "has a link collection" do
        let(:link) { "children" }
        let(:hrefs) do
          [
            {
              href: api_v3_paths.custom_field_item(luke.id),
              title: luke.label
            },
            {
              href: api_v3_paths.custom_field_item(mara.id),
              title: mara.label
            }
          ]
        end
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "branch" }
        let(:href) { api_v3_paths.custom_field_item_branch(item.id) }
      end
    end

    describe "properties" do
      it_behaves_like "property", :_type do
        let(:value) { "HierarchyItem" }
      end

      it_behaves_like "property", :id do
        let(:value) { item.id }
      end

      it_behaves_like "property", :label do
        let(:value) { nil }
      end

      it_behaves_like "property", :short do
        let(:value) { nil }
      end

      it_behaves_like "property", :depth do
        let(:value) { 0 }
      end
    end

    context "and depth is negative" do
      let(:item) { build_aggregate(item: root, depth: -1) }

      describe "properties" do
        it_behaves_like "property", :depth do
          let(:value) { nil }
        end
      end
    end
  end

  context "if item is leave" do
    let(:item) { build_aggregate(item: mouse, depth: mouse.depth) }

    describe "_links" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.custom_field_item(item.id) }
        let(:title) { "#{item.label} (#{item.short})" }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "parent" }
        let(:href) { api_v3_paths.custom_field_item(r2d2.id) }
        let(:title) { r2d2.label }
      end

      it_behaves_like "has a link collection" do
        let(:link) { "children" }
        let(:hrefs) { [] }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "branch" }
        let(:href) { api_v3_paths.custom_field_item_branch(item.id) }
      end
    end

    describe "properties" do
      it_behaves_like "property", :_type do
        let(:value) { "HierarchyItem" }
      end

      it_behaves_like "property", :id do
        let(:value) { item.id }
      end

      it_behaves_like "property", :label do
        let(:value) { item.label }
      end

      it_behaves_like "property", :short do
        let(:value) { item.short }
      end

      it_behaves_like "property", :depth do
        let(:value) { item.depth }
      end
    end
  end

  context "if item is intermediate" do
    let(:item) { build_aggregate(item: r2d2, depth: r2d2.depth) }

    describe "_links" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.custom_field_item(item.id) }
        let(:title) { "#{item.label} (#{item.short})" }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "parent" }
        let(:href) { api_v3_paths.custom_field_item(luke.id) }
        let(:title) { luke.label }
      end

      it_behaves_like "has a link collection" do
        let(:link) { "children" }
        let(:hrefs) do
          [
            {
              href: api_v3_paths.custom_field_item(mouse.id),
              title: mouse.label
            }
          ]
        end
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "branch" }
        let(:href) { api_v3_paths.custom_field_item_branch(item.id) }
      end
    end

    describe "properties" do
      it_behaves_like "property", :_type do
        let(:value) { "HierarchyItem" }
      end

      it_behaves_like "property", :id do
        let(:value) { item.id }
      end

      it_behaves_like "property", :label do
        let(:value) { item.label }
      end

      it_behaves_like "property", :short do
        let(:value) { item.short }
      end

      it_behaves_like "property", :depth do
        let(:value) { item.depth }
      end
    end
  end

  private

  def build_aggregate(item:, depth:)
    API::V3::CustomFields::Hierarchy::HierarchicalItemAggregate.new(item:, depth:)
  end
end
