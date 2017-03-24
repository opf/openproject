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

  let(:path) { api_v3_paths.query_form }
  let(:user) { FactoryGirl.create(:admin) }
  let!(:project) { FactoryGirl.create(:project_with_types) }

  let(:parameters) { {} }
  let(:override_params) { {} }
  let(:form) { JSON.parse response.body }

  before do
    login_as(user)

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
    it 'has 1 validation error' do
      expect(form.dig("_embedded", "validationErrors").size).to eq 1
    end

    it 'has a validation error on name' do
      expect(form.dig("_embedded", "validationErrors", "name", "message")).to eq "Name can't be blank."
    end

    it 'has no commit link' do
      expect(form.dig("_links", "commit")).to be_nil
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
  end

  describe 'with all parameters given' do
    let(:status) { FactoryGirl.create :status }

    let(:parameters) do
      {
        name: "Some Query",
        public: true,
        sums: true,
        filters: [
          {
            name: "Status",
            _links: {
              filter: {
                href: "/api/v3/queries/filters/status"
              },
              operator: {
                "href": "/api/v3/queries/operators/="
              },
              values: [
                {
                  href: "/api/v3/statuses/#{status.id}",
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
      project_link = { "href" => "/api/v3/projects/#{project.id}" }

      expect(form.dig("_embedded", "payload", "_links", "project")).to eq project_link
    end

    it 'is set to public' do
      expect(form.dig("_embedded", "payload", "public")).to eq true
    end

    it 'has the filters set' do
      filters = [
        {
          "_links" => {
            "filter" => { "href" => "/api/v3/queries/filters/status" },
            "operator" => { "href" => "/api/v3/queries/operators/=" },
            "values" => [
              { "href" => "/api/v3/statuses/#{status.id}" }
            ]
          }
        }
      ]

      expect(form.dig("_embedded", "payload", "filters")).to eq filters
    end

    it 'has the columns set' do
      columns = [
        { "href" => "/api/v3/queries/columns/id" },
        { "href" => "/api/v3/queries/columns/subject" }
      ]

      expect(form.dig("_embedded", "payload", "_links", "columns")).to eq columns
    end

    it 'has the groupBy set' do
      group_by = { "href" => "/api/v3/queries/group_bys/assignee" }

      expect(form.dig("_embedded", "payload", "_links", "groupBy")).to eq group_by
    end

    it 'has the columns set' do
      sort_by = [
        { "href" => "/api/v3/queries/sort_bys/id-desc" },
        { "href" => "/api/v3/queries/sort_bys/assignee-asc" }
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
        project_link = { "href" => "/api/v3/projects/#{project.id}" }

        expect(form.dig("_embedded", "payload", "_links", "project")).to eq project_link
      end
    end

    context "with groupBy specified as a GET parameter" do
      let(:path) { api_v3_paths.query_form + "?groupBy=author"}
      let(:override_params) do
        links = parameters[:_links]

        links.delete :groupBy

        { _links: links }
      end

      it "initializes the form with the given groupBy" do
        expect(form.dig("_embedded", "payload", "_links", "groupBy", "href"))
          .to eq "/api/v3/queries/group_bys/author"
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
    end

    context "with an unknown column" do
      let(:override_params) do
        column = { href: "/api/v3/queries/columns/wurst" }
        links = parameters[:_links]

        links[:columns] = links[:columns] + [column]

        { _links: links }
      end

      it "returns a validation error" do
        expect(form.dig("_embedded", "validationErrors", "columnNames", "message"))
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
        expect(form.dig("_embedded", "validationErrors", "sortCriteria", "message"))
          .to eq "Can't sort by column: spent_hours"
      end
    end

    context "with an unauthorized user trying to set the query public" do
      let(:user) { FactoryGirl.create :user }

      it "should reject the request" do
        expect(form.dig("_embedded", "validationErrors", "public", "message"))
          .to eq "Public - The user has no permission to create public queries."
      end
    end
  end
end
