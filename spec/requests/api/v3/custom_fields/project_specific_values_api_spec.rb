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

        context "with a visible item below a hidden one" do
          let!(:spider_sense) { create(:hierarchy_item, parent: oscorp, label: "Spider sense") }

          before { create(:project_specific_value_restriction, project:, hierarchy_item: spider_sense) }

          it "skips the visible item together with its hidden parent" do
            expect(last_response).to have_http_status(:ok)
            expect(elements.pluck("id")).to eq([root.id, acme.id, traffic_lights.id])
          end
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

      context "with a project and its subprojects" do
        let(:subproject) { create(:project, parent: project, types: [type]) }
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, project: project.id, include_subprojects: true) }

        current_user do
          create(:user, member_with_permissions: { project => %i[view_work_packages],
                                                   subproject => %i[view_work_packages] })
        end

        before do
          create(:project_specific_value_restriction, project: subproject, hierarchy_item: acme)
          create(:project_specific_value_restriction, project: subproject, hierarchy_item: traffic_lights)
          create(:project_specific_value_restriction, project: subproject, hierarchy_item: green)
        end

        it "returns the items usable in the project and its subprojects" do
          expect(last_response).to have_http_status(:ok)
          expect(elements.pluck("id")).to eq([root.id, acme.id, traffic_lights.id, green.id])
          expect(body.dig("_links", "self", "href")).to include("include_subprojects=true")
        end

        context "without including the subprojects" do
          let(:path) { api_v3_paths.custom_field_items(custom_field.id, project: project.id) }

          it "returns the items usable in the project only" do
            expect(last_response).to have_http_status(:ok)
            expect(elements.pluck("id")).to eq([root.id, acme.id, traffic_lights.id])
          end
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

    describe "POST /api/v3/queries/form with a project" do
      subject(:last_response) do
        post api_v3_paths.create_query_form,
             { name: "Query", _links: { project: { href: api_v3_paths.project(project.id) } } }.to_json
      end

      current_user do
        create(:user, member_with_permissions: { project => %i[view_work_packages save_queries] })
      end

      let(:filter_schema) do
        body.dig("_embedded", "schema", "_embedded", "filtersSchemas", "_embedded", "elements")
            .find { it.dig("_links", "self", "href").end_with?("customField#{custom_field.id}") }
      end
      let(:allowed_values_hrefs) do
        filter_schema["_dependencies"]
          .flat_map { it["dependencies"].values }
          .filter_map { it.dig("values", "_links", "allowedValues", "href") }
          .uniq
      end

      it "loads the values of the hierarchy filter from the project" do
        expect(last_response).to have_http_status(:ok)
        expect(allowed_values_hrefs)
          .to eq([api_v3_paths.custom_field_items(custom_field.id, project: project.id, include_subprojects: true)])
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

  context "for values added by projects without project-specific restrictions" do
    context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
      let(:custom_field) { create(:hierarchy_wp_custom_field, types: [type]) }
      let(:root) { custom_field.hierarchy_root }
      let!(:acme) { create(:hierarchy_item, parent: root, label: "Acme") }
      let!(:own_item) { create(:hierarchy_item, parent: acme, label: "Own", project:) }
      let!(:foreign_item) { create(:hierarchy_item, parent: acme, label: "Foreign", project: other_project) }

      describe "GET /api/v3/custom_fields/:id/items" do
        let(:path) { api_v3_paths.custom_field_items(custom_field.id, project: project.id) }

        it "returns the global items and the items of the project" do
          expect(last_response).to have_http_status(:ok)
          expect(elements.pluck("id")).to eq([root.id, acme.id, own_item.id])
        end

        context "without a project" do
          let(:path) { api_v3_paths.custom_field_items(custom_field.id) }

          it "only links the items to the projects the user sees work packages in" do
            expect(last_response).to have_http_status(:ok)
            expect(elements.filter_map { it.dig("_links", "project") })
              .to eq([{ "href" => api_v3_paths.project(project.id), "title" => project.name }])
            expect(last_response.body).not_to include(other_project.name)
          end
        end

        context "for an admin without a project" do
          let(:path) { api_v3_paths.custom_field_items(custom_field.id) }

          current_user { create(:admin) }

          it "loads the projects of the items at once" do
            recorder = ActiveRecord::QueryRecorder.new { last_response }

            expect(elements.filter_map { it.dig("_links", "project", "title") })
              .to contain_exactly(project.name, other_project.name)
            expect(recorder.log.grep(/FROM "projects" WHERE "projects"\."id"/)).to be_one
          end
        end
      end
    end

    context "for a list custom field" do
      let(:custom_field) { create(:list_wp_custom_field, types: [type], possible_values: %w[A]) }
      let!(:own_option) { create(:custom_option, custom_field:, value: "Own", project:) }
      let!(:foreign_option) { create(:custom_option, custom_field:, value: "Foreign", project: other_project) }

      describe "GET /api/v3/custom_options/:id" do
        context "for an option of a project the user sees work packages in" do
          let(:path) { api_v3_paths.custom_option(own_option.id) }

          it_behaves_like "successful response"

          it "links the option to its project" do
            expect(body.dig("_links", "project"))
              .to eq({ "href" => api_v3_paths.project(project.id), "title" => project.name })
          end
        end

        context "for an option of another project" do
          let(:path) { api_v3_paths.custom_option(foreign_option.id) }

          it_behaves_like "not found"
        end
      end
    end
  end
end
