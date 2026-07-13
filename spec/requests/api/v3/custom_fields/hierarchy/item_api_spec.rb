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

RSpec.describe "API v3 custom field items", :webmock, content_type: :json, with_ee: [:custom_field_hierarchies] do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }

  let(:custom_field) { create(:wp_custom_field, field_format: "hierarchy", hierarchy_root: nil) }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let!(:root) { service.generate_root(custom_field).value! }
  let(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }
  let!(:luke) { service.insert_item(contract_class:, parent: root, label: "Luke", short: "LS").value! }
  let!(:r2d2) { service.insert_item(contract_class:, parent: luke, label: "R2-D2", short: "R2").value! }
  let!(:mouse) { service.insert_item(contract_class:, parent: r2d2, label: "Mouse Droid", short: "MD").value! }
  let!(:c3po) { service.insert_item(contract_class:, parent: luke, label: "C-3PO", short: "3PO").value! }
  let!(:mara) { service.insert_item(contract_class:, parent: root, label: "Mara", short: "MJ").value! }

  subject(:last_response) { get path }

  describe "GET /api/v3/custom_field_items/:id" do
    let(:path) { api_v3_paths.custom_field_item(mouse.id) }

    context "if user is not logged in" do
      it_behaves_like "unauthenticated access"
    end

    context "if user is logged in but lacks permissions" do
      current_user { create(:user, member_with_permissions: { project => [] }) }

      it_behaves_like "not found"
    end

    context "if user is logged in with the necessary permissions" do
      current_user { create(:user, member_with_permissions: { project => [:select_custom_fields] }) }

      it_behaves_like "successful response"

      it "responds with the correct item" do
        expect(last_response.body).to be_json_eql("HierarchyItem".to_json).at_path("_type")
        expect(last_response.body).to be_json_eql(mouse.label.to_json).at_path("label")
        expect(last_response.body).to be_json_eql((mouse.depth - 1).to_json).at_path("depth")
      end

      context "if custom field does not exist" do
        let(:path) { api_v3_paths.custom_field_item(1337) }

        it_behaves_like "not found"
      end
    end
  end

  describe "GET /api/v3/custom_field_items/:id/branch" do
    let(:path) { api_v3_paths.custom_field_item_branch(mouse.id) }

    context "if user is not logged in" do
      it_behaves_like "unauthenticated access"
    end

    context "if user is logged in but lacks permissions" do
      current_user { create(:user, member_with_permissions: { project => [] }) }

      it_behaves_like "not found"
    end

    context "if user is logged in with the necessary permissions" do
      current_user { create(:user, member_with_permissions: { project => [:select_custom_fields] }) }

      it_behaves_like "API V3 collection response", 4, 4, "HierarchyItem", "Collection" do
        let(:elements) { [root, luke, r2d2, mouse] }
      end

      context "if custom field does not exist" do
        let(:path) { api_v3_paths.custom_field_items(1337) }

        it_behaves_like "not found"
      end
    end
  end
end
