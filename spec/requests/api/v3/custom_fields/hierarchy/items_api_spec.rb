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

RSpec.describe "API v3 custom field hierarchy items", :webmock, content_type: :json, with_ee: [:custom_field_hierarchies] do
  include API::V3::Utilities::PathHelper

  describe "GET /api/v3/custom_fields/:id/items" do
    shared_let(:type) { create(:type) }
    shared_let(:project) { create(:project, types: [type]) }

    let(:custom_field) do
      create(:wp_custom_field, :hierarchy, types: [type])
    end
    let!(:root) { custom_field.hierarchy_root }
    let!(:luke) { create(:hierarchy_item, parent: root, label: "Luke", short: "LS") }
    let!(:r2d2) { create(:hierarchy_item, parent: luke, label: "R2-D2", short: "R2") }
    let!(:mouse) { create(:hierarchy_item, parent: r2d2, label: "Mouse Droid", short: "MD") }
    let!(:c3po) { create(:hierarchy_item, parent: luke, label: "C-3PO", short: "3PO") }
    let!(:mara) { create(:hierarchy_item, parent: root, label: "Mara", short: "MJ") }

    let(:path) { api_v3_paths.custom_field_items(custom_field.id) }

    subject(:last_response) { get path }

    context "if user is not logged in" do
      it_behaves_like "unauthenticated access"
    end

    context "if user cannot see any project the field applies to" do
      current_user { create(:user) }

      it_behaves_like "not found"
    end

    context "if user is a member of a project the field applies to" do
      current_user { create(:user, member_with_permissions: { project => [] }) }

      it_behaves_like "API V3 collection response", 6, 6, "HierarchyItem", "Collection" do
        let(:elements) { [root, luke, r2d2, mouse, c3po, mara] }
      end

      it "renders the depth of each item below the root" do
        depths = JSON.parse(last_response.body).dig("_embedded", "elements").pluck("depth")
        expect(depths).to eq([nil, 0, 1, 2, 1, 0])
      end

      context "if custom field does not exist" do
        let(:path) { api_v3_paths.custom_field_items(not_existing_id(CustomField)) }

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

        it "renders the depth relative to the parent" do
          depths = JSON.parse(last_response.body).dig("_embedded", "elements").pluck("depth")
          expect(depths).to eq([nil, 0, 0])
        end
      end

      context "if parent is set to an undefined value" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, "wrong item") }

        it_behaves_like "param validation error"
      end

      context "if parent does not exist" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, not_existing_id(CustomField::Hierarchy::Item)) }

        it_behaves_like "not found"
      end

      context "if parent belongs to another hierarchy" do
        let(:other_custom_field) { create(:wp_custom_field, :hierarchy, types: [type]) }
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, other_custom_field.hierarchy_root.id) }

        it_behaves_like "not found"
      end

      context "if depth is negative" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, nil, -1) }

        it "results in a validation error" do
          expect(last_response).to have_http_status(:bad_request)
          expect(JSON.parse(last_response.body)).to include(
            "errorIdentifier" => "urn:openproject-org:api:v3:errors:BadRequest",
            "message" => "Bad request: depth does not have a valid value"
          )
        end
      end
    end
  end
end
