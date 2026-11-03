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

RSpec.describe "API v3 project-specific custom field values", :webmock, content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:other_project) { create(:project, types: [type]) }

  current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  let(:body) { JSON.parse(last_response.body) }
  let(:elements) { body.dig("_embedded", "elements") }

  subject(:last_response) { get path }

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist, types: [type]) }
    let(:root) { custom_field.hierarchy_root }
    let!(:acme) { create(:hierarchy_item, parent: root, label: "Acme") }
    let!(:traffic_lights) { create(:hierarchy_item, parent: acme, label: "Traffic lights") }
    let!(:green) { create(:hierarchy_item, parent: traffic_lights, label: "Green") }
    let!(:oscorp) { create(:hierarchy_item, parent: root, label: "Oscorp") }

    let(:acme_element) { elements.find { it["id"] == acme.id } }
    let(:traffic_lights_element) { elements.find { it["id"] == traffic_lights.id } }

    before do
      create(:project_specific_value_restriction, project:, hierarchy_item: acme)
      create(:project_specific_value_restriction, project:, hierarchy_item: traffic_lights)
      create(:project_specific_value_restriction, project: other_project, hierarchy_item: acme)
      create(:project_specific_value_restriction, project: other_project, hierarchy_item: traffic_lights)
      create(:project_specific_value_restriction, project: other_project, hierarchy_item: green)
    end

    describe "GET /api/v3/custom_fields/:id/items" do
      context "without a project" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id) }

        it "returns the items visible to the user without linking hidden children" do
          expect(last_response).to have_http_status(:ok)
          expect(elements.pluck("id")).to eq([root.id, acme.id, traffic_lights.id])
          expect(acme_element.dig("_links", "children").pluck("title")).to eq(["Traffic lights"])
          expect(traffic_lights_element.dig("_links", "children")).to be_empty
        end
      end

      context "with a project" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, project: project.id) }

        it "returns the items usable in the project" do
          expect(last_response).to have_http_status(:ok)
          expect(elements.pluck("id")).to eq([root.id, acme.id, traffic_lights.id])
          expect(body.dig("_links", "self", "href")).to include("project=#{project.id}")
        end
      end

      context "with a project the user cannot view work packages in" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, project: other_project.id) }

        it_behaves_like "not found"
      end

      context "with a parent that is not visible" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, oscorp.id) }

        it_behaves_like "not found"
      end
    end

    describe "GET /api/v3/custom_field_items/:id" do
      context "for a visible item" do
        let(:path) { api_v3_paths.custom_field_item(acme.id) }

        it "only links the visible children" do
          expect(last_response).to have_http_status(:ok)
          expect(body.dig("_links", "children").pluck("title")).to eq(["Traffic lights"])
        end
      end

      context "for an item that is not visible" do
        let(:path) { api_v3_paths.custom_field_item(oscorp.id) }

        it_behaves_like "not found"
      end

      context "for an item that is only usable in a project the user cannot view work packages in" do
        let(:path) { "#{api_v3_paths.custom_field_item(green.id)}?project=#{other_project.id}" }

        it_behaves_like "not found"
      end
    end

    describe "GET /api/v3/custom_field_items/:id/branch" do
      let(:path) { api_v3_paths.custom_field_item_branch(traffic_lights.id) }

      it "returns the branch without linking hidden children" do
        expect(last_response).to have_http_status(:ok)
        expect(elements.pluck("id")).to eq([root.id, acme.id, traffic_lights.id])
        expect(traffic_lights_element.dig("_links", "children")).to be_empty
      end

      context "for an item that is not visible" do
        let(:path) { api_v3_paths.custom_field_item_branch(green.id) }

        it_behaves_like "not found"
      end
    end
  end

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B])
    end
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_a)
    end

    describe "GET /api/v3/custom_options/:id" do
      context "for a visible option" do
        let(:path) { api_v3_paths.custom_option(option_a.id) }

        it_behaves_like "successful response"
      end

      context "for an option that is not visible" do
        let(:path) { api_v3_paths.custom_option(option_b.id) }

        it_behaves_like "not found"
      end
    end
  end
end
