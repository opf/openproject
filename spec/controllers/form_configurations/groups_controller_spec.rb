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

RSpec.describe FormConfigurations::GroupsController do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:form) { variant.form_configuration }
  let(:user) { create(:admin) }
  let(:temporary_group_key) { described_class::TEMPORARY_GROUP_KEY }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "POST #add_group", with_ee: %i[edit_attribute_groups] do
    it "renders the unsaved query summary without persisting a query" do
      create(:work_package)
      query_props = { columns: %w[subject], filters: [{ parent: { operator: "=", values: ["{id}"] } }].to_json }.to_json

      expect do
        post :add_group,
             params: { form_configuration_id: form.id, group_type: "query", query: query_props, name: "Draft children" },
             format: :turbo_stream
      end.not_to change(Query, :count)

      expect(response).to have_http_status(:ok)
      summary = Nokogiri::HTML.fragment(response.body)
      expect(summary.css("dt").map { it.text.strip }).to include("Relation type", "Columns")
      expect(summary.css("dd").map { it.text.strip }).to include("Children", "Subject")
      expect(summary.at_css('input[name="group[name]"]')["value"]).to eq("Draft children")
    end

    it "renders a temporary attribute group from group_type params" do
      expect do
        post :add_group, params: { form_configuration_id: form.id, group_type: "attribute" }, format: :turbo_stream
      end.not_to change { variant.reload.attribute_groups.count }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create", with_ee: %i[edit_attribute_groups] do
    it "persists a group when saving it" do
      expect do
        post :create,
             params: {
               form_configuration_id: form.id,
               group: { group_type: "attribute", name: "New Group" }
             },
             format: :turbo_stream
      end.to change { variant.reload.attribute_groups.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(variant.reload.attribute_groups.first.key).to eq("New Group")
    end

    it "persists a query group with an empty query when saving it" do
      query = create(:query, user:)
      query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
      query.save!
      query_props = API::V3::Queries::QueryParamsRepresenter.new(query).to_json

      post :create,
           params: {
             form_configuration_id: form.id,
             group: { group_type: "query", name: "Empty test", query: query_props }
           },
           format: :turbo_stream

      expect(response).to have_http_status(:ok)

      query_group = variant.reload.attribute_groups.detect { |group| group.is_a?(Type::QueryGroup) }
      expect(query_group.attributes).to be_a(Query)
      expect(query_group.key).to eq("Empty test")
    end
  end

  describe "PATCH #update_query", with_ee: %i[edit_attribute_groups] do
    let!(:work_package) { create(:work_package) }
    let(:query) { create(:query, user:, column_names: %w[id subject]) }

    before do
      query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
      query.save!
      form.update!(attribute_groups: [["Related", [query]]])
    end

    it "refreshes only the edited group's summary and editor data" do
      query.column_names = %w[subject]
      props = API::V3::Queries::QueryParamsRepresenter.new(query).to_json
      patch :update_query,
            params: { form_configuration_id: form.id, key: "Related", query: props },
            format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "replace",
                                            target: "work-package-types-form-configuration-group-query-row-component-Related")
      expect(response).not_to have_turbo_stream(action: "update",
                                                target: "work-package-types-form-configuration-main-content-component")
      expect(response.body).to include("Relation type", "Children", "Columns", "Subject")
      fragment = Nokogiri::HTML.fragment(response.body)
      expect(fragment.css("dd").map { it.text.strip }).not_to include("ID")
      expect(JSON.parse(fragment.at_css("[data-group-query]")["data-group-query"])["columns[]"]).to eq(%w[subject])
    end

    it "refreshes the canonical group when addressed by its display name" do
      aliased_query = create(:query, user:)
      form.update!(attribute_groups: [[:related, [aliased_query], "Related children"]])
      props = API::V3::Queries::QueryParamsRepresenter.new(aliased_query).to_json
      patch :update_query,
            params: { form_configuration_id: form.id, key: "Related children", query: props },
            format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "replace",
                                            target: "work-package-types-form-configuration-group-query-row-component-related")
    end

    it "does not replace saved content when an existing query update is invalid" do
      saved_filters = query.reload.filters.map { [it.name, it.operator, it.values] }

      patch :update_query,
            params: { form_configuration_id: form.id, key: "Related", query: "invalid JSON" },
            format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to have_turbo_stream(action: "flash", target: "op-primer-flash-component")
      expect(response).not_to have_turbo_stream(action: "update",
                                                target: "work-package-types-form-configuration-main-content-component")
      expect(query.reload.filters.map { [it.name, it.operator, it.values] }).to eq(saved_filters)
      expect(query.column_names).to eq(%i[id subject])
    end

    it "does not replace the saved content on failure" do
      patch :update_query,
            params: { form_configuration_id: form.id, key: "Missing", query: "{}" },
            format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to have_turbo_stream(action: "update",
                                                target: "work-package-types-form-configuration-main-content-component")
    end
  end

  describe "PATCH #update (rename)", with_ee: %i[edit_attribute_groups] do
    before do
      form.update!(attribute_groups: [
                     ["First group", %w[priority]],
                     ["Second group", %w[assignee]]
                   ])
    end

    context "when renaming to a duplicate name" do
      it "returns an error without the attribute prefix" do
        patch :update,
              params: {
                form_configuration_id: form.id,
                key: "First group",
                group: { name: "Second group" }
              },
              format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Second group")
        expect(response.body).to include("Group names must be unique.")
        expect(response.body).not_to include("Form Group names must be unique.")
      end

      it "preserves the entered name in the input field" do
        patch :update,
              params: {
                form_configuration_id: form.id,
                key: "First group",
                group: { name: "Second group" }
              },
              format: :turbo_stream

        expect(response.body).to include("Second group")
      end
    end

    context "when renaming to a blank name" do
      it "returns an error" do
        patch :update,
              params: {
                form_configuration_id: form.id,
                key: "First group",
                group: { name: "" }
              },
              format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the group was deleted meanwhile" do
      it "flashes the failure rather than re-rendering the editor of a gone group" do
        patch :update,
              params: {
                form_configuration_id: form.id,
                key: "Gone group",
                group: { name: "Any name" }
              },
              format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to have_turbo_stream(action: "flash", target: "op-primer-flash-component")
        expect(response.body).to include("The requested form item could not be found.")
      end
    end
  end

  describe "PATCH #update with unavailable query values", with_ee: %i[edit_attribute_groups] do
    it "preserves unavailable markers after a rejected rename" do
      project = create(:project)
      archived = create(:project)
      query = create(:query, user:)
      query.add_filter("project_id", "=", [project.id.to_s, archived.id.to_s])
      query.save!
      form.update!(attribute_groups: [["Related", [query]]])
      archived.update!(active: false)

      patch :update,
            params: { form_configuration_id: form.id, key: "Related", group: { name: "" } },
            format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Unavailable value")
    end
  end

  describe "without a group key", with_ee: %i[edit_attribute_groups] do
    before do
      form.update!(attribute_groups: [["First group", %w[priority]]])
    end

    it "rejects the request instead of reporting a missing group", :aggregate_failures do
      patch :update, params: { form_configuration_id: form.id, group: { name: "Renamed" } }, format: :turbo_stream

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq("Required parameter missing: key")
      expect(variant.reload.attribute_groups.map(&:key)).to eq(["First group"])
    end

    it "rejects a blank key" do
      delete :destroy, params: { form_configuration_id: form.id, key: "" }, format: :turbo_stream

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST #create (duplicate name)", with_ee: %i[edit_attribute_groups] do
    before do
      form.update!(attribute_groups: [["Existing group", %w[priority]]])
    end

    it "returns an error when creating a group with a duplicate name" do
      post :create,
           params: {
             form_configuration_id: form.id,
             group: { group_type: "attribute", name: "Existing group" }
           },
           format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('action="update"')
      expect(response.body).to include('target="work-package-types-form-configuration-main-content-component"')
      expect(response.body).not_to include("Form Group names must be unique.")
    end

    it "returns a main content turbo stream response" do
      post :create,
           params: {
             form_configuration_id: form.id,
             group: { group_type: "attribute", name: "Existing group" }
           },
           format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('target="work-package-types-form-configuration-main-content-component"')
    end

    it "does not render the existing group twice when a query group create fails" do
      query = create(:query, user:)
      query_props = API::V3::Queries::QueryParamsRepresenter.new(query).to_json

      post :create,
           params: {
             form_configuration_id: form.id,
             group: { group_type: "query", name: "Existing group", query: query_props }
           },
           format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body.scan('data-group-key="Existing group"').count).to eq(1)
      expect(response.body).to include('data-group-key="__new_form_configuration_group__"')
      summary = Nokogiri::HTML.fragment(response.body)
      expect(summary.css("dt").map { it.text.strip }).to include("Relation type", "Columns")
    end
  end

  describe "POST #create (default group name)", with_ee: %i[edit_attribute_groups] do
    it "returns an error when creating a group with the visible name of a default group" do
      post :create,
           params: {
             form_configuration_id: form.id,
             group: { group_type: "attribute", name: "Details" }
           },
           format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Details")
      expect(response.body).to include("Group names must be unique.")
    end
  end

  describe "DELETE #destroy", with_ee: %i[edit_attribute_groups] do
    let(:group_name) { "b) > 10.000 / 20.000 Nutzende" }

    before do
      form.update!(attribute_groups: [[group_name, %w[priority]]])
    end

    it "deletes a group whose name contains special characters" do
      delete :destroy, params: { form_configuration_id: form.id, key: group_name }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(variant.reload.attribute_groups.map(&:key)).not_to include(group_name)
    end
  end

  describe "PUT #drop", with_ee: %i[edit_attribute_groups] do
    it "reorders groups using the requested position" do
      form.update!(attribute_groups: [
                     [:details, %w[priority]],
                     ["Custom group", %w[version]],
                     [:people, %w[assignee]]
                   ])

      put :drop,
          params: { form_configuration_id: form.id, key: "Custom group", position: 1 },
          format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(variant.reload.attribute_groups.map(&:key)).to eq(["Custom group", :details, :people])
    end
  end
end
