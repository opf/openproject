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

RSpec.describe "API v3 custom field hierarchy items", :webmock, content_type: :json, with_ee: [:custom_field_hierarchies] do
  include API::V3::Utilities::PathHelper

  describe "GET /api/v3/custom_fields/:id/items" do
    shared_let(:project) { create(:project) }

    let(:custom_field) { create(:wp_custom_field, field_format: "hierarchy", hierarchy_root: nil) }
    let!(:root) { service.generate_root(custom_field).value! }
    let(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }
    let!(:luke) { service.insert_item(contract_class:, parent: root, label: "Luke", short: "LS").value! }
    let!(:r2d2) { service.insert_item(contract_class:, parent: luke, label: "R2-D2", short: "R2").value! }
    let!(:mouse) { service.insert_item(contract_class:, parent: r2d2, label: "Mouse Droid", short: "MD").value! }
    let!(:c3po) { service.insert_item(contract_class:, parent: luke, label: "C-3PO", short: "3PO").value! }
    let!(:mara) { service.insert_item(contract_class:, parent: root, label: "Mara", short: "MJ").value! }
    let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }

    let(:path) { api_v3_paths.custom_field_items(custom_field.id) }

    subject(:last_response) { get path }

    context "if user is not logged in" do
      it_behaves_like "unauthenticated access"
    end

    context "if the user is not allowed to view the custom field" do
      current_user { create(:user, member_with_permissions: { project => [] }) }

      it_behaves_like "not found"
    end

    context "if user is logged in with the necessary permissions" do
      current_user { create(:user, member_with_permissions: { project => [:select_custom_fields] }) }

      it_behaves_like "API V3 collection response", 6, 6, "HierarchyItem", "Collection" do
        let(:elements) { [root, luke, r2d2, mouse, c3po, mara] }
      end

      context "if custom field does not exist" do
        let(:path) { api_v3_paths.custom_field_items(1337) }

        it_behaves_like "not found"
      end

      context "if depth is limited to specific value" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, nil, 1) }

        it_behaves_like "API V3 collection response", 3, 3, "HierarchyItem", "Collection" do
          let(:elements) { [root, luke, mara] }
        end
      end

      context "if parent is set to specific item" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, luke.id, 1) }

        it_behaves_like "API V3 collection response", 3, 3, "HierarchyItem", "Collection" do
          let(:elements) { [luke, r2d2, c3po] }
        end
      end

      context "if parent is set to an undefined value" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, "wrong item") }

        it_behaves_like "error response", 400, "InvalidQuery", "Parent must be an integer."
      end

      context "if depth is negative" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, nil, -1) }

        it_behaves_like "error response", 400, "InvalidQuery", "Depth must be greater or equal to 0."
      end
    end
  end
end
