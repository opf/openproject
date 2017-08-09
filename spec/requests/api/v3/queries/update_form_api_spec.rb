#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.

require 'spec_helper'
require 'rack/test'

describe "POST /api/v3/queries/form", type: :request do
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.query_form(query.id) }
  let(:user) { FactoryGirl.create(:admin) }
  let(:role) { FactoryGirl.create :existing_role, permissions: permissions }
  let(:permissions) { %i(view_work_packages manage_public_queries) }

  let!(:project) { FactoryGirl.create(:project_with_types) }

  let(:query) do
    FactoryGirl.create(
      :query,
      name: "Existing Query",
      is_public: false,
      project: project,
      user: user
    )
  end
  let(:additional_setup) {}

  let(:parameters) { {} }
  let(:override_params) { {} }
  let(:form) { JSON.parse response.body }

  before do
    project.add_member! user, role

    login_as(user)

    additional_setup

    post path,
         params: parameters.merge(override_params).to_json,
         headers: { 'CONTENT_TYPE' => 'application/json' }
  end

  it 'should return 200(OK)' do
    expect(response.status).to eq(200)
  end

  it 'should be of type form' do
    expect(form["_type"]).to eq "Form"
  end

  it 'has the available_projects link for creation in the schema' do
    expect(form.dig("_embedded", "schema", "project", "_links", "allowedValues", "href"))
      .to eq "/api/v3/queries/available_projects"
  end

  describe 'with empty parameters' do
    it 'has 0 validation errors' do
      expect(form.dig("_embedded", "validationErrors").size).to eq 0
    end
  end

  describe 'with all minimum parameters' do
    let(:parameters) do
      {
        name: "Some Query"
      }
    end

    it 'has 0 validation errors' do
      expect(form.dig("_embedded", "validationErrors")).to be_empty
    end

    it 'has the given name set' do
      expect(form.dig("_embedded", "payload", "name")).to eq parameters[:name]
    end

    describe 'the commit link' do
      it "has the correct URL" do
        expect(form.dig("_links", "commit", "href")).to eq "/api/v3/queries/#{query.id}"
      end

      it "has the correct method" do
        expect(form.dig("_links", "commit", "method")).to eq "patch"
      end
    end

    describe 'columns' do
      let(:relation_columns_allowed) { true }

      let(:additional_setup) do
        custom_field

        non_project_type

        # There does not seem to appear a way to generate a valid token
        # for testing purposes
        allow(EnterpriseToken)
          .to receive(:allows_to?)
          .with(:work_package_query_relation_columns)
          .and_return(relation_columns_allowed)
      end

      let(:custom_field) do
        cf = FactoryGirl.create(:list_wp_custom_field)
        project.work_package_custom_fields << cf
        cf.types << project.types.first

        cf
      end

      let(:non_project_type) do
        FactoryGirl.create(:type)
      end

      let(:static_columns_json) do
        %w(id project assignee author
           category createdAt dueDate estimatedTime
           parent percentageDone priority responsible
           spentTime startDate status subject type
           updatedAt version).map do |id|
          {
            '_type': 'QueryColumn::Property',
            'id': id
          }
        end
      end

      let(:custom_field_columns_json) do
        [
          {
            '_type': 'QueryColumn::Property',
            'id': "customField#{custom_field.id}"
          }
        ]
      end

      let(:relation_to_type_columns_json) do
        project.types.map do |type|
          {
            '_type': 'QueryColumn::RelationToType',
            'id': "relationsToType#{type.id}"
          }
        end
      end

      let(:relation_of_type_columns_json) do
        Relation::TYPES.map do |_, value|
          {
            '_type': 'QueryColumn::RelationOfType',
            'id': "relationsOfType#{value[:sym].camelcase}"
          }
        end
      end

      let(:non_project_type_relation_column_json) do
        [
          {
            '_type': 'QueryColumn::RelationToType',
            'id': "relationsToType#{non_project_type.id}"
          }
        ]
      end

      context 'within a project' do
        context 'with relation columns allowed by the enterprise token' do
          it 'has the static, custom field and relation columns' do
            expected_columns = static_columns_json +
                               custom_field_columns_json +
                               relation_to_type_columns_json +
                               relation_of_type_columns_json

            actual_columns = form.dig('_embedded',
                                      'schema',
                                      'columns',
                                      '_embedded',
                                      'allowedValues')
                                 .map do |column|
                                   {
                                     '_type': column['_type'],
                                     'id': column['id']
                                   }
                                 end

            expect(actual_columns).to include(*expected_columns)
            expect(actual_columns).not_to include(non_project_type_relation_column_json)
          end
        end

        context 'with relation columns disallowed by the enterprise token' do
          it 'has the static and custom field' do
            expected_columns = static_columns_json +
                               custom_field_columns_json

            actual_columns = form.dig('_embedded',
                                      'schema',
                                      'columns',
                                      '_embedded',
                                      'allowedValues')
                                 .map do |column|
                                   {
                                     '_type': column['_type'],
                                     'id': column['id']
                                   }
                                 end

            expect(actual_columns).to include(*expected_columns)
            expect(actual_columns).not_to include(non_project_type_relation_column_json)
            expect(actual_columns).not_to include(relation_to_type_columns_json)
            expect(actual_columns).not_to include(relation_of_type_columns_json)
          end
        end
      end

      context 'globally (no project)' do
        let(:additional_setup) do
          custom_field

          non_project_type

          query.update_attribute(:project, nil)

          # There does not seem to appear a way to generate a valid token
          # for testing purposes
          allow(EnterpriseToken)
            .to receive(:allows_to?)
            .with(:work_package_query_relation_columns)
            .and_return(relation_columns_allowed)
        end

        context 'with relation columns allowed by the enterprise token' do
          it 'has the static, custom field and relation columns' do
            expected_columns = static_columns_json +
                               custom_field_columns_json +
                               relation_to_type_columns_json +
                               non_project_type_relation_column_json +
                               relation_of_type_columns_json

            actual_columns = form.dig('_embedded',
                                      'schema',
                                      'columns',
                                      '_embedded',
                                      'allowedValues')
                                 .map do |column|
                                   {
                                     '_type': column['_type'],
                                     'id': column['id']
                                   }
                                 end

            expect(actual_columns).to include(*expected_columns)
          end
        end

        context 'with relation columns disallowed by the enterprise token' do
          it 'has the static, custom field and relation columns' do
            expected_columns = static_columns_json +
                               custom_field_columns_json

            actual_columns = form.dig('_embedded',
                                      'schema',
                                      'columns',
                                      '_embedded',
                                      'allowedValues')
                                 .map do |column|
                                   {
                                     '_type': column['_type'],
                                     'id': column['id']
                                   }
                                 end

            expect(actual_columns).to include(*expected_columns)
            expect(actual_columns).not_to include(non_project_type_relation_column_json)
            expect(actual_columns).not_to include(relation_to_type_columns_json)
            expect(actual_columns).not_to include(relation_of_type_columns_json)
          end
        end
      end
    end
  end

  describe 'with all parameters given' do
    let(:status) { FactoryGirl.create :status }

    let(:parameters) do
      {
        name: "Some Query",
        public: true,
        sums: true,
        showHierarchies: false,
        filters: [
          {
            name: "Status",
            _links: {
              filter: {
                href: "/api/v3/queries/filters/status"
              },
              operator: {
                "href": "/api/v3/queries/operators/%3D"
              },
              values: [
                {
                  href: "/api/v3/statuses/#{status.id}"
                }
              ]
            }
          }
        ],
        _links: {
          project: {
            href: "/api/v3/projects/#{project.id}"
          },
          columns: [
            {
              href: "/api/v3/queries/columns/id"
            },
            {
              href: "/api/v3/queries/columns/subject"
            }
          ],
          sortBy: [
            {
              href: "/api/v3/queries/sort_bys/id-desc"
            },
            {
              href: "/api/v3/queries/sort_bys/assignee-asc"
            }
          ],
          groupBy: {
            href: "/api/v3/queries/group_bys/assignee"
          }
        }
      }
    end

    it 'has 0 validation errors' do
      expect(form.dig("_embedded", "validationErrors")).to be_empty
    end

    it 'has a commit link' do
      expect(form.dig("_links", "commit")).to be_present
    end

    it 'has the given name set' do
      expect(form.dig("_embedded", "payload", "name")).to eq parameters[:name]
    end

    it 'has the project set' do
      project_link = { "href" => "/api/v3/projects/#{project.id}", 'title' => project.name }

      expect(form.dig("_embedded", "payload", "_links", "project")).to eq project_link
    end

    it 'is set to public' do
      expect(form.dig("_embedded", "payload", "public")).to eq true
    end

    it 'has the filters set' do
      filters = [
        {
          "_links" => {
            "filter" => {
              "href" => "/api/v3/queries/filters/status",
              'title' => 'Status'
            },
            "operator" => {
              "href" => "/api/v3/queries/operators/%3D",
              "title" => 'is'
            },
            "values" => [
              {
                "href" => "/api/v3/statuses/#{status.id}",
                "title" => status.name
              }
            ]
          }
        }
      ]

      expect(form.dig("_embedded", "payload", "filters")).to eq filters
    end

    it 'has the columns set' do
      columns = [
        { "href" => "/api/v3/queries/columns/id", 'title' => 'ID' },
        { "href" => "/api/v3/queries/columns/subject", 'title' => 'Subject' }
      ]

      expect(form.dig("_embedded", "payload", "_links", "columns")).to eq columns
    end

    it 'has the groupBy set' do
      group_by = { "href" => "/api/v3/queries/group_bys/assignee", 'title' => 'Assignee' }

      expect(form.dig("_embedded", "payload", "_links", "groupBy")).to eq group_by
    end

    it 'has the columns set' do
      sort_by = [
        { "href" => "/api/v3/queries/sort_bys/id-desc", 'title' => 'ID (Descending)' },
        { "href" => "/api/v3/queries/sort_bys/assignee-asc", 'title' => 'Assignee (Ascending)' }
      ]

      expect(form.dig("_embedded", "payload", "_links", "sortBy")).to eq sort_by
    end

    context "with the project referred to by its identifier" do
      let(:override_params) do
        links = parameters[:_links]

        links[:project] = {
          href: "/api/v3/projects/#{project.identifier}"
        }

        { _links: links }
      end

      it "still finds the project" do
        project_link = { "href" => "/api/v3/projects/#{project.id}", 'title' => project.name }

        expect(form.dig("_embedded", "payload", "_links", "project")).to eq project_link
      end
    end

    context "with an unknown filter" do
      let(:override_params) do
        filter = parameters[:filters][0]

        filter[:_links][:filter][:href] = "/api/v3/queries/filters/statuz"

        { filters: [filter] }
      end

      it "returns a validation error" do
        expect(form.dig("_embedded", "validationErrors", "base", "message")).to eq "Statuz does not exist."
      end

      it "has no commit link" do
        expect(form.dig("_links", "commit")).not_to be_present
      end
    end

    context "with an unknown column" do
      let(:override_params) do
        column = { href: "/api/v3/queries/columns/wurst" }
        links = parameters[:_links]

        links[:columns] = links[:columns] + [column]

        { _links: links }
      end

      it "returns a validation error" do
        expect(form.dig("_embedded", "validationErrors", "columns", "message"))
          .to eq "Invalid query column: wurst"
      end
    end

    context "with an invalid groupBy column" do
      let(:override_params) do
        column = { href: "/api/v3/queries/group_bys/foobar" }
        links = parameters[:_links]

        links[:groupBy] = column

        { _links: links }
      end

      it "returns a validation error" do
        expect(form.dig("_embedded", "validationErrors", "groupBy", "message"))
          .to eq "Can't group by: foobar"
      end
    end

    context "with an invalid sort criterion" do
      let(:override_params) do
        sort_criterion = { href: "/api/v3/queries/sort_bys/spentTime-desc" }
        links = parameters[:_links]

        links[:sortBy] = links[:sortBy] + [sort_criterion]

        { _links: links }
      end

      it "returns a validation error" do
        expect(form.dig("_embedded", "validationErrors", "sortBy", "message"))
          .to eq "Can't sort by column: spent_hours"
      end
    end

    context "with an unauthorized user trying to set the query public" do
      let(:user) { FactoryGirl.create(:user) }
      let(:permissions) { [:view_work_packages] }

      it "should reject the request" do
        expect(form.dig("_embedded", "validationErrors", "public", "message"))
          .to eq "Public - The user has no permission to create public queries."
      end
    end
  end
end
