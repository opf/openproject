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

RSpec.describe API::V3::Queries::Schemas::QuerySchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:query) do
    query = Query.new(project:)

    # Stub some methods to avoid a test failure in unrelated tests
    allow(query)
      .to receive(:groupable_columns)
      .and_return([])

    allow(query)
      .to receive(:displayable_columns)
      .and_return([])

    allow(query)
      .to receive(:sortable_columns)
      .and_return([])

    query
  end

  let(:form_embedded) { false }
  let(:self_link) { "bogus_self_path" }
  let(:project) { nil }

  let(:instance) { described_class.new(query, self_link:, current_user: user, form_embedded:) }
  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user, &:forbid_everything)
  end

  subject(:generated) { instance.to_json }

  shared_examples_for "has a collection of allowed values" do
    before do
      allow(query).to receive(available_values_method).and_return(available_values)
    end

    context "when no values are allowed" do
      let(:available_values) do
        []
      end

      it_behaves_like "links to and embeds allowed values directly" do
        let(:hrefs) { [] }
      end
    end

    context "when values are allowed" do
      it_behaves_like "links to and embeds allowed values directly" do
        let(:hrefs) { expected_hrefs }
      end
    end
  end

  context "generation" do
    context "_links" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { self_link }
      end
    end

    context "attributes" do
      describe "_type" do
        it "is Schema" do
          expect(subject)
            .to be_json_eql("Schema".to_json)
            .at_path("_type")
        end
      end

      describe "id" do
        let(:path) { "id" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Integer" }
          let(:name) { Query.human_attribute_name("id") }
          let(:required) { true }
          let(:writable) { false }
        end
      end

      describe "name" do
        let(:path) { "name" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "String" }
          let(:name) { Query.human_attribute_name("name") }
          let(:required) { true }
          let(:writable) { true }
        end

        it_behaves_like "indicates length requirements" do
          let(:min_length) { 1 }
          let(:max_length) { 255 }
        end
      end

      describe "createdAt" do
        let(:path) { "createdAt" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "DateTime" }
          let(:name) { Query.human_attribute_name("created_at") }
          let(:required) { true }
          let(:writable) { false }
        end
      end

      describe "updatedAt" do
        let(:path) { "updatedAt" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "DateTime" }
          let(:name) { Query.human_attribute_name("updated_at") }
          let(:required) { true }
          let(:writable) { false }
        end
      end

      describe "user" do
        let(:path) { "user" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "User" }
          let(:name) { Query.human_attribute_name("user") }
          let(:required) { true }
          let(:writable) { false }
          let(:has_default) { true }
          let(:location) { "_links" }
        end
      end

      describe "project" do
        let(:path) { "project" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Project" }
          let(:name) { Query.human_attribute_name("project") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "does not link to allowed values"

        context "when embedding" do
          let(:form_embedded) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) { api_v3_paths.query_available_projects }
          end
        end
      end

      describe "public" do
        let(:path) { "public" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { Query.human_attribute_name("public") }
          let(:required) { false }
          let(:writable) { false }
          let(:has_default) { true }
        end

        context "when having the :manage_public_queries permission" do
          let(:other_project) { build_stubbed(:project) }

          before do
            mock_permissions_for(user) do |mock|
              # so that allowed_in_any_project? returns true
              mock.allow_in_project :manage_public_queries, project: other_project
            end
          end

          it "marks public as writable" do
            expect(subject)
              .to be_json_eql(true)
              .at_path("public/writable")
          end
        end
      end

      describe "hidden" do
        let(:path) { "hidden" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { Query.human_attribute_name("hidden") }
          let(:required) { true }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "sums" do
        let(:path) { "sums" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { Query.human_attribute_name("sums") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "timelineVisible" do
        let(:path) { "timelineVisible" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { Query.human_attribute_name("timeline_visible") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "timelineZoomLevel" do
        let(:path) { "timelineZoomLevel" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "String" }
          let(:name) { Query.human_attribute_name("timeline_zoom_level") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "timelineLabels" do
        let(:path) { "timelineLabels" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "QueryTimelineLabels" }
          let(:name) { Query.human_attribute_name("timeline_labels") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "timestamps" do
        let(:path) { "timestamps" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "[]Timestamp" }
          let(:name) { Query.human_attribute_name("timestamps") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "show hierarchies" do
        let(:path) { "showHierarchies" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { Query.human_attribute_name("show_hierarchies") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "starred" do
        let(:path) { "starred" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Boolean" }
          let(:name) { Query.human_attribute_name("starred") }
          let(:required) { false }
          let(:writable) { false }
          let(:has_default) { true }
        end
      end

      describe "highlighting_mode" do
        let(:path) { "highlightingMode" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "String" }
          let(:name) { Query.human_attribute_name("highlighting_mode") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "display_representation" do
        let(:path) { "displayRepresentation" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "String" }
          let(:name) { Query.human_attribute_name("display_representation") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end
      end

      describe "columns" do
        let(:path) { "columns" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "[]QueryColumn" }
          let(:name) { Query.human_attribute_name("columns") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "does not link to allowed values"

        context "when embedding" do
          let(:form_embedded) { true }
          let(:type) { build_stubbed(:type) }
          let(:available_values) do
            [Queries::WorkPackages::Selects::PropertySelect.new(:bogus1),
             Queries::WorkPackages::Selects::PropertySelect.new(:bogus2),
             Queries::WorkPackages::Selects::PropertySelect.new(:bogus3),
             Queries::WorkPackages::Selects::RelationToTypeSelect.new(type),
             Queries::WorkPackages::Selects::RelationOfTypeSelect.new(
               name: :label_relates_to,
               sym: :relation1,
               sym_name: :label_relates_to
             )]
          end
          let(:available_values_method) { :displayable_columns }

          it_behaves_like "has a collection of allowed values" do
            let(:expected_hrefs) do
              available_values.map do |value|
                api_v3_paths.query_column(value.name.to_s.camelcase(:lower))
              end
            end

            it "has available columns of both types" do
              types = JSON.parse(generated)
                          .dig("columns",
                               "_embedded",
                               "allowedValues")
                          .map { |v| v["_type"] }
                          .uniq

              expect(types).to match_array(%w(QueryColumn::Property QueryColumn::RelationToType QueryColumn::RelationOfType))
            end
          end
        end
      end

      describe "show highlighted_attributes" do
        let(:path) { "highlightedAttributes" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "[]QueryColumn" }
          let(:name) { Query.human_attribute_name("highlighted_attributes") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "does not link to allowed values"

        context "when embedding" do
          let(:form_embedded) { true }
          let(:type) { build_stubbed(:type) }
          let(:available_values) do
            [Queries::WorkPackages::Selects::PropertySelect.new(:bogus1, highlightable: true),
             Queries::WorkPackages::Selects::PropertySelect.new(:bogus2, highlightable: true)]
          end
          let(:available_values_method) { :displayable_columns }

          it_behaves_like "has a collection of allowed values" do
            let(:expected_hrefs) do
              available_values.map do |value|
                api_v3_paths.query_column(value.name.to_s.camelcase(:lower))
              end
            end
          end
        end
      end

      describe "filters" do
        let(:path) { "filters" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "[]QueryFilterInstance" }
          let(:name) { Query.human_attribute_name("filters") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like "does not link to allowed values"

        context "when global query" do
          let(:href) { api_v3_paths.query_filter_instance_schemas }

          it "contains the link to the filter schemas" do
            expect(subject)
              .to be_json_eql(href.to_json)
              .at_path("#{path}/_links/allowedValuesSchemas/href")
          end
        end

        context "when project query" do
          let(:project) { build_stubbed(:project) }
          let(:href) { api_v3_paths.query_project_filter_instance_schemas(project.id) }

          it "contains the link to the filter schemas" do
            expect(subject)
              .to be_json_eql(href.to_json)
              .at_path("#{path}/_links/allowedValuesSchemas/href")
          end
        end
      end

      describe "groupBy" do
        let(:path) { "groupBy" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "[]QueryGroupBy" }
          let(:name) { Query.human_attribute_name("group_by") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "does not link to allowed values"

        context "when embedding" do
          let(:form_embedded) { true }

          it_behaves_like "has a collection of allowed values" do
            let(:available_values) do
              [Queries::WorkPackages::Selects::PropertySelect.new(:bogus1),
               Queries::WorkPackages::Selects::PropertySelect.new(:bogus2),
               Queries::WorkPackages::Selects::PropertySelect.new(:bogus3)]
            end
            let(:available_values_method) { :groupable_columns }
            let(:expected_hrefs) do
              available_values.map do |value|
                api_v3_paths.query_group_by(value.name)
              end
            end
          end
        end
      end

      describe "sortBy" do
        let(:path) { "sortBy" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "[]QuerySortBy" }
          let(:name) { Query.human_attribute_name("sort_by") }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "does not link to allowed values"

        context "when embedding" do
          let(:form_embedded) { true }

          it_behaves_like "has a collection of allowed values" do
            before do
              allow(Query)
                .to receive(:sortable_columns)
                .and_return(available_values)
            end

            let(:available_values) do
              [Queries::WorkPackages::Selects::PropertySelect.new(:bogus1),
               Queries::WorkPackages::Selects::PropertySelect.new(:bogus2),
               Queries::WorkPackages::Selects::PropertySelect.new(:bogus3)]
            end
            let(:available_values_method) { :sortable_columns }

            let(:expected_hrefs) do
              expected = available_values.map do |value|
                [api_v3_paths.query_sort_by(value.name, "asc"),
                 api_v3_paths.query_sort_by(value.name, "desc")]
              end

              expected.flatten
            end
          end
        end
      end

      describe "results" do
        let(:path) { "results" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "WorkPackageCollection" }
          let(:name) { Query.human_attribute_name("results") }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    context "_embedded" do
      describe "filtersSchemas" do
        let(:path) { "_embedded/filtersSchemas" }

        context "when global query" do
          let(:href) { api_v3_paths.query_filter_instance_schemas }

          it "contains a collection of filter schemas" do
            expect(subject)
              .to be_json_eql(href.to_json)
              .at_path("#{path}/_links/self/href")
          end
        end

        context "when project query" do
          let(:project) { build_stubbed(:project) }
          let(:href) { api_v3_paths.query_project_filter_instance_schemas(project.id) }

          it "contains a collection of filter schemas" do
            expect(subject)
              .to be_json_eql(href.to_json)
              .at_path("#{path}/_links/self/href")
          end
        end
      end
    end
  end
end
